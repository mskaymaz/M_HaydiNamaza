import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';

class SettingsCalculationMethodRow extends StatelessWidget {
  final SurfaceStyle itemPanelStyle;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  const SettingsCalculationMethodRow({
    super.key,
    required this.itemPanelStyle,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: itemPanelStyle.borderRadius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: itemPanelStyle.color,
              borderRadius: itemPanelStyle.borderRadius,
            ),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 22,
                      color: Color(0xFF2F6F4F),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(subtitle, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
