import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_intelligence/features/calendar/domain/attendance_calculator.dart';

void main() {
  group('AttendanceCalculator', () {
    test('calculatePercentage returns correct value', () {
      expect(AttendanceCalculator.calculatePercentage(3, 4), 75.0);
      expect(AttendanceCalculator.calculatePercentage(0, 4), 0.0);
      expect(AttendanceCalculator.calculatePercentage(4, 4), 100.0);
      expect(AttendanceCalculator.calculatePercentage(1, 2), 50.0);
    });

    test('calculatePercentage handles zero conducted classes', () {
      expect(AttendanceCalculator.calculatePercentage(0, 0), 0.0);
    });

    test('classesNeededToReachTarget returns correct recovery classes', () {
      // 3/5 = 60%. Target 75%.
      // Need (0.75 * conducted - present) / (1 - 0.75)
      // (0.75 * 5 - 3) / 0.25 = (3.75 - 3) / 0.25 = 0.75 / 0.25 = 3
      // Check: 3+3 present / 5+3 conducted = 6/8 = 75%. Correct.
      expect(
        AttendanceCalculator.calculateClassesNeededToReachTarget(3, 5, 75),
        3,
      );

      // 24/100 = 24%. Target 75%.
      // (75 - 24) / 0.25 = 51 / 0.25 = 204.
      // 24+204 / 100+204 = 228 / 304 = 0.75. Correct.
      expect(
        AttendanceCalculator.calculateClassesNeededToReachTarget(24, 100, 75),
        204,
      );
    });

    test('classesNeeded returns 0 if already above target', () {
      expect(
        AttendanceCalculator.calculateClassesNeededToReachTarget(4, 5, 75),
        0,
      );
    });

    test('maxSkippable returns correct value', () {
      // 4/5 = 80%. Target 75%.
      // (4 - 0.75 * 5) / 0.75 = (4 - 3.75) / 0.75 = 0.25 / 0.75 = 0.33 -> floor 0.
      expect(AttendanceCalculator.calculateMaxSkippableClasses(4, 5, 75), 0);

      // 8/10 = 80%. Target 75%.
      // (8 - 7.5) / 0.75 = 0.5 / 0.75 = 0.66 -> floor 0.
      expect(AttendanceCalculator.calculateMaxSkippableClasses(8, 10, 75), 0);

      // 9/10 = 90%. Target 75%.
      // (9 - 7.5) / 0.75 = 1.5 / 0.75 = 2.
      // Skip 1: 9/11 = 81.8%
      // Skip 2: 9/12 = 75%
      // Skip 3: 9/13 = 69.2%
      expect(AttendanceCalculator.calculateMaxSkippableClasses(9, 10, 75), 2);
    });

    test('predictAttendanceIfSkipped returns correct prediction', () {
      // 3/4 = 75%.
      // Skip next: 3/5 = 60%.
      expect(AttendanceCalculator.predictAttendanceIfSkipped(3, 4), 60.0);
    });
  });
}
