import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/color_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/subject_model.dart';
import '../../data/repositories/attendance_repository.dart';

class SubjectFormSheet extends ConsumerStatefulWidget {
  final Subject? subjectToEdit;
  const SubjectFormSheet({super.key, this.subjectToEdit});

  @override
  ConsumerState<SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _minAttendanceController;
  late TextEditingController _weeklyHoursController;
  late Color _selectedColor;
  bool _isFormValid = false;

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

    // Add listeners to validate form on every change
    _nameController.addListener(_validateForm);
    _minAttendanceController.addListener(_validateForm);
    _weeklyHoursController.addListener(_validateForm);

    // Initial validation
    _validateForm();
  }

  void _validateForm() {
    final isValid =
        _nameController.text.trim().isNotEmpty &&
        _minAttendanceController.text.trim().isNotEmpty &&
        _weeklyHoursController.text.trim().isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
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
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Subject' : 'Add Subject',
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

            // Subject Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Data Structures',
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
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 24),

            // Color Tag Section
            Text(
              'Color Tag',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ColorPicker(
              colors: AppTheme.subjectColors,
              selectedColor: _selectedColor,
              onColorSelected: (color) =>
                  setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),

            // Min Attendance & Weekly Hours
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minAttendanceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Attendance %',
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weeklyHoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weekly Hours',
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (isEditing)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _delete,
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
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isFormValid ? _save : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Save Subject' : 'Add Subject',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                onPressed: _isFormValid ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add Subject',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
