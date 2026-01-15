String formatDuration(double hours) {
  final int totalMinutes = (hours * 60).round();
  final int h = totalMinutes ~/ 60;
  final int m = totalMinutes % 60;

  if (h > 0 && m > 0) {
    return '${h}h ${m}m';
  } else if (h > 0) {
    return '${h}h';
  } else {
    return '${m}m';
  }
}
