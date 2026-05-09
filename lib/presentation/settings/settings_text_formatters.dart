String toTurkishUpper(String value) {
  return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
}
