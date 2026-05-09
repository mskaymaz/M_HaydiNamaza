import 'package:flutter/material.dart';

class HomeMissingLocationPanel extends StatelessWidget {
  final String message;
  final String settingsLabel;
  final VoidCallback onOpenSettings;

  const HomeMissingLocationPanel({
    super.key,
    required this.message,
    required this.settingsLabel,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
            label: Text(settingsLabel),
          ),
        ],
      ),
    );
  }
}

class HomeInvalidLocationPanel extends StatelessWidget {
  final String message;
  final String settingsLabel;
  final VoidCallback onOpenSettings;

  const HomeInvalidLocationPanel({
    super.key,
    required this.message,
    required this.settingsLabel,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
            label: Text(settingsLabel),
          ),
        ],
      ),
    );
  }
}

class HomePrayerTimesUnavailablePanel extends StatelessWidget {
  final String message;

  const HomePrayerTimesUnavailablePanel({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
