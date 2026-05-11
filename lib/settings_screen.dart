import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _keyController = TextEditingController();
  final _promptController = TextEditingController();
  bool _saved = false;
  bool _obscure = true;
  double _speechRate = 0.7;
  int _maxTokens = 256;
  String _language = 'en';

  static const String _defaultPrompt =
      'Odgovori kratko i jasno, maksimalno 1-2 rečenice. Koristi prirodan govorni jezik.';

  static const Map<String, String> _languages = {
    'en': 'English',
    'de': 'Deutsch',
    'hr': 'Hrvatski',
    'sr': 'Srpski',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final key = await _storage.read(key: 'anthropic_api_key');
    final prompt = await _storage.read(key: 'system_prompt');
    final rate = await _storage.read(key: 'speech_rate');
    final tokens = await _storage.read(key: 'max_tokens');
    final lang = await _storage.read(key: 'language');

    setState(() {
      _keyController.text = key ?? '';
      _promptController.text = (prompt != null && prompt.isNotEmpty) ? prompt : _defaultPrompt;
      _speechRate = double.tryParse(rate ?? '0.7') ?? 0.7;
      _maxTokens = int.tryParse(tokens ?? '256') ?? 256;
      _language = lang ?? 'en';
    });
  }

  Future<void> _saveSettings() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    await _storage.write(key: 'anthropic_api_key', value: key);
    await _storage.write(key: 'system_prompt', value: _promptController.text.trim());
    await _storage.write(key: 'speech_rate', value: _speechRate.toString());
    await _storage.write(key: 'max_tokens', value: _maxTokens.toString());
    await _storage.write(key: 'language', value: _language);

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Postavke',
          style: TextStyle(color: Colors.white, letterSpacing: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- API KEY ---
            _sectionLabel('ANTHROPIC API KEY'),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.indigo.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.withOpacity(0.4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.withOpacity(0.4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.indigo)),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            // --- JEZIK ---
            _sectionLabel('JEZIK ODGOVORA'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _language,
                  dropdownColor: const Color(0xFF1a1a2e),
                  isExpanded: true,
                  items: _languages.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                  )).toList(),
                  onChanged: (v) => setState(() => _language = v ?? 'en'),
                ),
              ),
            ),

            // --- SYSTEM PROMPT ---
            _sectionLabel('SYSTEM PROMPT'),
            TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.indigo.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.withOpacity(0.4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.withOpacity(0.4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.indigo)),
              ),
            ),

            // --- SPEECH RATE ---
            _sectionLabel('BRZINA GOVORA'),
            Row(
              children: [
                const Text('Sporo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: 0.3,
                    max: 1.5,
                    divisions: 12,
                    activeColor: Colors.indigo,
                    inactiveColor: Colors.indigo.withOpacity(0.2),
                    onChanged: (v) => setState(() => _speechRate = v),
                  ),
                ),
                const Text('Brzo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 8),
                Text(_speechRate.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),

            // --- MAX TOKENS ---
            _sectionLabel('DUŽINA ODGOVORA (MAX TOKENS)'),
            Row(
              children: [
                const Text('Kratko', style: TextStyle(color: Colors.white38, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _maxTokens.toDouble(),
                    min: 64,
                    max: 1024,
                    divisions: 15,
                    activeColor: Colors.indigo,
                    inactiveColor: Colors.indigo.withOpacity(0.2),
                    onChanged: (v) => setState(() => _maxTokens = v.round()),
                  ),
                ),
                const Text('Dugo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 8),
                Text('$_maxTokens',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),

            const SizedBox(height: 32),

            // --- SAVE ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _saved ? '✓ Sačuvano' : 'Sačuvaj',
                  style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Svi podaci se čuvaju sigurno u Android Keystore i nikad ne napuštaju uređaj.',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
