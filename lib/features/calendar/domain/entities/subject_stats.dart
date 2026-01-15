import '../../data/models/subject_model.dart';
import '../../data/models/session_model.dart';

class SubjectStats {
  final Subject subject;
  final int conducted;
  final int present;
  final int absent;
  final double percentage;
  final int classesNeededFor75;
  final int classesSkippable;
  final bool isSafe;
  final double predictionNextClass;
  final List<ClassSession> history;

  SubjectStats({
    required this.subject,
    required this.conducted,
    required this.present,
    required this.absent,
    required this.percentage,
    required this.classesNeededFor75,
    required this.classesSkippable,
    required this.isSafe,
    required this.predictionNextClass,
    required this.history,
  });
}
