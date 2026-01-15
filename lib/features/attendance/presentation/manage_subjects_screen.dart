import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance/presentation/providers/attendance_provider.dart';
import 'package:attendance_intelligence/core/presentation/animations/fade_in_slide.dart';
import '../data/models/subject_model.dart';
import '../data/repositories/attendance_repository.dart';

class ManageSubjectsScreen extends ConsumerWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              'Subjects',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            sliver: subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subjects added yet.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final subject = subjects[index];
                    // Add spacing between items
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: Duration(milliseconds: index * 100),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showSubjectSheet(context, subject);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: subject.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        subject.name.substring(0, 1),
                                        style: TextStyle(
                                          color: subject.color,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subject.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _InfoTag(
                                                icon:
                                                    Icons.track_changes_rounded,
                                                label:
                                                    '${subject.minimumAttendancePercentage.toInt()}% Target',
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.tertiary,
                                              ),
                                              const SizedBox(width: 12),
                                              _InfoTag(
                                                icon: Icons.access_time_rounded,
                                                label:
                                                    '${subject.weeklyHours}h/week',
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.tertiary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: subjects.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) =>
                  SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showSubjectSheet(context, null);
        },
        backgroundColor: const Color(0xFF2D3436), // Obsidian Grey
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showSubjectSheet(BuildContext context, Subject? subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SubjectFormSheet(subjectToEdit: subject),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SubjectFormSheet extends ConsumerStatefulWidget {
  final Subject? subjectToEdit;
  const _SubjectFormSheet({this.subjectToEdit});

  @override
  ConsumerState<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<_SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _minAttendanceController;
  late TextEditingController _weeklyHoursController;
  late Color _selectedColor;

  final List<Color> _colors = [
    const Color(0xFF2C3E50), // Midnight Blue (Swapped from 2nd last)
    const Color(0xFF8E44AD), // Muted Purple
    const Color(0xFF27AE60), // Sage Green
    const Color(0xFFD35400), // Burnt Orange
    const Color(0xFFC0392B), // Muted Red
    const Color(0xFF16A085), // Muted Teal
    const Color(0xFF2980B9), // Muted Blue (Swapped from 1st)
    const Color(0xFFD81B60), // Deep Pink
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.subjectToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _minAttendanceController = TextEditingController(
      text: s?.minimumAttendancePercentage.toString() ?? '75',
    );
    _weeklyHoursController = TextEditingController(
      text: s?.weeklyHours.toString() ?? '5',
    );
    _selectedColor = s?.color ?? const Color(0xFF2C3E50);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minAttendanceController.dispose();
    _weeklyHoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final minAtt = double.tryParse(_minAttendanceController.text) ?? 75.0;
      final weeklyHours = int.tryParse(_weeklyHoursController.text) ?? 5;

      final repo = ref.read(attendanceRepositoryProvider);

      if (widget.subjectToEdit != null) {
        final updated = widget.subjectToEdit!.copyWith(
          name: name,
          minimumAttendancePercentage: minAtt,
          weeklyHours: weeklyHours,
          colorTag: _selectedColor.value, // ignore: deprecated_member_use
        );
        await repo.updateSubject(updated);
      } else {
        await repo.addSubject(
          name: name,
          minAttendance: minAtt,
          weeklyHours: weeklyHours,
          color: _selectedColor,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Subject "$name" saved!')));
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: const Text(
          'This will delete all attendance records for this subject. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.subjectToEdit != null) {
      await ref
          .read(attendanceRepositoryProvider)
          .deleteSubject(widget.subjectToEdit!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subjectToEdit != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Subject' : 'Add Subject',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (isEditing)
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Data Structures',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            const Text('Color Tag'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minAttendanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Attendance %',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weeklyHoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weekly Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Subject'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
