# Rhythm

**AI productivity iOS app that gives a sense of planning first, then gently nudges action.**

## Overview

Rhythm is a voice-first task management app designed around the principle of gentle productivity. Instead of commanding users to complete tasks, Rhythm provides a "preview → invite" rhythm that respects user autonomy and reduces pressure.

### Core Principles

1. **Voice-first**: All core actions can be done via voice (create task, adjust schedule, snooze, confirm completion)
2. **Options-first**: The system presents 2-3 choices + custom, never forcing a single path
3. **User-Stated Plan First**: User's own words ("tonight", "tomorrow", "first do X") have highest priority
4. **Preview → Invite**: No command-style reminders; every nudge is grounded in a prior "rhythm preview"
5. **Snooze-first**: Users can snooze/reschedule/skip anytime, without shame

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### 1. Clone and Open

```bash
git clone <repository-url>
cd Rhythm
open Rhythm.xcodeproj
```

### 2. Configure Backend (Optional)

The app works offline-first. To connect to the backend API:

1. Set the environment variable `RHYTHM_API_URL` to your backend URL
2. Or modify `AppConfig.swift` to change the default URL

```swift
// Default: http://localhost:8000
static var apiBaseURL: URL { ... }
```

### 3. Build and Run

1. Select your target device/simulator
2. Build and run (⌘R)
3. Grant microphone and speech recognition permissions when prompted

## Permissions Required

Add these to your Info.plist (Xcode should auto-generate):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Rhythm uses your microphone for voice input to create tasks hands-free.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Rhythm transcribes your voice to understand what you want to accomplish.</string>
```

## Architecture

### Project Structure

```
Rhythm/
├── RhythmApp.swift             # App entry point
├── Config/
│   └── AppConfig.swift         # Configuration constants
├── Models/                     # SwiftData entities
│   ├── RhythmTask.swift
│   ├── Utterance.swift
│   ├── PlanSignal.swift
│   ├── Tag.swift
│   ├── TaskScheduleChange.swift
│   ├── EventLog.swift
│   └── Enums/
├── Services/                   # Business logic
│   ├── SpeechService.swift
│   ├── PlanningService.swift
│   ├── NotificationScheduler.swift
│   ├── EventLogService.swift
│   └── SyncService.swift
├── ViewModels/                 # MVVM view models
├── Views/                      # SwiftUI views
├── Intents/                    # App Intents for Shortcuts
├── Extensions/                 # Swift extensions
└── Resources/
    └── Copy.swift              # UI copy (gentle tone)
```

### Data Flow

```
User Voice → SpeechService → PlanningService (API) → ViewModel → SwiftData
                                    ↓
                            Planning Signals
                            Time Windows
                            Suggested Tags
```

### Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Concurrency | Swift async/await |
| Architecture | MVVM + Services |
| Voice Input | Speech Framework (SFSpeechRecognizer) |
| Notifications | UNUserNotificationCenter |
| Networking | URLSession (REST) |

## Features

### MVP (v0.1)

- [x] Voice Quick Add with planning signal extraction
- [x] Time window selection (2-3 options + custom)
- [x] Tag suggestions and management
- [x] Plan view (day/week/month)
- [x] Tasks view (board + list)
- [x] Snooze with preset options
- [x] Local notifications (preview/start/end)
- [x] Action Button integration via App Intents
- [x] Offline-first with sync hooks
- [x] Event logging for future learning

### Planned

- [ ] Backend integration (Supabase)
- [ ] Push notifications (APNs)
- [ ] Memory/retrospective features
- [ ] Pattern learning
- [ ] Widget support

## Assumptions

The following assumptions were made during implementation:

1. **Backend API**: Defaults to `http://localhost:8000`. The app works offline with local fallback parsing.

2. **Time Windows**:
   - "Tonight" = 7:00 PM - 10:00 PM today (or tomorrow if past 7 PM)
   - "Tomorrow morning" = 9:00 AM - 12:00 PM tomorrow
   - Default buffer = 15 minutes before/after windows

3. **Morning Preview**: Scheduled for 8:00 AM by default (configurable in Settings)

4. **Tag Normalization**: Lowercase, trimmed, max 20 characters

5. **Snooze Reset**: Snooze counts are preserved for learning (not reset daily)

6. **Voice Input**:
   - Press-and-hold threshold: 0.3 seconds
   - Maximum recording duration: 60 seconds

7. **Offline Mode**: Tasks created offline are marked dirty and sync when connection returns

8. **Data Storage**: Local SwiftData only for MVP; CloudKit disabled

## Testing

Run tests with:

```bash
# Command line
xcodebuild test -scheme Rhythm -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode
⌘U
```

### Test Coverage

- Time window calculations
- Tag normalization
- Task lifecycle (start/pause/complete/skip/snooze)
- Event logging
- Date extensions

## UI/UX Design

### Design Principles

- **Warm, not cold**: Soft coral/amber palette instead of stark blues
- **Invitational, not commanding**: "Want to start?" not "Start now!"
- **Supportive snooze**: "No worries, let's find another time"

### Typography

- SF Rounded for warmth
- Generous spacing

### Colors

| Name | Use |
|------|-----|
| rhythmCoral | Primary accent |
| rhythmAmber | Secondary/warnings |
| rhythmSage | Calm/"could do" |
| rhythmCream | Light background |
| rhythmCharcoal | Dark background |

## Action Button Integration

The app supports iOS Action Button via App Intents:

1. Open **Settings** → **Action Button**
2. Select **Shortcut**
3. Choose **Quick Add** from Rhythm

Or use Siri:
- "Add task with Rhythm"
- "Quick add in Rhythm"

## Backend API (Expected)

The app expects these endpoints:

```
POST /api/v1/parse
Body: { "utterance": "string" }
Response: {
  "planning_signals": [...],
  "candidate_time_windows": [...],
  "suggested_tags": [...],
  "plan_sketch": {...},
  "extracted_title": "string",
  "opening_action": "string"
}

POST /api/v1/tasks
POST /api/v1/events/batch
```

## Future Extension Points

1. **SyncService**: Ready for backend sync, just implement API calls
2. **NotificationScheduler**: Hooks for APNs push notifications
3. **EventLogService**: All actions logged for ML/analytics
4. **MemoryView**: Placeholder ready for retrospective features
5. **PlanningService**: Local fallback can be enhanced with on-device ML

## Contributing

1. Follow the existing code style
2. Write tests for new features
3. Keep UI copy in `Copy.swift`
4. Use gentle, invitational language

## License

[Your License Here]

---

Built with ❤️ for gentle productivity.

