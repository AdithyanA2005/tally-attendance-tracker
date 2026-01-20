import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/subject_model.dart';
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
  late DateTime _selectedDate;
  late int _durationMinutes;
  bool _isSaving = false;
  bool _hasChanges = false;

  void _checkForChanges() {
    if (widget.isNew) {
      // For new sessions, basic validation is enough (subject selected)
      // or we can treat as always "has changes" if it's new, effectively enabling save once valid.
      // But typically "Save" is enabled for New items as soon as valid.
      // We'll manage this via the button condition.
      return;
    }

    final hasChanges =
        _selectedSubject?.id != widget.session.subjectId ||
        _selectedStatus != widget.session.status ||
        _selectedDate != widget.session.date ||
        _durationMinutes != widget.session.durationMinutes;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
    // Allow unmarked status (e.g. for scheduled/pending classes)
    _selectedStatus = widget.session.status;
    _selectedDate = widget.session.date;
    _durationMinutes = widget.session.durationMinutes;
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        _checkForChanges();
      });
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter statuses if needed, but allow all for now so users can set to Unmarked (Scheduled)
    final validStatuses = AttendanceStatus.values.toList();

    // Duration options matching Timetable form
    final durationOptions = [30, 45, 50, 60, 90, 120, 180];
    if (!durationOptions.contains(_durationMinutes)) {
      durationOptions.add(_durationMinutes);
      durationOptions.sort();
    }

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
      child: SingleChildScrollView(
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

            // Subject Dropdown
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
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
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
                  if (val != null) {
                    setState(() {
                      _selectedSubject = val;
                      _checkForChanges();
                    });
                  }
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
              items: validStatuses
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s == AttendanceStatus.scheduled
                            ? 'SCHEDULED'
                            : s.name.toUpperCase(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStatus = val;
                    _checkForChanges();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Time and Duration Row
            Row(
              children: [
                // Start Time Picker
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                        ),
                      ),
                      child: Text(
                        DateFormat.jm().format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Duration Dropdown
                Expanded(
                  child: DropdownButtonFormField<int>(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    initialValue: _durationMinutes,
                    items: durationOptions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(_formatMinutes(d)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _durationMinutes = val;
                          _checkForChanges();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                if (!widget.isNew) ...[
                  Expanded(
                    child: TextButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              try {
                                await ref
                                    .read(attendanceRepositoryProvider)
                                    .deleteDuplicateSessions(
                                      date: widget.session.date,
                                    );
                                if (context.mounted) Navigator.pop(context);
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.2,
                            ),
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
                    onPressed:
                        (_selectedSubject != null &&
                            !_isSaving &&
                            (widget.isNew || _hasChanges))
                        ? () async {
                            setState(() => _isSaving = true);
                            try {
                              final updatedSession = ClassSession(
                                id: widget.session.id,
                                subjectId: _selectedSubject!.id,
                                semesterId: widget.session.semesterId,
                                date: _selectedDate,
                                status: _selectedStatus,
                                isExtraClass: widget.session.isExtraClass,
                                notes: widget.session.notes,
                                durationMinutes: _durationMinutes,
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
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isSaving ? Colors.transparent : null,
                          ),
                        ),
                        if (_isSaving)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
