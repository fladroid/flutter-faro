import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'settings_screen.dart';

void main() {
  runApp(const FaroApp());
}

class FaroApp extends StatelessWidget {
  const FaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const FaroHome(),
    );
  }
}

class FaroHome extends StatefulWidget {
  const FaroHome({super.key});

  @override
  State<FaroHome> createState() => _FaroHomeState();
}

class _FaroHomeState extends State<FaroHome> {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final _storage = const FlutterSecureStorage();

  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  bool _listening = false;
  bool _loading = false;
  String _userText = '';
  String _claudeText = '';
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _initTts();
  }

  Future<void> _loadApiKey() async {
    final key = await _storage.read(key: 'anthropic_api_key');
    setState(() => _apiKey = key ?? '');
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('sr-RS');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
  }

  Future<void> _listen() async {
    if (_apiKey.isEmpty) {
      setState(() => _claudeText = 'Unesi API key u Postavkama prije korištenja.');
      return;
    }

    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }

    bool available = await _stt.initialize();
    if (!available) return;

    setState(() {
      _listening = true;
      _userText = '';
      _claudeText = '';
    });

    await _stt.listen(
      localeId: 'sr_RS',
      onResult: (result) {
        setState(() => _userText = result.recognizedWords);
        if (result.finalResult && _userText.isNotEmpty) {
          _stt.stop();
          setState(() => _listening = false);
          _sendToClaude(_userText);
        }
      },
    );
  }

  Future<void> _sendToClaude(String text) async {
    setState(() {
      _loading = true;
      _claudeText = '';
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': text}
          ],
        }),
      );

      final data = jsonDecode(response.body);
      final reply = data['content'][0]['text'] as String;

      setState(() {
        _claudeText = reply;
        _loading = false;
      });

      await _tts.speak(reply);
    } catch (e) {
      setState(() {
        _claudeText = 'Greška: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadApiKey();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'FARO',
                style: TextStyle(
                  color: Colors.indigo,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 60),
              if (_userText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userText,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              if (_loading)
                const CircularProgressIndicator(color: Colors.indigo),
              if (_claudeText.isNotEmpty && !_loading)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _claudeText,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _loading ? null : _listen,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? Colors.red : Colors.indigo,
                    boxShadow: [
                      BoxShadow(
                        color: (_listening ? Colors.red : Colors.indigo)
                            .withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _listening
                    ? 'Slušam...'
                    : _loading
                        ? 'Čekam odgovor...'
                        : 'Pritisni i govori',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
