abstract class DailyContentClock {
  DateTime now();

  String dayKey() {
    final current = now();
    final year = current.year.toString().padLeft(4, '0');
    final month = current.month.toString().padLeft(2, '0');
    final day = current.day.toString().padLeft(2, '0');
    // include 6-hour slot index (0..3) so the key changes every 6 hours
    final slot = (current.hour) ~/ 6;
    return '$year-$month-$day-$slot';
  }
}

class SystemDailyContentClock extends DailyContentClock {
  SystemDailyContentClock();

  @override
  DateTime now() => DateTime.now();
}
