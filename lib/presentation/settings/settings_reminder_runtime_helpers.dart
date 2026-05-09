String effectiveVisualReminderText({
  required String visualText,
  required String voiceText,
}) {
  final trimmedVisualText = visualText.trim();
  if (trimmedVisualText.isNotEmpty) return trimmedVisualText;
  return voiceText.trim();
}

T? selectedVoiceOption<T>({
  required String? selectedVoiceKey,
  required List<T> voiceOptions,
  required String Function(T voice) keyOf,
}) {
  final key = selectedVoiceKey;
  if (key == null) return null;
  for (final voice in voiceOptions) {
    if (keyOf(voice) == key) {
      return voice;
    }
  }
  return null;
}
