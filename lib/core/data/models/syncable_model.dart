import 'package:hive/hive.dart';

/// An interface for models that support synchronization logic.
abstract class SyncableModel extends HiveObject {
  String get id;
  bool get hasPendingSync;
  DateTime get lastUpdated;
}
