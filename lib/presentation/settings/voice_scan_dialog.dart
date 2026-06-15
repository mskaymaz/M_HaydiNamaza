import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/reminder_audio_service.dart';

class VoiceScanDialog extends StatefulWidget {
  final ReminderAudioService reminderAudioService;
  final List<dynamic> arabicVoices; // ReminderVoiceOption
  final String sampleText;

  const VoiceScanDialog({
    super.key,
    required this.reminderAudioService,
    required this.arabicVoices,
    required this.sampleText,
  });

  @override
  State<VoiceScanDialog> createState() => _VoiceScanDialogState();
}

class _VoiceScanDialogState extends State<VoiceScanDialog> {
  int _current = -1;
  Timer? _autoTimer;
  bool _isPlaying = false;

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _playIndex(int idx) async {
    final voice = _voiceAt(idx);
    setState(() {
      _current = idx;
      _isPlaying = true;
    });
    try {
      await widget.reminderAudioService.speakTextWithVoice(
        text: widget.sampleText,
        voiceName: voice.name,
        voiceLocale: voice.locale,
        selectedLocale: const Locale('ar'),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
    });
  }

  void _startAutoScan() {
    _autoTimer?.cancel();
    var idx = 0;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      if (idx >= widget.arabicVoices.length) {
        _autoTimer?.cancel();
        return;
      }
      await _playIndex(idx);
      idx += 1;
    });
  }

  Future<void> _selectCurrent() async {
    if (_current < 0) return;
    final voice = _voiceAt(_current);
    try {
      await widget.reminderAudioService.saveSelectedLanguageVoices(
        arabicVoiceLocale: voice.locale,
        arabicVoiceName: voice.name,
      );
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  _ScannedVoice _voiceAt(int index) {
    final raw = widget.arabicVoices[index];
    if (raw is ReminderVoiceOption) {
      return _ScannedVoice(
        name: raw.name,
        locale: raw.locale,
        label: raw.label,
      );
    }
    if (raw is Map) {
      final name = (raw['name'] ?? '').toString();
      final locale = (raw['locale'] ?? '').toString();
      final label = (raw['label'] ?? '$name ($locale)').toString();
      return _ScannedVoice(name: name, locale: locale, label: label);
    }
    final label = raw.toString();
    return _ScannedVoice(name: label, locale: '', label: label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Arapça Ses Tespiti'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _startAutoScan,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Otomatik Tara'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.arabicVoices.length,
                itemBuilder: (context, index) {
                  final voice = _voiceAt(index);
                  return ListTile(
                    title: Text(voice.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_current == index && _isPlaying)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow_rounded),
                          onPressed: () => _playIndex(index),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _current = index);
                            _selectCurrent();
                          },
                          child: const Text('Seç'),
                        ),
                      ],
                    ),
                    selected: _current == index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

class _ScannedVoice {
  final String name;
  final String locale;
  final String label;

  const _ScannedVoice({
    required this.name,
    required this.locale,
    required this.label,
  });
}
