//
//  LLMService.swift
//  Rhythm
//
//  Backend client for parsing voice input.
//  Python backend owns LLM calls and agent orchestration.
//

import Foundation

private struct ParseIntentRequest: Encodable {
    let utterance: String
    let existingTasks: [ParseIntentTaskContext]
    let locale: String
    let timezone: String
    let localTime: String

    enum CodingKeys: String, CodingKey {
        case utterance
        case existingTasks = "existing_tasks"
        case locale
        case timezone
        case localTime = "local_time"
    }
}

private struct ParseIntentTaskContext: Encodable {
    let id: UUID
    let title: String
    let status: String
    let priority: String
    let windowStart: String?
    let windowEnd: String?

    init(task: RhythmTask) {
        let formatter = ISO8601DateFormatter()
        self.id = task.id
        self.title = task.title
        self.status = task.statusRaw
        self.priority = task.priorityRaw
        self.windowStart = task.windowStart.map { formatter.string(from: $0) }
        self.windowEnd = task.windowEnd.map { formatter.string(from: $0) }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case priority
        case windowStart = "window_start"
        case windowEnd = "window_end"
    }
}

@Observable
@MainActor
final class LLMService {
    // MARK: - Published State
    
    private(set) var isProcessing = false
    private(set) var lastError: LLMError?
    
    // MARK: - Private Properties
    
    private let session: URLSession
    private let baseURL: URL
    
    // MARK: - Types
    
