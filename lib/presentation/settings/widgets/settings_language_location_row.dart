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
      padding: const EdgeInsets.fromLTRB(16, 16, 15, 8),
      child: Row(
        children: [
          SizedBox(
            width: 182,
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
          const Spacer(),
          SizedBox(
            width: 142,
            child: OutlinedButton(
              onPressed: onOpenLocation,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFE4F3E6),
                minimumSize: const Size(142, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Konum Seç'),
            ),
          ),
        ],
      ),
    );
  }
}
