class QiblaConstants {
  const QiblaConstants._();

  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  static const String avkatLocationModeLabel = 'Avkat/Diyanet kıble verisi';
  static const String locationModeLabel = 'Konuma göre hesaplandı';
  static const String sensorFallbackModeLabel = 'Yaklasik / sensor tabanli';
  static const String enableLocationGuidance =
      'Daha doğru kıble yönü için konum iznini açabilirsiniz.';
  static const String calibrationGuidance =
      'Pusula kalibrasyonu için telefonu 8 şeklinde yavaşça hareket ettirin.';
  static const String unstableAccuracyWarning =
      'Pusula verisi kararsiz gorunuyor. Metal yuzeylerden uzaklasip tekrar deneyin.';
  static const String noPerfectAccuracyNote =
      'Kıble yönü hesaplaması yaklaşıktır; yüzde 100 hassaslık garanti edilmez.';
}
