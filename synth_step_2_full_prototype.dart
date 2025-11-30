// THE SYNTH — STEP 2: FULL PROTOTYPE STARTER
// This file bundle contains a working prototype scaffold for The Synth.
// Files included below are delimited with `--- FILE: <path> ---` headers.
// Copy each section into its respective file in your project.
// ------------------------------------------------------------------

--- FILE: pubspec.yaml ---
name: synth
description: Storeylands MindGate Labs - The Synth (Prototype)
publish_to: 'none'
version: 0.2.0
environment:
  sdk: '>=2.18.0 <3.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  provider: ^6.0.5
  http: ^1.2.0
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  flutter_webrtc: ^0.9.0
  websocket: ^2.0.1
  shared_preferences: ^2.1.1
  uuid: ^3.0.6

flutter:
  uses-material-design: true
  assets:
    - assets/

--- FILE: lib/main.dart ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'services/realtime_service.dart';
import 'services/memory_service.dart';
import 'services/emotion_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SynthApp());
}

class SynthApp extends StatelessWidget {
  const SynthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SttService()),
        ChangeNotifierProvider(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => RealtimeService()),
        ChangeNotifierProvider(create: (_) => MemoryService()),
        ChangeNotifierProvider(create: (_) => EmotionService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'The Synth',
        theme: ThemeData.dark(),
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
    initialized = await _speech.initialize(onStatus: (s) {}, onError: (e) {});
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
    await _speech.stop();
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

class RealtimeService extends ChangeNotifier {
  WebSocket? _ws;
  bool connected = false;
  String? lastMessage;

  Future connect(String url) async {
    try {
      _ws = await WebSocket.connect(url);
      connected = true;
      _ws!.listen((message) {
        lastMessage = message.toString();
        notifyListeners();
      }, onDone: () {
        connected = false;
        notifyListeners();
      }, onError: (err) {
        connected = false;
        lastMessage = 'error: '\$err;
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      connected = false;
      lastMessage = 'connect error: \$e';
      notifyListeners();
    }
  }

  void send(Map<String, dynamic> data) {
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

--- FILE: lib/services/memory_service.dart ---
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService extends ChangeNotifier {
  List<String> _memories = [];

  List<String> get memories => _memories;

  Future init() async {
    final prefs = await SharedPreferences.getInstance();
    _memories = prefs.getStringList('synth_memories') ?? [];
    notifyListeners();
  }

  Future addMemory(String m) async {
    _memories.add(m);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('synth_memories', _memories);
    notifyListeners();
  }
}

--- FILE: lib/services/emotion_service.dart ---
import 'package:flutter/foundation.dart';

// Extremely lightweight emotion detector (prototype).
class EmotionService extends ChangeNotifier {
  String lastEmotion = 'neutral';

  // Very simple heuristic based on keywords
  void analyzeText(String text) {
    final t = text.toLowerCase();
    if (t.contains('happy') || t.contains('love') || t.contains('great')) {
      lastEmotion = 'happy';
    } else if (t.contains('sad') || t.contains('upset') || t.contains('sorry')) {
      lastEmotion = 'sad';
    } else if (t.contains('angry') || t.contains('hate')) {
      lastEmotion = 'angry';
    } else {
      lastEmotion = 'neutral';
    }
    notifyListeners();
  }
}

--- FILE: lib/services/video_pipeline.dart ---
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoPipeline extends ChangeNotifier {
  String? generatedUrl;
  bool busy = false;

  // Call your server that orchestrates AI video generation
  Future generateVideo(String prompt, String apiBase, String apiKey) async {
    busy = true;
    notifyListeners();
    final resp = await http.post(Uri.parse('\$apiBase/api/generate-video'),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: jsonEncode({'prompt': prompt}));
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body);
      generatedUrl = j['video_url'] ?? j['job_url'] ?? null;
    } else {
      generatedUrl = null;
    }
    busy = false;
    notifyListeners();
  }
}

--- FILE: lib/screens/home_screen.dart ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/realtime_service.dart';
import '../services/memory_service.dart';
import '../services/emotion_service.dart';
import '../services/video_pipeline.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SttService stt;
  late TtsService tts;
  late RealtimeService realtime;
  late MemoryService memory;
  late EmotionService emotion;
  final TextEditingController promptCtrl = TextEditingController();
  final videoPipeline = VideoPipeline();

  @override
  void initState() {
    super.initState();
    stt = Provider.of<SttService>(context, listen: false);
    tts = Provider.of<TtsService>(context, listen: false);
    realtime = Provider.of<RealtimeService>(context, listen: false);
    memory = Provider.of<MemoryService>(context, listen: false);
    emotion = Provider.of<EmotionService>(context, listen: false);
    memory.init();
  }

  @override
  void dispose() {
    promptCtrl.dispose();
    super.dispose();
  }

  Future _generateVideo() async {
    final prompt = promptCtrl.text.isEmpty ? stt.lastWords : promptCtrl.text;
    if (prompt.isEmpty) return;
    emotion.analyzeText(prompt);
    await videoPipeline.generateVideo(prompt, 'http://localhost:8080', 'demo_key');
    if (videoPipeline.generatedUrl != null) {
      await memory.addMemory('Generated video for: ' + prompt);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Synth — Prototype')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: promptCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type or speak a prompt...'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Listen'),
                  onPressed: () async => await stt.startListening(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  onPressed: () async => await stt.stopListening(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Speak'),
                  onPressed: () => tts.speak(stt.lastWords),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _generateVideo,
                child: const Text('Generate Voice → Video (prototype)')),
            const SizedBox(height: 12),
            Consumer<EmotionService>(builder: (_, e, __) {
              return Text('Emotion: ' + e.lastEmotion);
            }),
            const SizedBox(height: 8),
            Expanded(
                child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Live STT:'),
                Consumer<SttService>(builder: (_, s, __) => Text(s.lastWords)),
                const SizedBox(height: 12),
                const Text('Memories:'),
                Consumer<MemoryService>(builder: (_, m, __) => Column(children: m.memories.map((mm) => Text('- ' + mm)).toList())),
                const SizedBox(height: 12),
                const Text('Video Pipeline State:'),
                Text(videoPipeline.generatedUrl ?? 'No video yet'),
              ]),
            ))
          ],
        ),
      ),
    );
  }
}

