import 'package:flutter/widgets.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/reminder_text_settings_storage.dart';
import 'settings_audio_mode_texts.dart';

String methodSubtitleForCode(String? methodCode, AppLocalizations l10n) {
  switch (methodCode) {
    case 'turkey':
      return 'Türkiye hesaplama yöntemi';
    case 'diyanet_tabanli':
      return 'Diyanet tabanlı (deneysel)';
    case 'aladhan':
      return l10n.methodAladhan;
    case 'muslim_world_league':
      return l10n.methodMuslimWorldLeague;
    case 'umm_al_qura':
      return l10n.methodUmmAlQura;
    case 'dubai':
      return l10n.methodDubai;
    case 'kuwait':
      return l10n.methodKuwait;
    case 'qatar':
      return l10n.methodQatar;
    case 'singapore':
      return l10n.methodSingapore;
    case 'tehran':
      return l10n.methodTehran;
    case 'moonsighting':
      return l10n.methodMoonsighting;
    case 'north_america':
      return l10n.methodNorthAmerica;
    case 'egyptian':
      return l10n.methodEgyptian;
    case 'karachi':
      return l10n.methodKarachi;
    case 'other':
      return l10n.methodOther;
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
    return 'Se\u00e7ilen dosya: ';
  }
  return audioPickerHelpText(selectedAudioMode);
}
