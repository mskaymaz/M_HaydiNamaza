import 'package:flutter/material.dart';
import '../../app/reminder_audio_service.dart';
import '../../app/reminder_text_settings_storage.dart';

class VoiceTestScreen extends StatefulWidget {
  final List<DropdownMenuItem<String?>> voiceItems;

  const VoiceTestScreen({super.key, required this.voiceItems});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final ReminderAudioService _audioService = ReminderAudioService();
  String? _selectedEnglishKey;
  String? _selectedArabicKey;
  final TextEditingController _arabicController = TextEditingController(
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
  final TextEditingController _englishController = TextEditingController(
      text: 'This is a short test sentence for English voice detection.');

  @override
  void dispose() {
    _arabicController.dispose();
    _englishController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _saveDefaults() async {
    final storage = ReminderTextSettingsStorage();
    final current = await storage.read();
    final partsEn = _selectedEnglishKey?.split('|');
    final enLocale = partsEn != null && partsEn.length >= 2 ? partsEn[0] : null;
    final enName = partsEn != null && partsEn.length >= 2 ? partsEn[1] : null;
    final partsAr = _selectedArabicKey?.split('|');
    final arLocale = partsAr != null && partsAr.length >= 2 ? partsAr[0] : null;
    final arName = partsAr != null && partsAr.length >= 2 ? partsAr[1] : null;
    final updated = ReminderTextSettings(
      voiceText: current.voiceText,
      visualText: current.visualText,
      audioMode: current.audioMode,
      showVoiceIcon: current.showVoiceIcon,
      showVisualIcon: current.showVisualIcon,
      showAzanIcon: current.showAzanIcon,
      showVibrationIcon: current.showVibrationIcon,
      sortCustomPrayersByTime: current.sortCustomPrayersByTime,
      voiceRepeatSeconds: current.voiceRepeatSeconds,
      vibrationDurationSeconds: current.vibrationDurationSeconds,
      vibrationPauseSeconds: current.vibrationPauseSeconds,
      visualDisplaySeconds: current.visualDisplaySeconds,
      visualReopenSeconds: current.visualReopenSeconds,
      selectedVoiceName: current.selectedVoiceName,
      selectedVoiceLocale: current.selectedVoiceLocale,
      selectedEnglishVoiceName: enName,
      selectedEnglishVoiceLocale: enLocale,
      selectedArabicVoiceName: arName,
      selectedArabicVoiceLocale: arLocale,
      selectedAudioPath: current.selectedAudioPath,
      selectedAudioLabel: current.selectedAudioLabel,
    );
    await storage.write(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ses tercihleri kaydedildi.')),
    );
  }

  Future<void> _playArabic() async {
    final parts = _selectedArabicKey?.split('|');
    final voiceLocale = parts != null && parts.length >= 2 ? parts[0] : null;
    final voiceName = parts != null && parts.length >= 2 ? parts[1] : null;
    await _audioService.speakTextWithVoice(
      text: _arabicController.text,
      voiceName: voiceName,
      voiceLocale: voiceLocale,
      selectedLocale: voiceLocale == null ? const Locale('ar') : null,
    );
  }

  Future<void> _playEnglish() async {
    final parts = _selectedEnglishKey?.split('|');
    final voiceLocale = parts != null && parts.length >= 2 ? parts[0] : null;
    final voiceName = parts != null && parts.length >= 2 ? parts[1] : null;
    await _audioService.speakTextWithVoice(
      text: _englishController.text,
      voiceName: voiceName,
      voiceLocale: voiceLocale,
      selectedLocale: voiceLocale == null ? const Locale('en') : null,
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
              const Text('English voice (choose then press Play):'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: _selectedEnglishKey,
                items: widget.voiceItems,
                onChanged: (v) => setState(() => _selectedEnglishKey = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _englishController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'English text to test',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _playEnglish,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Play English'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saveDefaults,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save as default'),
              ),
              const Divider(height: 24),
              const Text('Arabic voice (choose then press Play):'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: _selectedArabicKey,
                items: widget.voiceItems,
                onChanged: (v) => setState(() => _selectedArabicKey = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _arabicController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Arabic text to test',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _playArabic,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Play Arabic'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saveDefaults,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save as default'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kullanım: Cihazdan farklı sesler dene. Eğer Arapça harf harf okunuyorsa, farklı "Arabic Voice" seçin veya cihazdan bölgesel Arapça ses verisini yükleyin.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
