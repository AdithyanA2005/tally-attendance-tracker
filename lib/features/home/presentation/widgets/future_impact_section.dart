import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:tally/core/data/models/session_model.dart';
import '../providers/future_impact_provider.dart';
import '../../../../core/presentation/animations/fade_in_slide.dart';
import '../../../../core/presentation/widgets/app_card.dart';

class FutureImpactSection extends ConsumerWidget {
  const FutureImpactSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impactAsync = ref.watch(futureImpactProvider);

    return impactAsync.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Impact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('EEEE, MMM d').format(summary.date),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary.impacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: index * 100),
                  child: _SubjectImpactCard(impact: summary.impacts[index]),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _SubjectImpactCard extends StatelessWidget {
  final SubjectImpact impact;

  const _SubjectImpactCard({required this.impact});

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(impact.subject.colorTag);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Calendar-style Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: subjectColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: subjectColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  impact.subject.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${impact.currentPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOutcome(
                  context,
                  label: 'If Present',
                  percentage: impact.percentageIfPresent,
                  diff: impact.gain,
                  color: AppTheme.statusColors[AttendanceStatus.present]!,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildOutcome(
                  context,
                  label: 'If Absent',
                  percentage: impact.percentageIfAbsent,
                  diff: -impact.loss,
                  color: AppTheme.statusColors[AttendanceStatus.absent]!,
                  icon: Icons.cancel_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(
    BuildContext context, {
    required String label,
    required double percentage,
    required double diff,
    required Color color,
    required IconData icon,
  }) {
    final isPositive = diff >= 0;
    final diffStr = '${isPositive ? "+" : ""}${diff.toStringAsFixed(1)}%';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          diffStr,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