--- FILE: backend/server_prod.js ---
// Production-ready server stub (Node.js)
// Use express + ws + axios (or node-fetch) and wire to your AI provider.
// Replace placeholders with real provider calls.

require('dotenv').config();
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
app.use(cors());
app.use(bodyParser.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Basic auth for demo - swap with JWT or OAuth
function checkKey(req, res, next) {
  const k = req.header('x-api-key');
  if (!k || k !== process.env.SERVER_API_KEY) return res.status(401).json({ error: 'unauthorized' });
  next();
}

app.post('/api/generate-video', checkKey, async (req, res) => {
  const { prompt } = req.body;
  // TODO: integrate with your AI provider (OpenAI/GAIAgrid)
  // Example: call provider, poll job status, store to CDN.
  const fakeUrl = `https://cdn.example.com/videos/\${Date.now()}.mp4`;
  // Return immediate response with job/url
  res.json({ job_id: 'job_' + Date.now(), video_url: fakeUrl });
});

wss.on('connection', (ws) => {
  console.log('ws connected');
  ws.on('message', (msg) => {
    try {
      const j = JSON.parse(msg);
      if (j.type === 'auth' && j.apiKey === process.env.SERVER_API_KEY) {
        ws.send(JSON.stringify({ type: 'auth_ok' }));
      } else if (j.type === 'generate_video') {
        // Simulate asynchronous generation push
        setTimeout(() => {
          ws.send(JSON.stringify({ type: 'video_generated', video_url: `https://cdn.example.com/videos/\${Date.now()}.mp4`, prompt: j.prompt }));
        }, 2000);
      }
    } catch (e) {
      ws.send(JSON.stringify({ type: 'error', message: 'bad_request' }));
    }
  });
});

const port = process.env.PORT || 8080;
server.listen(port, () => console.log('server running on', port));

--- FILE: backend/Dockerfile ---
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["node", "server_prod.js"]

--- FILE: README_STEP2.md ---
# The Synth — Prototype Setup (Step 2)

## Backend
1. Create `.env` with `SERVER_API_KEY=` set to a secret.
2. `cd backend` then `npm init -y` and `npm i express ws cors body-parser dotenv`
3. `node server_prod.js`

## Frontend
1. Ensure Flutter SDK installed
2. Create flutter project and copy `pubspec.yaml` + `lib/` files
3. `flutter pub get`
4. Run `flutter run`

## Notes
- This prototype is designed for local development. Replace `http://localhost:8080` with your deployed backend when ready.
- Wire the backend to a real AI provider to produce real video assets. Keep API keys server-side only.

---
// END OF STEP 2 BUNDLE
// Copy each section into your project files.
