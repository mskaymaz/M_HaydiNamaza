import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_models.dart';
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
            Text(
              support.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 21,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            FractionallySizedBox(
              widthFactor: 0.72,
              child: FilledButton.icon(
                onPressed: () => _onSupportAction(support),
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
                label: Text(support.actionLabel),
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

  Future<void> _onSupportAction(
    SharedSettingsSupportConfig support,
  ) async {
    if (support.actionType == 'prayer') {
      _onPrayerSupport();
      return;
    }

    final uri = Uri.tryParse(support.actionUrl.trim());
    if (uri == null) {
      _showSnack('Destek bağlantısı açılamadı.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showSnack('Destek bağlantısı açılamadı.');
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
