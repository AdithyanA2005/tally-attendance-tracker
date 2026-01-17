import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/subject_model.dart';

class AttendanceAnomaly {
  final Subject subject;
  final DateTime date;
  final List<ClassSession> presentClasses;
  final List<ClassSession> absentClasses;
  final int totalClasses;
  final int presentCount;
  final double currentPercentage;
  final double potentialPercentage;
  final double impactPercentage;

  AttendanceAnomaly({
    required this.subject,
    required this.date,
    required this.presentClasses,
    required this.absentClasses,
    required this.totalClasses,
    required this.presentCount,
    required this.currentPercentage,
    required this.potentialPercentage,
    required this.impactPercentage,
  });

  int get anomalyCount => absentClasses.length;

  int get contextClassesCount => presentClasses.length;

  // Confidence level based on how many other classes were present
  String get confidenceLevel {
    if (contextClassesCount >= 3) return 'High';
    if (contextClassesCount >= 2) return 'Medium';
    return 'Low';
  }
}

class SubjectAnomalySummary {
  final Subject subject;
  final List<AttendanceAnomaly> anomalies;
  final double currentPercentage;
  final double potentialPercentage;
  final double impactPercentage;
  final int totalAnomalies;

  SubjectAnomalySummary({
    required this.subject,
    required this.anomalies,
    required this.currentPercentage,
    required this.potentialPercentage,
    required this.impactPercentage,
    required this.totalAnomalies,
  });
}
