part of 'home_screen.dart';

extension _HomePrayerTableController on _HomeScreenState {
  void _loadWeeklyPrayerTable(_HomeData data) {
    _loadPresetPrayerTable(data: data, mode: _PrayerTableMode.week, days: 7);
  }

  void _loadThirtyDayPrayerTable(_HomeData data) {
    _loadPresetPrayerTable(
      data: data,
      mode: _PrayerTableMode.thirtyDays,
      days: 30,
    );
  }

  Future<void> _pickPrayerTableRange(_HomeData data) async {
    final today = DateTime(_now.year, _now.month, _now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 7)),
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 6)),
      ),
      helpText: 'Vakit aralığı seç',
      cancelText: 'Vazgeç',
      confirmText: 'Getir',
      saveText: 'Getir',
    );
    if (picked == null || !mounted) return;
    final dayCount = picked.end.difference(picked.start).inDays + 1;
    if (dayCount > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aralık en fazla 31 gün olabilir.')),
      );
      return;
    }
    _setHomeState(() {
      _prayerTableMode = _PrayerTableMode.range;
      _prayerTableRange = picked;
      _prayerTableFuture = _loadPrayerTableDays(
        data: data,
        start: picked.start,
        end: picked.end,
      );
    });
  }

  void _loadPresetPrayerTable({
    required _HomeData data,
    required _PrayerTableMode mode,
    required int days,
  }) {
    final today = DateTime(_now.year, _now.month, _now.day);
    _setHomeState(() {
      _prayerTableMode = mode;
      _prayerTableRange = DateTimeRange(
        start: today,
        end: today.add(Duration(days: days - 1)),
      );
      _prayerTableFuture = _loadPrayerTableDays(
        data: data,
        start: today,
        end: today.add(Duration(days: days - 1)),
      );
    });
  }

  Future<List<_PrayerTableDay>> _loadPrayerTableDays({
    required _HomeData data,
    required DateTime start,
    required DateTime end,
  }) async {
    final location = data.location;
    final methodCode = data.methodCode ?? CalculationMethodStorage.defaultCode;
    if (location == null) return const [];
    final lat = double.tryParse(location.latitude) ?? 0;
    final lon = double.tryParse(location.longitude) ?? 0;
    final today = DateTime(_now.year, _now.month, _now.day);
    final rows = <_PrayerTableDay>[];
    final totalDays = end.difference(start).inDays + 1;
    for (var index = 0; index < totalDays; index += 1) {
      final date = DateTime(start.year, start.month, start.day + index);
      final offset = DateTime(date.year, date.month, date.day)
          .difference(today)
          .inDays;
      final cached = _prayerDayCache[offset];
      if (cached != null) {
        rows.add(_PrayerTableDay(date: date, times: cached));
        continue;
      }
      final times = offset == 0 && data.times != null
          ? data.times!
          : await _prayerService.calculateForDate(
              location: location,
              latitude: lat,
              longitude: lon,
              timeZone: location.timeZoneOffset,
              methodCode: methodCode,
              date: date,
              allowDiyanet: true,
              allowRemote: true,
            );
      _prayerDayCache[offset] = times;
      rows.add(_PrayerTableDay(date: date, times: times));
    }
    return rows;
  }
}
