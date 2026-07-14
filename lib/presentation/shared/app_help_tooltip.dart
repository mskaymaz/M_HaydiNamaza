import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppHelpTooltip extends StatelessWidget {
  final bool visible;
  final String title;
  final String message;
  final double iconSize;
  final double tapSize;
  final Color? color;
  final Widget Function(BuildContext context)? inlineIconBuilder;

  const AppHelpTooltip({
    super.key,
    required this.visible,
    required this.title,
    required this.message,
    this.iconSize = 20,
    this.tapSize = 34,
    this.color,
    this.inlineIconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || message.trim().isEmpty) return const SizedBox.shrink();
    final effectiveIconSize = iconSize * 1.275;
    final effectiveTapSize = math.max(tapSize, effectiveIconSize + 10);
    final helpColor = _resolveHelpColor(context);
    return SizedBox(
      width: effectiveTapSize,
      height: effectiveTapSize,
      child: IconButton(
        tooltip: 'Yardım',
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tight(Size.square(effectiveTapSize)),
        icon: Icon(
          Icons.help_outline_rounded,
          size: effectiveIconSize,
          color: helpColor,
        ),
        onPressed: () => _showHelpDialog(context),
      ),
    );
  }

  Color _resolveHelpColor(BuildContext context) {
    final materialColor = context
        .findAncestorWidgetOfExactType<Material>()
        ?.color;
    final Color surfaceColor;
    if (materialColor != null && ((materialColor.a * 255.0).round().clamp(0, 255)) > 20) {
      surfaceColor = materialColor;
    } else {
      surfaceColor = Theme.of(context).cardColor;
    }
    final brightness = ThemeData.estimateBrightnessForColor(surfaceColor);
    if (brightness == Brightness.dark) {
      return const Color(0xFFFFF176);
    }
    return const Color(0xFFFF8F00);
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: _HelpMessage(
            message: message,
            inlineIconBuilder: inlineIconBuilder,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

class _HelpMessage extends StatelessWidget {
  final String message;
  final Widget Function(BuildContext context)? inlineIconBuilder;

  const _HelpMessage({
    required this.message,
    this.inlineIconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs = message.split('\n\n');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < paragraphs.length; index++) ...[
          if (index > 0) const SizedBox(height: 3),
          _buildParagraph(context, paragraphs[index]),
        ],
      ],
    );
  }

  Widget _buildParagraph(BuildContext context, String paragraph) {
    const marker = '[[inline_icon]]';
    if (inlineIconBuilder == null || !paragraph.contains(marker)) {
      return Text(paragraph);
    }
    final parts = paragraph.split(marker);
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < parts.length; index++) ...[
            if (parts[index].isNotEmpty) TextSpan(text: parts[index]),
            if (index < parts.length - 1)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: inlineIconBuilder!(context),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

