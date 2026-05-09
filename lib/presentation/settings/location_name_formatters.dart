String formatLocationDisplayName(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed
      .replaceAll('I', String.fromCharCode(0x0131))
      .replaceAll(String.fromCharCode(0x0130), 'i')
      .toLowerCase();
  final parts = lower.split(RegExp(r'(\s+|/|-)'));
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part.isEmpty) continue;
    final isSeparator = RegExp(r'^\s+$|^/$|^-$').hasMatch(part);
    if (isSeparator) {
      buffer.write(part);
      continue;
    }
    buffer.write(capitalizeTurkishFirst(part[0]));
    if (part.length > 1) {
      buffer.write(part.substring(1));
    }
  }
  return buffer.toString();
}

String capitalizeTurkishFirst(String input) {
  if (input == 'i') return String.fromCharCode(0x0130);
  if (input == String.fromCharCode(0x0131)) return 'I';
  return input.toUpperCase();
}
