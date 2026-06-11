import 'package:flutter/material.dart';

class SettingsAzanIconPreviewGrid extends StatelessWidget {
  static const double _boxSize = 22.0;
  static const double _iconSize = 18.5;

  static const List<_AzanIconCandidate> _candidates = [
    _AzanIconCandidate('mosque_sharp', Icons.mosque_sharp),
    _AzanIconCandidate('mosque_rounded', Icons.mosque_rounded),
    _AzanIconCandidate('mosque_outlined', Icons.mosque_outlined),
    _AzanIconCandidate(
      'record_voice_over_outlined',
      Icons.record_voice_over_outlined,
    ),
    _AzanIconCandidate(
      'record_voice_over_rounded',
      Icons.record_voice_over_rounded,
    ),
    _AzanIconCandidate('record_voice_over_sharp', Icons.record_voice_over_sharp),
    _AzanIconCandidate('campaign_outlined', Icons.campaign_outlined),
    _AzanIconCandidate('campaign_rounded', Icons.campaign_rounded),
    _AzanIconCandidate('settings_voice_outlined', Icons.settings_voice_outlined),
    _AzanIconCandidate('keyboard_voice_outlined', Icons.keyboard_voice_outlined),
    _AzanIconCandidate('spatial_audio_outlined', Icons.spatial_audio_outlined),
    _AzanIconCandidate('ring_volume_outlined', Icons.ring_volume_outlined),
    _AzanIconCandidate('speaker_phone_outlined', Icons.speaker_phone_outlined),
    _AzanIconCandidate('graphic_eq_outlined', Icons.graphic_eq_outlined),
  ];

  const SettingsAzanIconPreviewGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const activeName = 'mosque_sharp';
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.black87,
      fontSize: 10,
      height: 1.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ezan ikon adaylari',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final candidate in _candidates)
              _AzanIconPreviewTile(
                candidate: candidate,
                isActive: candidate.name == activeName,
                colorScheme: colorScheme,
                textStyle: textStyle,
              ),
          ],
        ),
      ],
    );
  }
}

class SettingsSummaryReminderIconPreviewGrid extends StatelessWidget {
  static const double _boxSize = 30.0;
  static const double _iconSize = 20.0;

  static const List<_ReminderIconCandidate> _candidates = [
    _ReminderIconCandidate(
      'notifications_active_outlined',
      Icons.notifications_active_outlined,
    ),
    _ReminderIconCandidate(
      'notifications_none_outlined',
      Icons.notifications_none_outlined,
    ),
    _ReminderIconCandidate('notifications_outlined', Icons.notifications_outlined),
    _ReminderIconCandidate(
      'notification_important_outlined',
      Icons.notification_important_outlined,
    ),
    _ReminderIconCandidate('add_alert_outlined', Icons.add_alert_outlined),
    _ReminderIconCandidate('alarm_outlined', Icons.alarm_outlined),
    _ReminderIconCandidate('alarm_on_outlined', Icons.alarm_on_outlined),
    _ReminderIconCandidate('access_alarm_outlined', Icons.access_alarm_outlined),
    _ReminderIconCandidate('schedule_outlined', Icons.schedule_outlined),
    _ReminderIconCandidate('watch_later_outlined', Icons.watch_later_outlined),
    _ReminderIconCandidate('event_available_outlined', Icons.event_available_outlined),
    _ReminderIconCandidate('pending_actions_outlined', Icons.pending_actions_outlined),
    _ReminderIconCandidate('more_time_outlined', Icons.more_time_outlined),
    _ReminderIconCandidate('timer_outlined', Icons.timer_outlined),
  ];

  const SettingsSummaryReminderIconPreviewGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const activeName = 'notifications_active_outlined';
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.black87,
      fontSize: 10,
      height: 1.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ana panel ikon adaylari',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final candidate in _candidates)
              _ReminderIconPreviewTile(
                candidate: candidate,
                isActive: candidate.name == activeName,
                colorScheme: colorScheme,
                textStyle: textStyle,
              ),
          ],
        ),
      ],
    );
  }
}

class _AzanIconPreviewTile extends StatelessWidget {
  final _AzanIconCandidate candidate;
  final bool isActive;
  final ColorScheme colorScheme;
  final TextStyle? textStyle;

  const _AzanIconPreviewTile({
    required this.candidate,
    required this.isActive,
    required this.colorScheme,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.14);
    final iconColor = isActive ? colorScheme.primary : Colors.black87;

    return SizedBox(
      width: 86,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.54),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: SettingsAzanIconPreviewGrid._boxSize,
                height: SettingsAzanIconPreviewGrid._boxSize,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  candidate.icon,
                  size: SettingsAzanIconPreviewGrid._iconSize,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                candidate.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderIconPreviewTile extends StatelessWidget {
  final _ReminderIconCandidate candidate;
  final bool isActive;
  final ColorScheme colorScheme;
  final TextStyle? textStyle;

  const _ReminderIconPreviewTile({
    required this.candidate,
    required this.isActive,
    required this.colorScheme,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.14);
    final iconColor = isActive ? colorScheme.primary : Colors.black87;

    return SizedBox(
      width: 94,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.54),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: SettingsSummaryReminderIconPreviewGrid._boxSize,
                height: SettingsSummaryReminderIconPreviewGrid._boxSize,
                child: Center(
                  child: Icon(
                    candidate.icon,
                    size: SettingsSummaryReminderIconPreviewGrid._iconSize,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                candidate.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AzanIconCandidate {
  final String name;
  final IconData icon;

  const _AzanIconCandidate(this.name, this.icon);
}

class _ReminderIconCandidate {
  final String name;
  final IconData icon;

  const _ReminderIconCandidate(this.name, this.icon);
}
