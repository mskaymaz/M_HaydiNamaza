import '../../app/reminder_text_settings_storage.dart';

String audioModeLabel(ReminderAudioMode mode) {
  switch (mode) {
    case ReminderAudioMode.textToSpeech:
      return 'Metni Oku';
    case ReminderAudioMode.deviceAudio:
      return 'Telefon Melodisi';
    case ReminderAudioMode.mp3File:
      return 'MP3 Dosyası';
  }
}

String audioPickerButtonLabel(ReminderAudioMode mode) {
  switch (mode) {
    case ReminderAudioMode.textToSpeech:
      return 'Ses Dosyası Seç';
    case ReminderAudioMode.deviceAudio:
      return 'Telefon Melodisi Seç';
    case ReminderAudioMode.mp3File:
      return 'MP3 Dosyası Seç';
  }
}

String audioPickerHelpText(ReminderAudioMode mode) {
  switch (mode) {
    case ReminderAudioMode.textToSpeech:
      return '';
    case ReminderAudioMode.deviceAudio:
      return 'Telefonunuzdaki ses dosyalarından bir melodi seçin.';
    case ReminderAudioMode.mp3File:
      return 'Yalnız mp3 dosyası seçilir.';
  }
}
