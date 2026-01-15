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
            ColorPicker(
              colors: AppTheme.subjectColors,
              selectedColor: _selectedColor,
              onColorSelected: (color) =>
                  setState(() => _selectedColor = color),
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
