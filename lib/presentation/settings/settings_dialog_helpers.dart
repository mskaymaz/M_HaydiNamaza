import 'package:flutter/material.dart';

import 'settings_color_formatters.dart';
import 'widgets/settings_color_picker_widgets.dart';

Future<void> showSettingsColorPickerDialog({
  required BuildContext context,
  required String title,
  required Color initialColor,
  required Future<void> Function(Color color) onApply,
  required VoidCallback onApplied,
}) async {
  var draft = HSVColor.fromColor(initialColor);
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('$title Rengi'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ColorPreview(color: draft.toColor()),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    child: Row(
                      children: [
                        Expanded(
                          child: ColorSpectrum(
                            hsv: draft,
                            onChanged: (saturation, value) {
                              setState(() {
                                draft = draft
                                    .withSaturation(saturation)
                                    .withValue(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        HueStrip(
                          hue: draft.hue,
                          onChanged: (hue) {
                            setState(() => draft = draft.withHue(hue));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Iptal'),
              ),
              FilledButton(
                onPressed: () async {
                  await onApply(draft.toColor());
                  onApplied();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Uygula'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ColorPreview extends StatelessWidget {
  final Color color;

  const _ColorPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: Text(
        hexColor(color),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: HSVColor.fromColor(color).value > 0.6
              ? Colors.black87
              : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
