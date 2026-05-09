import '../../app/reminder_text_settings_storage.dart';

String audioModeLabel(ReminderAudioMode mode) {
  switch (mode) {
    case ReminderAudioMode.textToSpeech:
      return 'Metni Oku';
    case ReminderAudioMode.deviceAudio:
      return 'Telefon Melodisi';
    case ReminderAudioMode.mp3File:
      return 'MP3 Dosyasi';
  }
}

String audioPickerButtonLabel(ReminderAudioMode mode) {
  switch (mode) {
    case ReminderAudioMode.textToSpeech:
      return 'Ses Dosyasi Sec';
    case ReminderAudioMode.deviceAudio:
      return 'Telefon Melodisi Sec';
    case ReminderAudioMode.mp3File:
      return 'MP3 Dosyasi Sec';
  }
}

String audioPickerHelpText(ReminderAudioMode mode) {
  switch (mode) {
    case ReminderAudioMode.textToSpeech:
      return '';
    case ReminderAudioMode.deviceAudio:
      return 'Telefonunuzdaki ses dosyalarindan bir melodi secin.';
    case ReminderAudioMode.mp3File:
      return 'Yalniz mp3 dosyasi secilir.';
  }
}
