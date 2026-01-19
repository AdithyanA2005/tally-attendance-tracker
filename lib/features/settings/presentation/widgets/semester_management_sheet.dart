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

  // Create Form State
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();

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
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isCreating ? 'New Semester' : 'Switch Semester',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isCreating)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    TextButton(
                      onPressed: () => setState(() => _isCreating = false),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No semesters found. Create one!'),
              ),

            ...sorted.map((semester) {
              final isActive = semester.id == activeId;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: isActive
                      ? Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                          width: 2,
                        )
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    semester.name,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    'Starts: ${DateFormat('MMM d, yyyy').format(semester.startDate)}',
                  ),
                  trailing: isActive
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () async {
                    if (!isActive) {
                      await ref
                          .read(semesterRepositoryProvider)
                          .setActiveSemesterId(semester.id);

                      // Force provider refresh
                      ref.invalidate(activeSemesterProvider);
                      // Invalidate downstream dependent providers if necessary,
                      // but activeSemesterProvider used in .watch should be enough.

                      if (mounted) Navigator.pop(context);
                    }
                  },
                ),
              );
            }),

            const SizedBox(height: 16),
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
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
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
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newSemester = Semester(
                  id: const Uuid().v4(),
                  name: _nameController.text.trim(),
                  startDate: _startDate,
                  isActive: true, // Auto-activate
                  hasPendingSync: true,
                );

                await ref
                    .read(semesterRepositoryProvider)
                    .addSemester(newSemester);

                // Set as active
                await ref
                    .read(semesterRepositoryProvider)
                    .setActiveSemesterId(newSemester.id);

                if (mounted) Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Create & Switch'),
          ),
        ],
      ),
    );
  }
}
