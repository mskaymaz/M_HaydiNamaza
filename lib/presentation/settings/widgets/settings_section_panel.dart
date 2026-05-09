import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';

class SettingsSectionPanel extends StatelessWidget {
  final SurfaceStyle style;
  final Widget child;

  const SettingsSectionPanel({
    super.key,
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
