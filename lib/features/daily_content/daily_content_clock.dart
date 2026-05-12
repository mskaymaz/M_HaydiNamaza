abstract class DailyContentClock {
  DateTime now();

  String dayKey() {
    final current = now();
    final year = current.year.toString().padLeft(4, '0');
    final month = current.month.toString().padLeft(2, '0');
    final day = current.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class SystemDailyContentClock implements DailyContentClock {
  const SystemDailyContentClock();

  @override
  DateTime now() => DateTime.now();
}

