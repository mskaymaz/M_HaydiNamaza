import 'package:flutter/material.dart';

class SettingsLanguageLocationRow extends StatelessWidget {
  final String initialLanguageCode;
  final InputDecoration languageDecoration;
  final String languageSystemLabel;
  final String languageTurkishLabel;
  final String languageEnglishLabel;
  final String languageArabicLabel;
  final Future<void> Function(String code) onLanguageChanged;
  final Future<void> Function() onOpenLocation;

  const SettingsLanguageLocationRow({
    super.key,
    required this.initialLanguageCode,
    required this.languageDecoration,
    required this.languageSystemLabel,
    required this.languageTurkishLabel,
    required this.languageEnglishLabel,
    required this.languageArabicLabel,
    required this.onLanguageChanged,
    required this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              initialValue: initialLanguageCode,
              decoration: languageDecoration,
              items: [
                DropdownMenuItem(value: 'system', child: Text(languageSystemLabel)),
                DropdownMenuItem(value: 'tr', child: Text(languageTurkishLabel)),
                DropdownMenuItem(value: 'en', child: Text(languageEnglishLabel)),
                DropdownMenuItem(value: 'ar', child: Text(languageArabicLabel)),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await onLanguageChanged(value);
              },
            ),
          ),
          const SizedBox(width: 35),
          SizedBox(
            width: 160,
            child: OutlinedButton.icon(
              onPressed: onOpenLocation,
              icon: const Icon(Icons.settings),
              label: const Text('Konum'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFE4F3E6),
                minimumSize: const Size(160, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
