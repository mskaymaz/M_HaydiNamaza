import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/reminder_audio_service.dart';
import '../../app/reminder_text_settings_storage.dart';

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
    final v = widget.arabicVoices[idx];
    final name = (v.name ?? v['name']).toString();
    final locale = (v.locale ?? v['locale']).toString();
    setState(() {
      _current = idx;
      _isPlaying = true;
    });
    try {
      await widget.reminderAudioService.speakTextWithVoice(
        text: widget.sampleText,
        voiceName: name,
        voiceLocale: locale,
        selectedLocale: const Locale('ar'),
      );
    } catch (_) {}
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
    final v = widget.arabicVoices[_current];
    final name = (v.name ?? v['name']).toString();
    final locale = (v.locale ?? v['locale']).toString();
    try {
      final storage = ReminderTextSettingsStorage();
      await storage.writeSelectedLanguageVoices(
        arabicVoiceName: name,
        arabicVoiceLocale: locale,
      );
      await widget.reminderAudioService.saveSelectedLanguageVoices(
        arabicVoiceLocale: locale,
        arabicVoiceName: name,
      );
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
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
                  final v = widget.arabicVoices[index];
                  final label = (v.label ?? '${v['name']} (${v['locale']})').toString();
                  return ListTile(
                    title: Text(label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_current == index && _isPlaying) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat')),
      ],
    );
  }
}
