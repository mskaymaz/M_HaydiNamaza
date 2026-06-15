import 'package:flutter/material.dart';

import '../../../features/shared_settings/shared_settings_remote_client.dart';
import 'shared_settings/settings_shared_about_section.dart';
import 'shared_settings/settings_shared_contact_section.dart';
import 'shared_settings/settings_shared_other_apps_section.dart';
import 'shared_settings/settings_shared_support_section.dart';
import 'shared_settings/settings_shared_update_section.dart';

class SettingsSharedSectionsList extends StatelessWidget {
  const SettingsSharedSectionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SettingsSharedContactSection(),
        SizedBox(height: 10),
        SettingsSharedUpdateSection(),
        SizedBox(height: 10),
        SettingsSharedOtherAppsSection(
          remoteClient: SharedSettingsRemoteClient(),
        ),
        SizedBox(height: 10),
        SettingsSharedSupportSection(),
        SizedBox(height: 10),
        SettingsSharedAboutSection(),
      ],
    );
  }
}
