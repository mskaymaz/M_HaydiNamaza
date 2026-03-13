class TimeComponents {
  final int hours;
  final int minutes;
  final int seconds;

  TimeComponents(double num)
      : hours = num.floor(),
        minutes = ((num - num.floor()) * 60).floor(),
        seconds = ((num - (num.floor() + (((num - num.floor()) * 60).floor() / 60))) * 3600).floor();

  DateTime utcDate(int year, int month, int day) {
    return DateTime.utc(year, month, day, hours, minutes, seconds);
  }
}
