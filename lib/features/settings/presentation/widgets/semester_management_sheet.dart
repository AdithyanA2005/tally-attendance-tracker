import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tally/core/data/models/semester_model.dart';
import 'package:tally/features/settings/data/repositories/semester_repository.dart';
import 'package:uuid/uuid.dart';

class SemesterManagementSheet extends ConsumerStatefulWidget {
  const SemesterManagementSheet({super.key});

  @override
  ConsumerState<SemesterManagementSheet> createState() =>
      _SemesterManagementSheetState();
}

class _SemesterManagementSheetState
    extends ConsumerState<SemesterManagementSheet> {
  bool _isCreating = false;
  bool _isSaving = false;

  // Create Form State
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now().copyWith(
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
    microsecond: 0,
  );
  String? _editingId; // Track if we are editing

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch semesters stream for real-time updates
    final semestersAsync = ref.watch(watchSemestersProvider);
    final activeSemesterId = ref.watch(activeSemesterProvider).valueOrNull?.id;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              if (_isCreating) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingId != null ? 'Edit Semester' : 'New Semester',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isCreating = false;
                          _editingId = null;
                          _nameController.clear();
                          _startDate = DateTime.now();
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Text(
                  'Switch Semester',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
              ],

              if (_isCreating)
                _buildCreateForm()
              else
                _buildSemesterList(semestersAsync, activeSemesterId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterList(
    AsyncValue<List<Semester>> semestersAsync,
    String? activeId,
  ) {
    return semestersAsync.when(
      data: (semesters) {
        // Sort by start date descending (newest first)
        final sorted = List<Semester>.from(semesters)
          ..sort((a, b) => b.startDate.compareTo(a.startDate));

        return Column(
          children: [
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No semesters found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ...sorted.map((semester) {
              final isActive = semester.id == activeId;
              final colorScheme = Theme.of(context).colorScheme;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (!isActive) {
                        await ref
                            .read(semesterRepositoryProvider)
                            .setActiveSemesterId(semester.id);

                        // Force active semester provider refresh
                        ref.invalidate(activeSemesterProvider);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primary.withValues(alpha: 0.2)
                                  : colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  semester.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(semester.startDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isActive
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.8,
                                          )
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),

                          // Menu
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                setState(() {
                                  _isCreating = true;
                                  _editingId = semester.id;
                                  _nameController.text = semester.name;
                                  _startDate = semester.startDate;
                                });
                              } else if (value == 'delete') {
                                _deleteSemester(semester, isActive);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 20),
                                    SizedBox(width: 12),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() => _isCreating = true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Semester'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Future<void> _deleteSemester(Semester semester, bool isActive) async {
    if (isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cannot delete the active semester. Please switch first.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester?'),
        content: Text(
          'Are you sure you want to delete "${semester.name}"?\n\n'
          'This will permanently delete ALL subjects, classes, and timetable entries associated with this semester.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(semesterRepositoryProvider).deleteSemester(semester.id);
    }
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Input
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Semester Name',
              hintText: 'e.g., Spring 2024 or Semester 6',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 16),

          // Date Picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _startDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                suffixIcon: const Icon(Icons.calendar_today_rounded),
              ),
              child: Text(
                DateFormat('MMMM d, yyyy').format(_startDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Create Button
          // Create Button
          FilledButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      // Close keyboard first to ensure clean navigation
                      FocusScope.of(context).unfocus();

                      setState(() => _isSaving = true);
                      try {
                        if (_editingId != null) {
                          // Update Existing
                          final repo = ref.read(semesterRepositoryProvider);
                          final original = repo.box.get(_editingId!);
                          if (original != null) {
                            await repo.updateSemester(
                              original.copyWith(
                                name: _nameController.text.trim(),
                                startDate: _startDate,
                                hasPendingSync: true,
                              ),
                            );

                            if (mounted) {
                              setState(() {
                                _isCreating = false;
                                _editingId = null;
                              });
                            }
                          }
                        } else {
                          // Create New
                          final newSemester = Semester(
                            id: const Uuid().v4(),
                            name: _nameController.text.trim(),
                            startDate: _startDate,
                            isActive: false, // Profile controls status now
                            hasPendingSync: true,
                          );

                          await ref
                              .read(semesterRepositoryProvider)
                              .addSemester(newSemester);

                          // Set as active (Switch)
                          await ref
                              .read(semesterRepositoryProvider)
                              .setActiveSemesterId(newSemester.id);

                          if (mounted) Navigator.pop(context);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    }
                  },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _editingId != null ? 'Update Semester' : 'Create & Switch',
                  style: TextStyle(
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
        ],
      ),
    );
  }
}
