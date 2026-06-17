import 'package:flutter/widgets.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/reminder_text_settings_storage.dart';
import 'settings_audio_mode_texts.dart';

String methodSubtitleForCode(String? methodCode, AppLocalizations l10n) {
  switch (methodCode) {
    case 'aladhan':
      return l10n.methodAladhan;
    case 'turkey':
      return l10n.methodTurkey;
    case 'diyanet':
    case 'diyanet_tabanli':
      return 'Diyanet';
    case 'umm_al_qura':
      return l10n.methodUmmAlQura;
    case 'muslim_world_league':
      return l10n.methodMuslimWorldLeague;
    case 'moonsighting':
      return l10n.methodMoonsighting;
    case 'north_america':
      return l10n.methodNorthAmerica;
    default:
      return l10n.methodNotSet;
  }
}

String codeForLocale(Locale? locale) => locale?.languageCode ?? 'system';

Locale? localeForCode(String code) {
  switch (code) {
    case 'tr':
      return const Locale('tr');
    case 'en':
      return const Locale('en');
    case 'ar':
      return const Locale('ar');
    case 'system':
    default:
      return null;
  }
}

String audioInfoTextForSelection({
  required String? selectedAudioLabel,
  required ReminderAudioMode selectedAudioMode,
}) {
  if (selectedAudioLabel?.trim().isNotEmpty == true) {
    return 'Seçilen dosya: $selectedAudioLabel';
  }
  return audioPickerHelpText(selectedAudioMode);
}
