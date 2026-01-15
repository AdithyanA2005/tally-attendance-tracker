import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/animations/fade_in_slide.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/timeline_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/string_utils.dart';
import '../../calendar/data/models/session_model.dart';

import '../../calendar/data/repositories/attendance_repository.dart';
import '../../calendar/presentation/providers/attendance_provider.dart';
import '../../calendar/presentation/widgets/edit_session_sheet.dart';
import '../../settings/presentation/providers/today_classes_provider.dart';

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
                          return TimelineItem(
                            isLast: isLast,
                            child: _TodayClassCard(item: item),
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
    return const EmptyState(
      icon: Icons.check_circle_outline_rounded,
      title: 'All caught up!',
      subtitle: 'No classes scheduled for today.',
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
          color: theme.cardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(item.currentStatus),
              size: 20,
              color: _getStatusColor(item.currentStatus).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.subject.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.3,
                  ),
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

    return AppCard(
      padding: EdgeInsets.zero,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.05),
          ),
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
    return AppTheme.statusColors[status] ?? Colors.black;
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
      builder: (context) => EditSessionSheet(
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
            color: color.withValues(alpha: 0.1),
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
