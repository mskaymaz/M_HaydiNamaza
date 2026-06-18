import 'package:flutter/material.dart';

import '../../../shared/app_help_tooltip.dart';

const Color sharedSettingsContentSurface = Color(0xFFF4F4F4);
const Color sharedSettingsUpdateHeader = Color(0xFFE6D5F0);
const Color sharedSettingsOtherAppsHeader = Color(0xFFF2D9E8);
const Color sharedSettingsSupportHeader = Color(0xFFD6E5F5);
const Color sharedSettingsAboutHeader = Color(0xFFE8E6CF);
const Color sharedSettingsReminderOptionsHeader = Color(0xFFE9D8C5);
const Color sharedSettingsVibrationHeader = Color(0xFFDCE8F8);
const Color sharedSettingsVoiceHeader = Color(0xFFE5DBF7);
const Color sharedSettingsVisualHeader = Color(0xFFF6DEEA);
const Color sharedSettingsMergedColorsHeader = Color(0xFFD8EAD8);
const double sharedSettingsHeaderRowHeight = 35;

class SharedSettingsSectionCard extends StatelessWidget {
  final String title;
  final Color headerColor;
  final Widget child;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final ExpansibleController? controller;
  final bool showHelpBalloons;
  final String? helpMessage;

  const SharedSettingsSectionCard({
    super.key,
    required this.title,
    required this.headerColor,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.controller,
    this.showHelpBalloons = false,
    this.helpMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ListTileTheme.merge(
          dense: true,
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          child: ExpansionTile(
            controller: controller,
            dense: true,
            maintainState: true,
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.only(right: 20),
            childrenPadding: EdgeInsets.zero,
            collapsedBackgroundColor: headerColor,
            backgroundColor: headerColor,
            onExpansionChanged: onExpansionChanged,
            title: SizedBox(
              height: sharedSettingsHeaderRowHeight,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 25, right: 34),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: 2,
                    child: AppHelpTooltip(
                      visible: showHelpBalloons,
                      title: title,
                      message: helpMessage ?? '',
                      iconSize: 18,
                      tapSize: 30,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Container(
                color: sharedSettingsContentSurface,
                width: double.infinity,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
