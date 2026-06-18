import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_support_bridge.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedSupportSection extends StatefulWidget {
  final bool showHelpBalloons;

  const SettingsSharedSupportSection({
    super.key,
    required this.showHelpBalloons,
  });

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
    final textColor = const Color(0xFF161616);
    return SharedSettingsSectionCard(
      key: ValueKey<String>('support_$_openRevision'),
      title: support.title,
      showHelpBalloons: widget.showHelpBalloons,
      helpMessage:
          'Bu bölüm uygulamaya destek ve dua hatırlatma alanıdır. Dua Ediyorum düğmesi yalnızca ekrandaki teşekkür mesajını gösterir.',
      headerColor: sharedSettingsSupportHeader,
      controller: _controller,
      initiallyExpanded: _expanded,
      onExpansionChanged: (value) => setState(() => _expanded = value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                children: const [
                  TextSpan(text: 'Öncelikle '),
                  TextSpan(text: 'Direniş', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' için,\n'),
                  TextSpan(text: 'tüm '),
                  TextSpan(
                    text: 'Dünya Müslümanları',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' için\n'),
                  TextSpan(text: 've '),
                  TextSpan(text: 'bizim', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' için '),
                  TextSpan(text: 'dua edin.', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Allah (cc) hepimizden razı olsun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 38 / 2,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            FractionallySizedBox(
              widthFactor: 0.72,
              child: FilledButton.icon(
                onPressed: _onPrayerSupport,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF117A66),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.volunteer_activism_rounded, size: 22),
                label: const Text('Dua Ediyorum'),
              ),
            ),
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
      'Allah (cc) razı olsun.\nDuanız bizim için kıymetli.',
      duration: const Duration(seconds: 5),
      background: const Color(0xFF2E7D32),
      largeText: true,
    );
    _controller.collapse();
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

