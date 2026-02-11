import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/day_note_model.dart';
import '../../data/repositories/day_note_repository.dart';
import 'day_note_sheet.dart';

class DayNoteCard extends ConsumerStatefulWidget {
  final DateTime date;

  const DayNoteCard({super.key, required this.date});

  @override
  ConsumerState<DayNoteCard> createState() => _DayNoteCardState();
}

class _DayNoteCardState extends ConsumerState<DayNoteCard> {
  bool _isExpanded = false;

  void _handleTap(BuildContext context, DayNote? note) {
    if (note == null || note.content.isEmpty) {
      _openEditSheet(context, note);
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  void _openEditSheet(BuildContext context, DayNote? note) {
    HapticFeedback.lightImpact();
    // Collapse when editing starts to avoid weird transitions
    // setState(() => _isExpanded = false); // Optional: keep expanded?

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => DayNoteSheet(date: widget.date, existingNote: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(dayNoteRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenToNotes(),
      builder: (context, box, _) {
        final note = repository.getNote(widget.date);
        final hasNote = note != null && note.content.isNotEmpty;

        // If content is very short, no need to expand really, but let's keep behavior consistent
        // or functionality simple.

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: InkWell(
              onTap: () => _handleTap(context, note),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasNote
                      ? Theme.of(context).colorScheme.primaryContainer
                            .withValues(alpha: 0.15) // More subtle
                      : Theme.of(context).colorScheme.surfaceContainerLow
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: hasNote
                      ? Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasNote
                              ? Icons.sticky_note_2_rounded
                              : Icons.note_add_rounded,
                          color: hasNote
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        if (!hasNote)
                          Expanded(
                            child: Text(
                              'Add a note for this day...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        if (hasNote) ...[
                          Expanded(
                            child: Text(
                              'Day Note',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          // Edit Button only visible when note exists
                          // Edit Button only visible when note exists
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openEditSheet(context, note),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasNote) ...[
                      const SizedBox(height: 12),
                      Text(
                        note.content,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        maxLines: _isExpanded ? null : 3,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (!_isExpanded && _isLongContent(note.content)) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tap to read more',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isLongContent(String content) {
    return content.length > 100 || content.split('\n').length > 3;
  }
}
