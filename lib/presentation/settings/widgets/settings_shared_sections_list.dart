import 'package:flutter/material.dart';

import '../../../features/shared_settings/shared_settings_remote_client.dart';
import 'shared_settings/settings_shared_about_section.dart';
import 'shared_settings/settings_shared_other_apps_section.dart';
import 'shared_settings/settings_shared_support_section.dart';
import 'shared_settings/settings_shared_update_section.dart';

class SettingsSharedSectionsList extends StatelessWidget {
  final bool showHelpBalloons;

  const SettingsSharedSectionsList({
    super.key,
    required this.showHelpBalloons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSharedAboutSection(showHelpBalloons: showHelpBalloons),
        SizedBox(height: 20),
        SettingsSharedUpdateSection(showHelpBalloons: showHelpBalloons),
        SizedBox(height: 20),
        SettingsSharedOtherAppsSection(
          remoteClient: const SharedSettingsRemoteClient(),
          showHelpBalloons: showHelpBalloons,
        ),
        SizedBox(height: 20),
        SettingsSharedSupportSection(showHelpBalloons: showHelpBalloons),
      ],
    );
  }
}
