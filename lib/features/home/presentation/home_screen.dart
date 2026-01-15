import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/animations/fade_in_slide.dart';
import '../../../../core/utils/string_utils.dart';
import '../../attendance/data/models/session_model.dart';
import '../../attendance/data/models/subject_model.dart';
import '../../attendance/data/repositories/attendance_repository.dart';
import '../../attendance/presentation/providers/attendance_provider.dart';
import '../../timetable/presentation/providers/today_classes_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayClassesAsyncValue = ref.watch(todayClassesProvider);
    final now = DateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              DateFormat('EEEE, d MMMM').format(now),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: todayClassesAsyncValue.maybeWhen(
                data: (items) => Text(
                  items.isEmpty
                      ? 'No classes today'
                      : '${items.length} classes scheduled',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  child: todayClassesAsyncValue.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isLast = index == items.length - 1;
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline Line
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: Theme.of(
                                            context,
                                          ).dividerColor.withOpacity(0.2),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: _TodayClassCard(item: item),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error: $e'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'No classes scheduled for today.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayClassCard extends ConsumerWidget {
  final TodayClassItem item;
  const _TodayClassCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMarked = item.currentStatus != AttendanceStatus.unmarked;
    final theme = Theme.of(context);

    if (isMarked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(item.currentStatus),
              size: 20,
              color: _getStatusColor(item.currentStatus).withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.subject.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _showEditDialog(context, ref);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.entry.startTime,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      formatDuration(item.entry.durationInHours),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (item.subject.id != item.originalSubject.id)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Substituted for ${item.originalSubject.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showEditDialog(context, ref),
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: theme.dividerColor.withOpacity(0.05)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _MiniActionButton(
                    label: 'Present',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF27AE60),
                    onTap: () => _mark(ref, AttendanceStatus.present),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniActionButton(
                    label: 'Absent',
                    icon: Icons.close_rounded,
                    color: const Color(0xFFC0392B),
                    onTap: () => _mark(ref, AttendanceStatus.absent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.cancelled:
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF27AE60);
      case AttendanceStatus.absent:
        return const Color(0xFFC0392B);
      case AttendanceStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _mark(WidgetRef ref, AttendanceStatus status) async {
    HapticFeedback.lightImpact();
    // Re-use existing logic
    final session = ClassSession(
      id: item.existingSession?.id.isNotEmpty == true
          ? item.existingSession!.id
          : const Uuid().v4(),
      subjectId: item.subject.id,
      date: item.scheduledTime,
      status: status,
    );
    await ref.read(attendanceRepositoryProvider).logSession(session);
    ref.invalidate(todayClassesProvider);
    ref.invalidate(subjectStatsListProvider);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    // Re-use existing dialog logic
    final repo = ref.read(attendanceRepositoryProvider);
    final allSubjects = repo.getSubjects();

    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditSessionSheet(
        session:
            item.existingSession ??
            ClassSession(
              id: const Uuid().v4(),
              subjectId: item.subject.id,
              date: item.scheduledTime,
              status: AttendanceStatus.unmarked,
            ),
        initialSubject: item.subject,
        allSubjects: allSubjects,
        isNew: item.existingSession == null,
      ),
    );

    ref.invalidate(todayClassesProvider);
    ref.invalidate(subjectStatsListProvider);
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Standard rounded shape
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // Use the specific color tint to differentiate (Green tint vs Red tint)
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color, // Text matches status color for clarity
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSessionSheet extends ConsumerStatefulWidget {
  final ClassSession session;
  final Subject initialSubject;
  final List<Subject> allSubjects;
  final bool isNew;

  const _EditSessionSheet({
    required this.session,
    required this.initialSubject,
    required this.allSubjects,
    this.isNew = false,
  });

  @override
  ConsumerState<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<_EditSessionSheet> {
  late Subject _selectedSubject;
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
                      .withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subject Dropdown
          DropdownButtonFormField<Subject>(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            borderRadius: BorderRadius.circular(16),
            decoration: InputDecoration(
              labelText: 'Subject',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.3,
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
            initialValue: widget.allSubjects.firstWhere(
              (s) => s.id == _selectedSubject.id,
              orElse: () => _selectedSubject,
            ),
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
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.3,
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
              // Always show Reset button to allow clearing/cancelling back to default
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
                        color: theme.colorScheme.error.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final updatedSession = ClassSession(
                      id: widget.session.id,
                      subjectId: _selectedSubject.id,
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
                  },
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
