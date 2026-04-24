# Engel

A reflective iOS journal built around two spaces: a **green globe** for energy, wins, and aliveness, and a **red globe** for friction, heaviness, and feeling stuck. Capture fragments by voice or text, let AI suggest sorting and tags, and notice patterns weekly. No scoring, no streaks, no advice — just your thoughts, kept visible and always yours.

## Prerequisites

- macOS with Xcode 15+
- iOS 17+ simulator or device
- Python 3.11+ (for the backend)

## Getting Started

### iOS App

```bash
# Open in Xcode
xed .

# Or build from the command line
xcodebuild -scheme engel -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Backend

```bash
cd backend
cp ../.env.example .env        # Fill in your API keys
pip install -e .
uvicorn app.main:app --reload
```

## Project Structure

```
engel/                   Xcode project root
  engel/                 App source
    views/               SwiftUI screens
    engel/theme/         Design tokens & typography
    features/capture/    Voice recording
    Fonts/               Fraunces & JetBrains Mono
  Assets.xcassets/       Color sets & images
backend/                 FastAPI server
  app/api/               Routes
  app/services/          Sort engine, insight engine
  app/core/              Config & settings
docs/                    Product specs & design system
```

## Design Principles

- Never prescribe, diagnose, or moralize
- Show at most one insight per week
- Skip is always a valid option
- Export is one tap
- No streaks, no guilt loops
- Authority stays with the human; AI suggestions are always editable

## Tech Stack

- **iOS**: SwiftUI, SwiftData, iOS 17+
- **Backend**: Python, FastAPI, SQLite
- **AI**: Anthropic Claude (sorting), OpenAI Whisper (transcription)
- **Fonts**: Fraunces (display), JetBrains Mono (UI)

## License

Private — all rights reserved.
