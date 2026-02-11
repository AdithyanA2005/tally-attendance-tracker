import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/day_note_model.dart';
import '../../data/repositories/day_note_repository.dart';

final dayNoteProvider = StreamProvider.family<DayNote?, DateTime>((ref, date) {
  final repository = ref.watch(dayNoteRepositoryProvider);
  return repository.watchNote(date);
});
