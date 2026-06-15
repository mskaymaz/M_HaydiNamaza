import 'package:flutter/material.dart';

import '../../app/reminder_audio_service.dart';
import '../../app/reminder_text_settings_storage.dart';

class VoiceTestScreen extends StatefulWidget {
  final List<DropdownMenuItem<String?>> voiceItems;

  const VoiceTestScreen({super.key, this.voiceItems = const []});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final ReminderAudioService _audioService = ReminderAudioService();
  final TextEditingController _arabicController = TextEditingController(
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  );
  final TextEditingController _englishController = TextEditingController(
    text: 'This is a short test sentence for English voice detection.',
  );

  List<DropdownMenuItem<String?>> _englishVoiceItems = const [];
  List<DropdownMenuItem<String?>> _arabicVoiceItems = const [];
  String? _selectedEnglishKey;
  String? _selectedArabicKey;
  bool _loadingVoices = true;

  @override
  void initState() {
    super.initState();
    _loadVoiceOptions();
  }

  @override
  void dispose() {
    _arabicController.dispose();
    _englishController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceOptions() async {
    final storage = ReminderTextSettingsStorage();
    final current = await storage.read();
    final englishVoices = await _audioService.loadVoiceOptions(
      languageCode: 'en',
    );
    final arabicVoices = await _audioService.loadVoiceOptions(
      languageCode: 'ar',
    );
    if (!mounted) return;

    final englishItems = _buildVoiceItems(englishVoices);
    final arabicItems = _buildVoiceItems(arabicVoices);
    final storedEnglishKey = _voiceKey(
      current.selectedEnglishVoiceLocale,
      current.selectedEnglishVoiceName,
    );
    final storedArabicKey = _voiceKey(
      current.selectedArabicVoiceLocale,
      current.selectedArabicVoiceName,
    );

    setState(() {
      _englishVoiceItems = englishItems;
      _arabicVoiceItems = arabicItems;
      _selectedEnglishKey = _containsKey(englishItems, storedEnglishKey)
          ? storedEnglishKey
          : null;
      _selectedArabicKey = _containsKey(arabicItems, storedArabicKey)
          ? storedArabicKey
          : null;
      _loadingVoices = false;
    });
  }

  List<DropdownMenuItem<String?>> _buildVoiceItems(
    List<ReminderVoiceOption> voices,
  ) {
    return voices
        .map(
          (voice) => DropdownMenuItem<String?>(
            value: voice.key,
            child: Text(voice.label),
          ),
        )
        .toList(growable: false);
  }

  bool _containsKey(List<DropdownMenuItem<String?>> items, String? key) {
    return key != null && items.any((item) => item.value == key);
  }

  String? _voiceKey(String? locale, String? name) {
    if (locale == null || name == null) return null;
    return '$locale|$name';
  }

  _SelectedVoice _voiceFromKey(String? key) {
    final parts = key?.split('|');
    if (parts == null || parts.length < 2) return const _SelectedVoice();
    return _SelectedVoice(locale: parts[0], name: parts[1]);
  }

  Future<void> _saveDefaults() async {
    final english = _voiceFromKey(_selectedEnglishKey);
    final arabic = _voiceFromKey(_selectedArabicKey);
    await _audioService.saveSelectedLanguageVoices(
      englishVoiceName: english.name,
      englishVoiceLocale: english.locale,
      arabicVoiceName: arabic.name,
      arabicVoiceLocale: arabic.locale,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ses tercihleri kaydedildi.')));
  }

  Future<void> _playArabic() async {
    final voice = _voiceFromKey(_selectedArabicKey);
    await _audioService.speakTextWithVoice(
      text: _arabicController.text,
      voiceName: voice.name,
      voiceLocale: voice.locale,
      selectedLocale: voice.locale == null ? const Locale('ar') : null,
    );
  }

  Future<void> _playEnglish() async {
    final voice = _voiceFromKey(_selectedEnglishKey);
    await _audioService.speakTextWithVoice(
      text: _englishController.text,
      voiceName: voice.name,
      voiceLocale: voice.locale,
      selectedLocale: voice.locale == null ? const Locale('en') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ses Tespit Paneli')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('İngilizce erkek ses seçimi:'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: _selectedEnglishKey,
                items: _englishVoiceItems,
                onChanged: _loadingVoices
                    ? null
                    : (v) => setState(() => _selectedEnglishKey = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _englishController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Test edilecek İngilizce metin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _playEnglish,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('İngilizce oku'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loadingVoices ? null : _saveDefaults,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Varsayılan olarak kaydet'),
              ),
              const Divider(height: 24),
              const Text('Arapça erkek ses seçimi:'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: _selectedArabicKey,
                items: _arabicVoiceItems,
                onChanged: _loadingVoices
                    ? null
                    : (v) => setState(() => _selectedArabicKey = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _arabicController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Test edilecek Arapça metin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _playArabic,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Arapça oku'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loadingVoices ? null : _saveDefaults,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Varsayılan olarak kaydet'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bu listelerde yalnızca dili uygun ve erkek olduğu güvenle tespit edilen sesler gösterilir. Uygun erkek ses yoksa okuma yapılmaz.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedVoice {
  final String? locale;
  final String? name;

  const _SelectedVoice({this.locale, this.name});
}
