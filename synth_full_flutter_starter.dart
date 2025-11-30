// STOREYLANDS MINDGATE LABS — THE SYNTH
// Full Synth starter: Flutter frontend + Node.js backend stubs + README
// ---------------------------------------------------------------------
// This single text file contains multiple files you can copy into a project.
// Each section is labeled with a "--- FILE: <path> ---" header.
// Files included:
//  - pubspec.yaml
//  - lib/main.dart
//  - lib/services/stt_service.dart
//  - lib/services/tts_service.dart
//  - lib/services/realtime_service.dart
//  - lib/screens/home_screen.dart
//  - assets/README.md
//  - backend/server_stub.js
//  - README.md
// ---------------------------------------------------------------------

--- FILE: pubspec.yaml ---
name: synth
description: "Storeylands MindGate Labs - The Synth (Flutter starter)"
publish_to: 'none'
version: 0.1.0
environment:
  sdk: ">=2.18.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  http: ^1.2.0
  websocket: ^2.0.1
  provider: ^6.0.5

flutter:
  uses-material-design: true
  assets:
    - assets/

--- FILE: lib/main.dart ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SynthApp());
}

class SynthApp extends StatelessWidget {
  const SynthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RealtimeService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'The Synth',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

--- FILE: lib/services/stt_service.dart ---
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool initialized = false;
  bool listening = false;
  String lastWords = '';

  Future init() async {
    initialized = await _speech.initialize();
    notifyListeners();
  }

  Future startListening() async {
    if (!initialized) await init();
    listening = true;
    _speech.listen(onResult: (result) {
      lastWords = result.recognizedWords;
      notifyListeners();
    });
  }

  Future stopListening() async {
    listening = false;
    _speech.stop();
    notifyListeners();
  }
}

--- FILE: lib/services/tts_service.dart ---
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
  }

  Future speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  Future stop() async => await _tts.stop();
}

--- FILE: lib/services/realtime_service.dart ---
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:websocket/websocket.dart';

// A lightweight WebSocket wrapper for connecting to a realtime backend
class RealtimeService extends ChangeNotifier {
  WebSocket? _ws;
  String? lastMessage;
  bool connected = false;

  Future connect(String url) async {
    try {
      _ws = await WebSocket.connect(url);
      connected = true;
      _ws!.listen((dynamic message) {
        lastMessage = message.toString();
        notifyListeners();
      }, onDone: () {
        connected = false;
        notifyListeners();
      }, onError: (err) {
        connected = false;
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      connected = false;
      lastMessage = 'connect error: \$e';
      notifyListeners();
    }
  }

  void sendJson(Map<String, dynamic> data) {
    if (_ws != null && connected) {
      _ws!.add(jsonEncode(data));
    }
  }

  Future disconnect() async {
    await _ws?.close();
    connected = false;
    notifyListeners();
  }
}

--- FILE: lib/screens/home_screen.dart ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/realtime_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SttService _stt;
  late TtsService _tts;
  late RealtimeService _realtime;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stt = SttService();
    _tts = TtsService();
    _realtime = RealtimeService();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _realtime.disconnect();
    super.dispose();
  }

  Future _connectRealtime() async {
    // Replace with your backend realtime ws url (wss://...)
    await _realtime.connect('ws://localhost:8080');
  }

