import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_support_bridge.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedSupportSection extends StatefulWidget {
  const SettingsSharedSupportSection({super.key});

  @override
  State<SettingsSharedSupportSection> createState() =>
      _SettingsSharedSupportSectionState();
}

class _SettingsSharedSupportSectionState
    extends State<SettingsSharedSupportSection> {
  int _openRevision = supportSectionOpenRevision.value;
  bool _expanded = false;
  late final ExpansibleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    supportSectionOpenRevision.addListener(_onSupportOpenRequest);
  }

  @override
  void dispose() {
    supportSectionOpenRevision.removeListener(_onSupportOpenRequest);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final support = kSharedSettingsAppConfig.support;
    return SharedSettingsSectionCard(
      key: ValueKey<String>('support_$_openRevision'),
      title: support.title,
      headerColor: sharedSettingsSupportHeader,
      controller: _controller,
      initiallyExpanded: _expanded,
      onExpansionChanged: (value) => setState(() => _expanded = value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              support.body,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: FilledButton.icon(
                onPressed: _onPrayerSupport,
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: const Text('Dua Ediyorum'),
              ),
            ),
            if (support.actionUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: OutlinedButton.icon(
                  onPressed: () => _openSupportUrl(),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(support.actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onSupportOpenRequest() {
    final revision = supportSectionOpenRevision.value;
    if (revision == _openRevision || !mounted) return;

    setState(() {
      _openRevision = revision;
      _expanded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.14,
        ),
      );
    });
  }

  void _onPrayerSupport() {
    _showSnack(
      'Allah (cc) razi olsun.\nDuaniz bizim icin kiymetli.',
      duration: const Duration(seconds: 5),
      background: const Color(0xFF2E7D32),
      largeText: true,
    );
    _controller.collapse();
  }

  Future<void> _openSupportUrl() async {
    final uri = Uri.tryParse(kSharedSettingsAppConfig.support.actionUrl.trim());
    if (uri == null) {
      _showSnack('Destek baglantisi acilamadi.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showSnack('Destek baglantisi acilamadi.');
    }
  }

  void _showSnack(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? background,
    bool largeText = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: background,
        content: SizedBox(
          width: double.infinity,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: largeText ? const TextStyle(fontSize: 18) : null,
          ),
        ),
      ),
    );
  }
}
