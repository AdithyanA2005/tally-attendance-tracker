import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/session_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/repositories/attendance_repository.dart';

class EditSessionSheet extends ConsumerStatefulWidget {
  final ClassSession session;
  final Subject? initialSubject;
  final List<Subject> allSubjects;
  final bool isNew;

  const EditSessionSheet({
    super.key,
    required this.session,
    this.initialSubject,
    required this.allSubjects,
    this.isNew = false,
  });

  @override
  ConsumerState<EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<EditSessionSheet> {
  Subject? _selectedSubject;
  late AttendanceStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
    _selectedStatus = widget.session.status == AttendanceStatus.unmarked
        ? AttendanceStatus.present
        : widget.session.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (widget.isNew && widget.session.isExtraClass)
                    ? 'New Class'
                    : 'Edit Class',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subject Dropdown or Empty State
          if (widget.allSubjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.subject_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Subjects Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add subjects first to track attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Assuming context.push is available via a navigation package like go_router
                      // If not, this line might cause an error or need a different navigation method.
                      // For example, using Navigator.push(context, MaterialPageRoute(builder: (context) => ManageSubjectsScreen()));
                      context.push('/manage_subjects');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Subjects'),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<Subject>(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(16),
              decoration: InputDecoration(
                labelText: 'Subject',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              initialValue: _selectedSubject,
              items: widget.allSubjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubject = val);
              },
            ),
          const SizedBox(height: 16),

          // Status Dropdown
          DropdownButtonFormField<AttendanceStatus>(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            borderRadius: BorderRadius.circular(16),
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            initialValue: _selectedStatus,
            items: AttendanceStatus.values
                .where((s) => s != AttendanceStatus.unmarked)
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              // Only show Reset button for existing sessions
              if (!widget.isNew) ...[
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      // Reset logic: Delete specific override for this date
                      await ref
                          .read(attendanceRepositoryProvider)
                          .deleteDuplicateSessions(date: widget.session.date);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Text(
                      widget.session.isExtraClass ? 'Delete' : 'Reset',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _selectedSubject != null
                      ? () async {
                          final updatedSession = ClassSession(
                            id: widget.session.id,
                            subjectId: _selectedSubject!.id,
                            date: widget.session.date,
                            status: _selectedStatus,
                            isExtraClass: widget.session.isExtraClass,
                            notes: widget.session.notes,
                          );
                          if (widget.isNew) {
                            await ref
                                .read(attendanceRepositoryProvider)
                                .logSession(updatedSession);
                          } else {
                            await ref
                                .read(attendanceRepositoryProvider)
                                .updateSession(updatedSession);
                          }
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          // Extra bottom padding for safety
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
