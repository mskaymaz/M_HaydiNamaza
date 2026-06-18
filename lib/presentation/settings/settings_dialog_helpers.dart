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
  String? hexError;
  final hexController = TextEditingController(text: hexColor(initialColor));

  try {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final dialogTitle = _colorDialogTitle(title);
            final canApply = hexError == null;
            return AlertDialog(
              title: Text(dialogTitle),
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
                                  hexController.text = hexColor(draft.toColor());
                                  hexError = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          HueStrip(
                            hue: draft.hue,
                            onChanged: (hue) {
                              setState(() {
                                draft = draft.withHue(hue);
                                hexController.text = hexColor(draft.toColor());
                                hexError = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: 132,
                  child: TextField(
                    controller: hexController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'HEX',
                      hintText: '#2E7D32',
                      errorText: hexError,
                    ),
                    onChanged: (value) {
                      final parsed = _tryParseHexColor(value);
                      setState(() {
                        if (parsed == null) {
                          hexError = 'Geçersiz HEX';
                          return;
                        }
                        draft = HSVColor.fromColor(parsed);
                        hexError = null;
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'İptal',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                IconButton.filled(
                  tooltip: 'Uygula',
                  onPressed: canApply
                      ? () async {
                          final parsed = _tryParseHexColor(hexController.text);
                          if (parsed == null) {
                            setState(() => hexError = 'Geçersiz HEX');
                            return;
                          }
                          await onApply(parsed);
                          onApplied();
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    hexController.dispose();
  }
}

String _colorDialogTitle(String title) {
  final trimmed = title.trim();
  return trimmed.endsWith('Rengi') ? trimmed : '$trimmed Rengi';
}

Color? _tryParseHexColor(String input) {
  final normalized = input.trim().replaceFirst('#', '').toUpperCase();
  if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized)) return null;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
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
