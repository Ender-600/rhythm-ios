//
//  LLMService.swift
//  Rhythm
//
//  Service for parsing voice input using LLM (OpenAI/Claude)
//  Handles intent classification and entity extraction
//

import Foundation

@Observable
@MainActor
final class LLMService {
    // MARK: - Published State
    
    private(set) var isProcessing = false
    private(set) var lastError: LLMError?
    
    // MARK: - Private Properties
    
    private let session: URLSession
    private let apiKey: String
    private let baseURL: URL
    private let model: String
    
    // MARK: - Types
    
    enum LLMError: LocalizedError {
        case noAPIKey
        case networkError(String)
        case invalidResponse
        case parsingFailed(String)
        case rateLimited
        case serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "API key not configured"
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
        apiKey: String = AppConfig.openAIAPIKey,
        baseURL: URL = AppConfig.openAIBaseURL,
        model: String = AppConfig.llmModel
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Main API
    
    /// Parse user's voice input and return all intents (supports multiple)
    func parseIntents(from utterance: String, existingTasks: [RhythmTask] = []) async -> VoiceIntentResult {
        guard !apiKey.isEmpty else {
            lastError = .noAPIKey
            return generateFallbackIntentResult(from: utterance)
        }
        
        isProcessing = true
        lastError = nil
        
        defer { isProcessing = false }
        
        do {
            let response = try await callLLM(utterance: utterance, existingTasks: existingTasks)
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
    
    // MARK: - LLM Call
    
    private func callLLM(utterance: String, existingTasks: [RhythmTask]) async throws -> LLMIntentResponse {
        let url = baseURL.appendingPathComponent("chat/completions")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = buildSystemPrompt(existingTasks: existingTasks)
        let userPrompt = buildUserPrompt(utterance: utterance)
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
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
        
        // Parse OpenAI response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        
        // Parse the JSON content from the LLM
        guard let contentData = content.data(using: .utf8) else {
            throw LLMError.parsingFailed("Invalid content encoding")
        }
        
        do {
            let intentResponse = try JSONDecoder().decode(LLMIntentResponse.self, from: contentData)
            return intentResponse
        } catch {
            throw LLMError.parsingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Prompt Building
    
    private func buildSystemPrompt(existingTasks: [RhythmTask]) -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentTime = formatter.string(from: now)
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        let weekday = weekdayFormatter.string(from: now)
        
        var prompt = """
        You are an intent parser for a task management app called Rhythm. Your job is to understand the user's voice command and extract structured data.
        
        **IMPORTANT**: A single voice command can contain MULTIPLE intents - both creating new tasks AND updating existing tasks. Parse ALL intents in the utterance.
        
        Current time: \(currentTime) (\(weekday))
        
        ## Response Format
        
        Always respond with this JSON structure (arrays can have 0 or more items):
        ```json
        {
            "create_tasks": [
                {
                    "title": "concise task title",
                    "schedule_description": "this evening" or "tomorrow morning" etc,
                    "schedule_start": "ISO8601 datetime or null",
                    "schedule_end": "ISO8601 datetime or null",
                    "deadline": "ISO8601 datetime or null",
                    "priority": "urgent" | "normal" | "low",
                    "note": "any additional context or null",
                    "is_flexible": true/false
                }
            ],
            "update_tasks": [
                {
                    "action": "task_started" | "task_paused" | "task_resumed" | "task_completed" | "task_skipped" | "task_deleted" | "task_snoozed" | "task_rescheduled",
                    "target_description": "description of which task(s)",
                    "title_keywords": ["keywords", "from", "title"],
                    "time_reference": "the morning task" or null,
                    "status_filter": "not_started" | "in_progress" | "done" or null,
                    "is_multiple": false,
                    "snooze_duration": minutes as integer or null,
                    "snooze_until": "ISO8601 datetime or null",
                    "new_schedule_description": "for reschedule" or null,
                    "new_schedule_start": "ISO8601 or null",
                    "new_schedule_end": "ISO8601 or null",
                    "reason": "reason for action or null"
                }
            ],
            "confidence": 0.0-1.0
        }
        ```
        
        ## Examples
        
        **Example 1 - Single create:**
        "帮我安排今晚看那本新书"
        → create_tasks: [{ title: "看那本新书", schedule_description: "tonight", ... }]
        → update_tasks: []
        
        **Example 2 - Single update:**
        "把购物任务标记为完成"
        → create_tasks: []
        → update_tasks: [{ action: "task_completed", title_keywords: ["购物"], ... }]
        
        **Example 3 - Multiple creates:**
        "明天要去银行还要去超市买菜"
        → create_tasks: [
            { title: "去银行", schedule_description: "tomorrow", ... },
            { title: "去超市买菜", schedule_description: "tomorrow", ... }
        ]
        → update_tasks: []
        
        **Example 4 - Mixed (create + update):**
        "添加一个下午开会的提醒，然后把邮件任务标记完成"
        → create_tasks: [{ title: "开会", schedule_description: "this afternoon", ... }]
        → update_tasks: [{ action: "task_completed", title_keywords: ["邮件"], ... }]
        
        **Example 5 - Multiple updates:**
        "把早上的任务都跳过，然后开始做作业那个任务"
        → create_tasks: []
        → update_tasks: [
            { action: "task_skipped", time_reference: "morning", is_multiple: true, ... },
            { action: "task_started", title_keywords: ["作业"], ... }
        ]
        
        ## Guidelines
        
        1. **Title extraction**: Create a clear, concise title (3-8 words) that captures the essence of the task.
        
        2. **Time parsing**: 
           - "tonight", "this evening", "今晚" → same day evening (6pm-10pm)
           - "tomorrow morning", "明天早上" → next day 8am-12pm
           - "in an hour", "一小时后" → current time + 1 hour
           - "around 3", "大概3点" → 3pm with is_flexible=true
           - "at 3", "3点" → 3pm with is_flexible=false
           - "by Friday", "周五前" → deadline
        
        3. **Priority inference**:
           - "urgent", "important", "asap", "must", "紧急", "重要" → urgent
           - "whenever", "if possible", "low priority", "有空", "可能的话" → low
           - Default → normal
        
        4. **Action detection for updates**:
           - "start", "begin", "开始", "做" → task_started
           - "pause", "stop", "暂停" → task_paused
           - "continue", "resume", "继续" → task_resumed
           - "done", "finished", "complete", "完成", "做完了" → task_completed
           - "skip", "not today", "跳过", "今天不做" → task_skipped
           - "delete", "remove", "删除", "取消" → task_deleted
           - "snooze", "later", "稍后", "等会" → task_snoozed
           - "move to", "reschedule", "改到", "推迟" → task_rescheduled
        
        5. **Task identification**: Use keywords, time references, or status to identify which task(s).
        
        6. **Multiple intents**: Parse ALL intents in the utterance. Look for conjunctions like "and", "then", "also", "还要", "然后", "顺便".
        """
        
        // Add existing tasks context if available
        if !existingTasks.isEmpty {
            prompt += "\n\n## Existing Tasks (for update matching):\n"
            for task in existingTasks.prefix(10) {
                let statusStr = task.status.rawValue
                let timeStr = task.windowStart.map { formatter.string(from: $0) } ?? "no time set"
                prompt += "- \"\(task.title)\" [\(statusStr)] (\(timeStr))\n"
            }
        }
        
        return prompt
    }
    
    private func buildUserPrompt(utterance: String) -> String {
        return """
        Parse this voice command and return the appropriate JSON:
        
        "\(utterance)"
        """
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
