import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/day_note_model.dart';

class DayNoteRepository {
  static const String boxName = 'day_notes_box';
  final Box<DayNote> _box;
  final SupabaseClient? _supabase;

  DayNoteRepository(this._box, [this._supabase]);

  static Future<DayNoteRepository> init([SupabaseClient? supabase]) async {
    final box = await Hive.openBox<DayNote>(boxName);
    return DayNoteRepository(box, supabase);
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

    // 1. Local save
    await _box.put(key, note);

    // 2. Proactive sync if supabase is available
    if (_supabase != null && _supabase.auth.currentUser != null) {
      try {
        final json = note.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase
            .from('day_notes')
            .upsert(json, onConflict: 'user_id, date_iso');

        await _box.put(key, note.copyWith(hasPendingSync: false));
      } catch (e) {
        debugPrint('Proactive day note sync failed: $e');
      }
    }
  }

  Future<void> deleteNote(DateTime date) async {
    // Treat empty as delete for sync compatibility
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
  // Try to get from ref if possible, otherwise throw (it should be overridden in main)
  return ref.watch(dayNoteRepositoryInternalProvider);
});

final dayNoteRepositoryInternalProvider = Provider<DayNoteRepository>((ref) {
  throw UnimplementedError(
    'dayNoteRepositoryInternalProvider must be overridden in main',
  );
});
