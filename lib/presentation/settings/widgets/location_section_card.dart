import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';

class LocationSectionCard extends StatelessWidget {
  final SurfaceStyle style;
  final EdgeInsets padding;
  final Widget child;

  const LocationSectionCard({
    super.key,
    required this.style,
    required this.padding,
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
        padding: padding,
        child: child,
      ),
    );
  }
}