    enum LLMError: LocalizedError {
        case networkError(String)
        case invalidResponse
        case parsingFailed(String)
        case rateLimited
        case serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .networkError(let msg):
                return "Network error: \(msg)"
            case .invalidResponse:
                return "Invalid response from AI"
            case .parsingFailed(let msg):
                return "Couldn't parse response: \(msg)"
            case .rateLimited:
                return "Too many requests. Please wait a moment."
            case .serverError(let code):
                return "Server error (\(code))"
            }
        }
    }

    // MARK: - Initialization
    
    init(
        baseURL: URL = AppConfig.apiBaseURL
    ) {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.apiTimeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Main API
    
    /// Parse user's voice input and return all intents (supports multiple)
    func parseIntents(from utterance: String, existingTasks: [RhythmTask] = []) async -> VoiceIntentResult {
        isProcessing = true
        lastError = nil
        
        defer { isProcessing = false }
        
        do {
            let response = try await callBackend(utterance: utterance, existingTasks: existingTasks)
            return response.toVoiceIntentResult(rawUtterance: utterance)
        } catch let error as LLMError {
            lastError = error
            return generateFallbackIntentResult(from: utterance)
        } catch {
            lastError = .networkError(error.localizedDescription)
            return generateFallbackIntentResult(from: utterance)
        }
    }
    
    /// Parse user's voice input and return single intent (legacy, uses first intent)
    func parseIntent(from utterance: String, existingTasks: [RhythmTask] = []) async -> VoiceIntent {
        let result = await parseIntents(from: utterance, existingTasks: existingTasks)
        
        if let firstCreate = result.createIntents.first {
            return .createTask(firstCreate)
        } else if let firstUpdate = result.updateIntents.first {
            return .updateTask(firstUpdate)
        } else {
            return .unknown(utterance)
        }
    }
    
    // MARK: - Backend Call
    
    private func callBackend(utterance: String, existingTasks: [RhythmTask]) async throws -> LLMIntentResponse {
        let url = baseURL.appendingPathComponent(AppConfig.parseEndpointPath)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ParseIntentRequest(
            utterance: utterance,
            existingTasks: existingTasks.prefix(20).map(ParseIntentTaskContext.init(task:)),
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            localTime: ISO8601DateFormatter().string(from: Date())
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            throw LLMError.rateLimited
        default:
            throw LLMError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(LLMIntentResponse.self, from: data)
        } catch {
            throw LLMError.parsingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Fallback Generation
    
    /// Generate fallback intents when LLM is unavailable (supports multiple)
    private func generateFallbackIntentResult(from utterance: String) -> VoiceIntentResult {
        let lowercased = utterance.lowercased()
        var createIntents: [CreateTaskIntent] = []
        var updateIntents: [UpdateTaskIntent] = []
        
        // Split by common conjunctions to find multiple intents
        let segments = splitByConjunctions(utterance)
        
        for segment in segments {
            let segmentLower = segment.lowercased()
            var isUpdate = false
            
            // Check for update action keywords
            let updateKeywords: [(keywords: [String], action: TaskAction)] = [
                (["done", "finished", "complete", "completed", "完成", "做完"], .complete),
                (["start", "begin", "let's do", "开始", "做"], .start),
                (["pause", "stop", "暂停"], .pause),
                (["resume", "continue", "继续"], .resume),
                (["skip", "not today", "跳过"], .skip),
                (["delete", "remove", "cancel", "删除", "取消"], .delete),
                (["snooze", "later", "remind me later", "稍后", "等会"], .snooze),
                (["reschedule", "move to", "改到", "推迟"], .reschedule)
            ]
            
            for (keywords, action) in updateKeywords {
                if keywords.contains(where: { segmentLower.contains($0) }) {
                    let targetQuery = TaskTargetQuery(
                        titleKeywords: extractKeywords(from: segment),
                        reference: nil,
                        timeReference: nil,
                        statusFilter: nil,
                        priorityFilter: nil,
                        isMultiple: false,
                        rawDescription: segment
                    )
                    
                    let intent = UpdateTaskIntent(
                        action: action,
                        targetQuery: targetQuery,
                        parameters: nil,
                        rawUtterance: segment,
                        confidence: 0.4
                    )
                    updateIntents.append(intent)
                    isUpdate = true
                    break
                }
            }
            
            // If not an update, treat as create
            if !isUpdate && !segment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let title = extractTitleFallback(from: segment)
                let scheduleWindow = extractScheduleWindowFallback(from: segment)
                let priority = extractPriorityFallback(from: segment)
                
                // Only add if we have a reasonable title
                if title.count >= 2 {
                    let intent = CreateTaskIntent(
                        title: title,
                        scheduleWindow: scheduleWindow,
                        deadline: nil,
                        priority: priority,
                        note: nil,
                        rawUtterance: segment,
                        confidence: 0.3
                    )
                    createIntents.append(intent)
                }
            }
        }
        
        // If nothing was parsed, default to single create intent
        if createIntents.isEmpty && updateIntents.isEmpty {
            let title = extractTitleFallback(from: utterance)
            let scheduleWindow = extractScheduleWindowFallback(from: utterance)
            let priority = extractPriorityFallback(from: utterance)
            
            let intent = CreateTaskIntent(
                title: title,
                scheduleWindow: scheduleWindow,
                deadline: nil,
                priority: priority,
                note: nil,
                rawUtterance: utterance,
                confidence: 0.3
            )
            createIntents.append(intent)
        }
        
        return VoiceIntentResult(
            createIntents: createIntents,
            updateIntents: updateIntents,
            rawUtterance: utterance,
            confidence: 0.4
        )
    }
    
    /// Split utterance by conjunctions to find multiple intents
    private func splitByConjunctions(_ text: String) -> [String] {
        // Common conjunctions in English and Chinese
        let conjunctions = [
            " and ", " then ", " also ", ", then ", ", and ",
            "然后", "还要", "顺便", "另外", "同时", "接着", "并且"
        ]
        
        var segments = [text]
        
        for conjunction in conjunctions {
            var newSegments: [String] = []
            for segment in segments {
                let parts = segment.components(separatedBy: conjunction)
                newSegments.append(contentsOf: parts)
            }
            segments = newSegments
        }
        
        return segments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Generate a basic intent when LLM is unavailable (legacy single intent)
    private func generateFallbackIntent(from utterance: String) -> VoiceIntent {
        let result = generateFallbackIntentResult(from: utterance)
        
        if let firstCreate = result.createIntents.first {
            return .createTask(firstCreate)
        } else if let firstUpdate = result.updateIntents.first {
            return .updateTask(firstUpdate)
        } else {
            return .unknown(utterance)
        }
    }
    
    private func extractKeywords(from text: String) -> [String] {
        // Extract meaningful words (nouns, verbs) - simple implementation
        let stopWords = Set(["the", "a", "an", "to", "for", "my", "this", "that", "with", "and", "or", "is", "it", "i", "me"])
        let words = text.lowercased()
            .components(separatedBy: .whitespaces)
            .filter { $0.count > 2 && !stopWords.contains($0) }
        return Array(words.prefix(5))
    }
    
    private func extractTitleFallback(from text: String) -> String {
        // Simple title extraction: use first sentence or first 50 chars
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let firstSentence = sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
        
        if firstSentence.count <= 50 {
            return firstSentence
        }
        
        let truncated = String(firstSentence.prefix(47))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }
    
    private func extractScheduleWindowFallback(from text: String) -> ScheduleWindow? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Simple time pattern matching
        if lowercased.contains("tonight") || lowercased.contains("this evening") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 18
            components.minute = 0
            let start = calendar.date(from: components)
            
            components.hour = 22
            let end = calendar.date(from: components)
            
            return ScheduleWindow(start: start, end: end, label: "This evening", isFlexible: true)
        }
        
        if lowercased.contains("tomorrow morning") {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 8
            components.minute = 0
            let start = calendar.date(from: components)
            
            components.hour = 12
            let end = calendar.date(from: components)
            
            return ScheduleWindow(start: start, end: end, label: "Tomorrow morning", isFlexible: true)
        }
        
        if lowercased.contains("tomorrow") {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            let start = calendar.date(from: components)
            
            return ScheduleWindow(start: start, end: nil, label: "Tomorrow", isFlexible: true)
        }
        
        if lowercased.contains("this afternoon") {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 13
            components.minute = 0
            let start = calendar.date(from: components)
            
            components.hour = 17
            let end = calendar.date(from: components)
            
            return ScheduleWindow(start: start, end: end, label: "This afternoon", isFlexible: true)
        }
        
        if lowercased.contains("later") || lowercased.contains("soon") {
            let start = calendar.date(byAdding: .hour, value: 1, to: now)
            return ScheduleWindow(start: start, end: nil, label: "Later", isFlexible: true)
        }
        
        return nil
    }
    
    private func extractPriorityFallback(from text: String) -> TaskPriority {
        let lowercased = text.lowercased()
        
        if lowercased.contains("urgent") || lowercased.contains("important") ||
           lowercased.contains("asap") || lowercased.contains("must") {
            return .urgent
        }
        
        if lowercased.contains("whenever") || lowercased.contains("if possible") ||
           lowercased.contains("low priority") || lowercased.contains("maybe") {
            return .low
        }
        
        return .normal
    }
}
