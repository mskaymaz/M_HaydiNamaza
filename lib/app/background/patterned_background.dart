import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

@immutable
class BackgroundPatternDefinition {
  final String assetPath;
  final String label;
  final double baseTileSize;

  const BackgroundPatternDefinition({
    required this.assetPath,
    required this.label,
    required this.baseTileSize,
  });
}

class BackgroundPatternRegistry {
  static const List<BackgroundPatternDefinition> patterns =
      <BackgroundPatternDefinition>[
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesM01.svg',
          label: 'DesM01',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesM02.svg',
          label: 'DesM02',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesM03.svg',
          label: 'DesM03',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesM04.svg',
          label: 'DesM04',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesHL01.svg',
          label: 'DesHL01',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesH01.svg',
          label: 'DesH01',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesH02.svg',
          label: 'DesH02',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesH03.svg',
          label: 'DesH03',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesH04.svg',
          label: 'DesH04',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesC01.svg',
          label: 'DesC01',
          baseTileSize: 180,
        ),
        BackgroundPatternDefinition(
          assetPath: 'img/Desen/DesC02.svg',
          label: 'DesC02',
          baseTileSize: 180,
        ),
      ];

  static BackgroundPatternDefinition forAssetPath(String assetPath) {
    return patterns.firstWhere(
      (pattern) => pattern.assetPath == assetPath,
      orElse: () => patterns.first,
    );
  }
}

class PatternedBackground extends StatelessWidget {
  final Color backgroundColor;
  final Color patternColor;
  final String patternAssetPath;
  final double patternScale;
  final double patternOpacity;
  final Widget child;

  const PatternedBackground({
    super.key,
    required this.backgroundColor,
    required this.patternColor,
    required this.patternAssetPath,
    required this.patternScale,
    required this.patternOpacity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final pattern = BackgroundPatternRegistry.forAssetPath(patternAssetPath);
    final tileSize = math.max(64.0, pattern.baseTileSize * patternScale);
    final tint = patternColor.withValues(alpha: patternOpacity.clamp(0.0, 1.0));

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: backgroundColor),
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = math.max(
                  1,
                  (constraints.maxWidth / tileSize).ceil() + 1,
                );
                final cellExtent = constraints.maxWidth / columns;
                final rows = math.max(
                  1,
                  (constraints.maxHeight / cellExtent).ceil() + 1,
                );
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 1,
                  ),
                  itemCount: columns * rows,
                  itemBuilder: (context, index) {
                    return Center(
                      child: SizedBox.square(
                        dimension: tileSize,
                        child: SvgPicture.asset(
                          pattern.assetPath,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        child,
      ],
    );
  }
}
