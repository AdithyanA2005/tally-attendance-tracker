import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/day_note_model.dart';
import 'package:intl/intl.dart';

class DayNoteRepository {
  static const String boxName = 'day_notes_box';
  final Box<DayNote> _box;

  DayNoteRepository(this._box);

  static Future<DayNoteRepository> init() async {
    final box = await Hive.openBox<DayNote>(boxName);
    return DayNoteRepository(box);
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DayNote? getNote(DateTime date) {
    final key = _getDateKey(date);
    return _box.get(key);
  }

  Future<void> saveNote(DateTime date, String content) async {
    final key = _getDateKey(date);
    final note = DayNote(
      dateIso: key,
      content: content,
      updatedAt: DateTime.now(),
      hasPendingSync: true,
    );
    await _box.put(key, note);
  }

  Future<void> deleteNote(DateTime date) async {
    // We treat delete as setting content to empty string for now, to sync deletion state.
    // Or we need a tombstone mechanic.
    // Simpler approach: DayNote content empty = "No note".
    // And on sync if content is empty, we can delete row or keep it empty.
    // Let's keep it empty for simplicity.
    await saveNote(date, '');
  }

  Future<void> deleteNoteLocally(String dateIso) async {
    await _box.delete(dateIso);
  }

  Box<DayNote> get box => _box;

  List<DayNote> getAllNotes() {
    return _box.values.toList();
  }

  DayNote? getNoteByDateKey(String key) {
    return _box.get(key);
  }

  Future<void> saveNoteInternal(DayNote note) async {
    await _box.put(note.dateIso, note);
  }

  Stream<DayNote?> watchNote(DateTime date) async* {
    final key = _getDateKey(date);
    yield _box.get(key);
    yield* _box.watch(key: key).map((event) {
      if (event.deleted) return null;
      return event.value as DayNote?;
    });
  }

  ValueListenable<Box<DayNote>> listenToNotes() {
    return _box.listenable();
  }
}

final dayNoteRepositoryProvider = Provider<DayNoteRepository>((ref) {
  throw UnimplementedError(
    'dayNoteRepositoryProvider must be overridden in main',
  );
});
