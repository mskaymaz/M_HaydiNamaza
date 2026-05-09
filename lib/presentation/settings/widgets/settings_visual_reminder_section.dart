import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';

class SettingsVisualReminderSection extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final Widget header;
  final Widget visualTextField;
  final Widget visualDisplayField;
  final Widget visualReopenField;
  final VoidCallback onShowPreview;

  const SettingsVisualReminderSection({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.header,
    required this.visualTextField,
    required this.visualDisplayField,
    required this.visualReopenField,
    required this.onShowPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding,
      child: _SectionPanel(
        style: panelStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 10),
            visualTextField,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: visualDisplayField),
                const SizedBox(width: 8),
                Expanded(child: visualReopenField),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onShowPreview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Görsel Yapıyı Göster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final SurfaceStyle style;
  final Widget child;

  const _SectionPanel({
    required this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
