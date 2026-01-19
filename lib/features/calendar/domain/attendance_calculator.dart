class AttendanceCalculator {
  /// Calculate current attendance percentage (0.0 to 100.0)
  static double calculatePercentage(int present, int conducted) {
    if (conducted == 0) return 0.0;
    return (present / conducted) * 100;
  }

  /// Calculate classes needed to reach target percentage
  static int calculateClassesNeededToReachTarget(
    int present,
    int conducted,
    double targetPercentage,
  ) {
    final target = targetPercentage / 100.0;
    final current = present / conducted;

    if (conducted == 0) return 0;
    if (current >= target) return 0;

    // Formula: (present + x) / (conducted + x) >= target
    // present + x >= target * conducted + target * x
    // x * (1 - target) >= target * conducted - present
    // x >= (target * conducted - present) / (1 - target)

    final result = (target * conducted - present) / (1 - target);
    return result.ceil();
  }

  /// Calculate maximum classes that can be skipped while staying above target
  static int calculateMaxSkippableClasses(
    int present,
    int conducted,
    double targetPercentage,
  ) {
    final target = targetPercentage / 100.0;
    if (conducted == 0) return 0;

    // Formula: present / (conducted + x) >= target
    // present >= target * (conducted + x)
    // present / target >= conducted + x
    // (present / target) - conducted >= x

    final result = (present / target) - conducted;
    return result.floor() < 0 ? 0 : result.floor();
  }

  /// Predict attendance if next class is skipped
  static double predictAttendanceIfSkipped(int present, int conducted) {
    if (conducted + 1 == 0) return 0.0;
    return (present / (conducted + 1)) * 100;
  }

  /// Predict attendance if next class is attended
  static double predictAttendanceIfAttended(int present, int conducted) {
    return ((present + 1) / (conducted + 1)) * 100;
  }
}
