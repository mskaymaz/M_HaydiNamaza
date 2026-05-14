class DailyContentPaths {
  static const String approvedRoot = 'assets/data/daily_content/approved/';
  static const String approvedAyahsSample =
      '${approvedRoot}ayahs.v1.approved.json';
  static const String approvedHadithsSample =
      '${approvedRoot}hadiths.v1.approved.json';

  static const String remoteBaseUrl =
      'https://raw.githubusercontent.com/mskaymaz/AllApp/main/data/daily_content/v1';
  static const Duration remoteRequestTimeout = Duration(seconds: 6);
}
