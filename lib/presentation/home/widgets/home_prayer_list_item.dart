import 'package:flutter/material.dart';

import '../../../core/prayer_engine/prayer.dart';

class HomePrayerListItem {
  final String id;
  final Prayer? prayer;
  final String label;
  final DateTime? sortTime;
  final TextEditingController? labelController;
  final ValueChanged<String>? onLabelChanged;
  final VoidCallback? onLabelEditingComplete;
  final String timeLabel;
  final VoidCallback? onTimeTap;
  final TextEditingController reminderController;
  final ValueChanged<String> onReminderChanged;
  final VoidCallback onReminderTap;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;
  final VoidCallback onVoiceToggle;
  final VoidCallback onVisualToggle;
  final VoidCallback onAzanToggle;
  final VoidCallback onVibrationToggle;
  final VoidCallback? onDelete;

  HomePrayerListItem({
    required this.id,
    required this.prayer,
    required this.label,
    this.sortTime,
    this.labelController,
    this.onLabelChanged,
    this.onLabelEditingComplete,
    required this.timeLabel,
    this.onTimeTap,
    required this.reminderController,
    required this.onReminderChanged,
    required this.onReminderTap,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    required this.vibrationEnabled,
    required this.onVoiceToggle,
    required this.onVisualToggle,
    required this.onAzanToggle,
    required this.onVibrationToggle,
    this.onDelete,
  });
}
