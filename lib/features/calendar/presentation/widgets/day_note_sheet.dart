import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/day_note_repository.dart';
import '../../data/models/day_note_model.dart';
import '../../../../core/services/sync_service.dart';

class DayNoteSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final DayNote? existingNote;

  const DayNoteSheet({super.key, required this.date, this.existingNote});

  @override
  ConsumerState<DayNoteSheet> createState() => _DayNoteSheetState();
}

class _DayNoteSheetState extends ConsumerState<DayNoteSheet> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final content = _controller.text.trim();
      if (content.isEmpty) {
        await ref.read(dayNoteRepositoryProvider).deleteNote(widget.date);
      } else {
        await ref
            .read(dayNoteRepositoryProvider)
            .saveNote(widget.date, content);
      }

      // Trigger sync to push changes immediately (fire and forget)
      if (mounted) {
        ref.read(syncServiceProvider).sync();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Note for ${DateFormat('MMMM d').format(widget.date)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write something...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
