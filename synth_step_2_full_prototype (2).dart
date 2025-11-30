--- FILE: README.md ---
# The Synth – Storeylands MindGate Labs

**AI-driven Voice-to-Avatar Real-Time Demo**

> ⚠️ **Private Investor Preview** – Access requires NDA. All intellectual property belongs to Travis H Storey, CEO & Owner. Co-created by Nova AI Assistant.

## Overview
The Synth is a cutting-edge prototype from Storeylands MindGate Labs that converts voice or text prompts into real-time animated AI avatars.

### Features
- Speech-to-Text (STT) & Text-to-Speech (TTS)
- Real-time AI avatar generation from prompts
- WebRTC streaming for live avatar animation
- Flutter frontend + Node.js backend
- NDA & IP protection integrated

## Quick Start
### Backend
Start the backend servers with Docker:
```bash
docker-compose up
```
This will start both the AI avatar engine and WebRTC server.

### Flutter App
Run the Flutter app on an Android device or emulator:
```bash
flutter run --release
```

1. Accept NDA in the app.
2. Speak or type a prompt.
3. Watch the AI avatar respond in real-time.

## Investor Notes
- Only authorized investors should access this demo.
- API keys and sensitive configuration are stored in `.env` and not included in GitHub.
- Do not copy, share, or distribute any part of this project.
- For evaluation only.

## Project Structure
```
/lib         # Flutter frontend code
/backend     # Node.js backend (AI + WebRTC)
/assets      # Placeholder assets, avatars, logos
/docker-compose.yml  # Docker setup for backend
/README.md   # This file
```

## Contact
For questions or support regarding this demo, contact:
**Travis H Storey** – CEO & Owner, Storeylands MindGate Labs
Email: [Your secure email here]

--- End of README ---