  Future _sendForVideo() async {
    final prompt = _promptController.text.isEmpty ? _stt.lastWords : _promptController.text;
    if (prompt.isEmpty) return;

    // Example: send json to realtime backend to request avatar/video generation
    _realtime.sendJson({
      'type': 'generate_video',
      'prompt': prompt,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Synth')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type a prompt (or speak below)...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async => await _stt.startListening(),
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Listening'),
                ),
                ElevatedButton.icon(
                  onPressed: () async => await _stt.stopListening(),
                  icon: const Icon(Icons.mic_off),
                  label: const Text('Stop'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _tts.speak(_stt.lastWords),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Speak'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _connectRealtime,
              child: const Text('Connect Realtime Backend'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sendForVideo,
              child: const Text('Generate Voice → Video'),
            ),

            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live STT result:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_stt.lastWords.isEmpty ? 'No speech yet' : _stt.lastWords),
                    ),
                    const SizedBox(height: 12),
                    const Text('Realtime backend status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_realtime.connected ? 'Connected' : 'Disconnected'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Backend last message:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_realtime.lastMessage ?? '—'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

--- FILE: assets/README.md ---
Place any placeholder assets here (avatars, logos, sample audio). The app won't crash if empty.

--- FILE: backend/server_stub.js ---
// Lightweight Node.js WebSocket stub for realtime demo
// Run: node server_stub.js

const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

console.log('Realtime stub running on ws://localhost:8080');

wss.on('connection', function connection(ws) {
  console.log('client connected');
  ws.on('message', function incoming(message) {
    console.log('received:', message);
    try {
      const data = JSON.parse(message);
      if (data.type === 'generate_video') {
        // In a real system: call OpenAI / GAIAgrid / media pipeline to generate a video
        // For demo: respond with a fake video URL after a short delay
        setTimeout(() => {
          ws.send(JSON.stringify({
            type: 'video_generated',
            video_url: 'https://example.com/generated_video_demo.mp4',
            prompt: data.prompt,
          }));
        }, 1500);
      } else {
        ws.send(JSON.stringify({ echo: data }));
      }
    } catch (e) {
      ws.send(JSON.stringify({ error: 'invalid json' }));
    }
  });

  ws.on('close', () => console.log('client disconnected'));
});

--- FILE: README.md ---
# The Synth — Starter Project

This repo contains a full starter scaffold for "The Synth" — speech-driven AV generator for Storeylands MindGate Labs.

## What is included
- Flutter frontend (STT, TTS, Realtime WebSocket integration)
- Node.js realtime backend stub for development/testing
- Clear extension points for connecting real AI services (OpenAI Realtime, GAIAgrid, custom ML pipelines)

## How to run (local dev)
### Backend
1. Install Node.js
2. `cd backend` and run `npm init -y` then `npm i ws`
3. `node server_stub.js`

### Frontend
1. Ensure Flutter SDK is installed
2. Copy the `pubspec.yaml` and `lib/` into a new Flutter project
3. `flutter pub get`
4. `flutter run` (or use an emulator)

## Next steps / integration ideas
- Replace Node stub with a secure server that calls OpenAI Realtime (or GAIAgrid). Use signed tokens for auth.
- Add a streaming audio pipeline: capture raw mic audio and stream to a speech-to-text realtime model for lower-latency STT.
- Implement an avatar renderer: use a WebRTC or WebGL canvas to render an animated face synced to audio, or connect to a third-party video generation service.
- Add persistent storage (Firestore / Supabase / Redis) for generated assets, prompts, and user profiles.

---

// End of mult-file bundle
// Copy each section into the respective file in your project.

--- NEW: backend/server_secure.js ---
// Secure Node.js backend + WebSocket + proxy to OpenAI-style Realtime/AI endpoints
// NOTE: This is a template — replace the AI call with your GAIAgrid/OpenAI integration.
// Install: npm i express ws node-fetch dotenv cors

require('dotenv').config();
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const fetch = require('node-fetch');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Simple token check middleware for basic protection (improve in production)
function requireApiKey(req, res, next) {
  const key = req.header('x-api-key') || req.query.api_key;
  if (!key || key !== process.env.SERVER_API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

app.get('/health', (req, res) => res.json({ ok: true }));

// Example REST endpoint that proxies a prompt to an AI text-to-video job
app.post('/api/generate-video', requireApiKey, async (req, res) => {
  try {
    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ error: 'missing prompt' });

    // Replace with real call to your AI/video pipeline (OpenAI/GAIAgrid/other)
    // Example: call an external service and return an asset id/url
    // const aiResp = await fetch('https://api.example.com/generate', ... )

    // For demo: queue job and return a job_id
    const jobId = `job_\${Date.now()}`;

    // In production: enqueue and process job, store result to S3 or similar
    res.json({ jobId, status: 'queued' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// WebSocket realtime: clients connect, authenticate with server API key
wss.on('connection', function connection(ws, req) {
  console.log('ws: client connected');

  // Minimal auth: expect first message to be a json with apiKey
  let authenticated = false;

  ws.on('message', async function incoming(message) {
    try {
      const data = JSON.parse(message);
      if (!authenticated) {
        if (data.type === 'auth' && data.apiKey === process.env.SERVER_API_KEY) {
          authenticated = true;
          ws.send(JSON.stringify({ type: 'auth_ok' }));
          return;
        } else {
          ws.send(JSON.stringify({ type: 'error', message: 'unauthenticated' }));
          ws.close();
          return;
        }
      }

      // Handle generate_video messages by proxying to AI backend
      if (data.type === 'generate_video') {
        const prompt = data.prompt || '';

        // Example placeholder: call your AI provider here (server-side)
        // This keeps your API keys secret and allows you to sign tokens for clients.

        // Simulate generation and respond with a URL when done
        setTimeout(() => {
          ws.send(JSON.stringify({ type: 'video_generated', video_url: `https://cdn.example.com/videos/\${Date.now()}.mp4`, prompt }));
        }, 2000);
      }

      // Other message types: forward to AI, handle TTS requests, etc.
    } catch (err) {
      console.error('ws message error', err);
      ws.send(JSON.stringify({ type: 'error', message: 'invalid_message' }));
    }
  });

  ws.on('close', () => console.log('ws: client disconnected'));
});

// Static files (avatar demo)
app.use('/static', express.static(__dirname + '/static'));

const port = process.env.PORT || 8080;
server.listen(port, () => console.log(`Secure server running on http://localhost:\${port}`));

--- NEW: backend/static/avatar.html ---
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Synth Avatar Demo</title>
  <style>body{margin:0;background:#111;color:#eee;font-family:sans-serif}#localVideo,#remoteVideo{width:45%;}</style>
</head>
<body>
  <h2 style="text-align:center">The Synth — Avatar & WebRTC Demo</h2>
  <div style="display:flex;gap:10px;justify-content:center;align-items:flex-start;">
    <video id="localVideo" autoplay muted playsinline></video>
    <video id="remoteVideo" autoplay playsinline></video>
  </div>
  <script>
    // Simple WebRTC loopback demo + placeholder for integrating a 3D avatar (Three.js)
    (async ()=>{
      try{
        const local = document.getElementById('localVideo');
        const remote = document.getElementById('remoteVideo');
        const pc1 = new RTCPeerConnection();
        const pc2 = new RTCPeerConnection();

        pc1.ontrack = (e)=>{ remote.srcObject = e.streams[0]; };
        pc2.ontrack = (e)=>{ /* unused for loopback */ };

        const stream = await navigator.mediaDevices.getUserMedia({ audio:true, video:true });
        local.srcObject = stream;
        stream.getTracks().forEach(track => pc1.addTrack(track, stream));

        pc1.onicecandidate = e=>{ if(e.candidate) pc2.addIceCandidate(e.candidate); };
        pc2.onicecandidate = e=>{ if(e.candidate) pc1.addIceCandidate(e.candidate); };

        const offer = await pc1.createOffer();
        await pc1.setLocalDescription(offer);
        await pc2.setRemoteDescription(offer);
        const answer = await pc2.createAnswer();
        await pc2.setLocalDescription(answer);
        await pc1.setRemoteDescription(answer);

        // At this point, remote video is loopback of local.
        // Replace the <video> drawing with a Three.js canvas that's lip-synced to audio.
      }catch(e){ console.error(e); alert('WebRTC error: '+e.message); }
    })();
  </script>
</body>
</html>

--- NEW: frontend/flutter_webrtc_integration.md ---
Add WebRTC to Flutter using flutter_webrtc package. Example pubspec entry:

  flutter_webrtc: ^0.9.0

Key steps:
1. Use flutter_webrtc to create RTCPeerConnection and capture local stream.
2. Send SDP offers through your secure backend (signaling over ws) to connect to avatar renderer or other clients.
3. Render remote stream in a RTCVideoView inside Flutter.

This lets you stream synthesized avatar video into the Flutter app in real-time.

--- NEW: frontend/avatar_integration_notes.md ---
Options for avatar rendering (pick one based on your timeline):

1) Three.js (web) avatar: fast to prototype, expressive, runs in a webview. Use audio analysis for visemes.
2) Unity/Unreal engine avatar: high fidelity, heavier and requires native integration.
3) WebGL + WASM model: advanced, can run ML-based face animation in browser.

For a quick demo: serve avatar.html from backend and open in a webview inside Flutter. Later replace with WebRTC remote stream of server-generated avatar video.

--- NEW: deployment_and_packaging.md ---
# APK Packaging + Deploy Checklist (Play Store)

## Before build
- [ ] Ensure appId/package name is unique (e.g., com.storeyland.synth)
- [ ] Set app version and versionCode in android/app/build.gradle
- [ ] Add privacy policy URL (hosted on your domain) and include in Play Store listing
- [ ] Prepare app icons and feature graphic (512x512, 1024x500)
- [ ] Ensure backend has HTTPS (TLS) and a domain with valid certs
- [ ] Implement secure token exchange: do NOT embed secret API keys in the app
- [ ] Add Firebase/Crashlytics, Analytics (optional)

## Build signed APK / AAB
1. Generate signing key (keystore):
   `keytool -genkey -v -keystore ~/synth-release-key.jks -alias synth-key -keyalg RSA -keysize 2048 -validity 10000`
2. Reference keystore in `android/key.properties` and `android/app/build.gradle`.
3. Build an AAB (recommended):
   `flutter build appbundle --release`
   Or APK: `flutter build apk --release`

## Upload
- [ ] Create Play Console listing
- [ ] Upload AAB, fill store listing, content rating, privacy policy, screenshots
- [ ] Add testers/internal track first

## Post-release
- [ ] Monitor crashes, ANRs
- [ ] Rotate server tokens if leaked
- [ ] Add analytics funnels for voice/video features

--- NEW: security_and_operational_notes.md ---
# Security and Ops Notes
- Never call AI provider directly from client — always proxy through your server to keep keys secret.
- Use short-lived signed tokens for clients (JWT) to limit exposure.
- Host generated assets (videos) on a CDN with signed URLs.
- Rate-limit and authenticate endpoints; add logging and alerting.
- GDPR/CCPA: provide ways to delete user data, store consent for audio recordings.

---add copyrights, travis h storey as ceo and owner of synth and add co creator nova AI assistant and brains of the platform, with a disclamer contract on the beginning of it to state that no one can use this or take any of the stated project for there own they must sign a ndc agreement befor they read with
  
// End of added secure backend, avatar, and deploy materials
