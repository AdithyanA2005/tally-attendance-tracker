import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'providers/insights_provider.dart';
import 'package:tally/core/data/models/session_model.dart';
import '../../calendar/domain/entities/subject_stats.dart';
import '../../../core/presentation/animations/fade_in_slide.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/stats_display.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/anomalies/anomaly_section.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      body: insightsAsync.when(
        data: (stats) {
          final sortedSubjects = List<SubjectStats>.from(stats.subjectStats)
            ..sort((a, b) => a.percentage.compareTo(b.percentage));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(insightsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      snap: true,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      surfaceTintColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      title: Text(
                        'Insights',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      centerTitle: false,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 10),
                          // 1. Hero Stat (Big Typography)
                          FadeInSlide(
                            duration: const Duration(milliseconds: 600),
                            child: _buildHeroStat(context, stats),
                          ),

                          // Only show stats and performance when there's data
                          if (stats.subjectStats.isNotEmpty) ...[
                            const SizedBox(height: 32),

                            // 2. Quick Stats (Flat & Clean)
                            FadeInSlide(
                              duration: const Duration(milliseconds: 700),
                              child: _buildQuickStatsRow(context, stats),
                            ),
                            const SizedBox(height: 32),

                            // 3. Anomalies Section
                            const FadeInSlide(
                              duration: Duration(milliseconds: 750),
                              child: AnomalySection(),
                            ),

                            const SizedBox(height: 16),

                            // 3. Subject List Header
                            FadeInSlide(
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'PERFORMANCE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. Unified Subject List
                            ...sortedSubjects.asMap().entries.map((entry) {
                              final index = entry.key;
                              final subject = entry.value;
                              return FadeInSlide(
                                duration: const Duration(milliseconds: 800),
                                delay: Duration(milliseconds: 100 * index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: _buildMinimalSubjectCard(
                                    context,
                                    subject,
                                  ),
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeroStat(BuildContext context, InsightStats stats) {
    // Check if there's actually any data
    final hasNoData = stats.subjectStats.isEmpty;

    if (hasNoData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'N/A',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
              letterSpacing: -2,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No Attendance Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start marking attendance to see your insights.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final percentage = stats.overallPercentage;
    final isGood = percentage >= 75;
    final color = isGood
        ? AppTheme.statusColors[AttendanceStatus.present]!
        : AppTheme.statusColors[AttendanceStatus.absent]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              percentage.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -2,
                height: 1,
              ),
            ),
            Text(
              '%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isGood ? 'Overall Attendance' : 'Attention Required',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (!isGood) ...[
          const SizedBox(height: 4),
          Text(
            'Running low. Prioritize classes to recover.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStatsRow(BuildContext context, InsightStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatsDisplay(
            label: 'Skippable',
            value: '${stats.totalClassesSkippable}',
            icon: Icons.pause_circle_outline_rounded,
            color: AppTheme.statusColors[AttendanceStatus.present]!,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        Expanded(
          child: StatsDisplay(
            label: 'To Attend',
            value: '${stats.totalClassesNeeded}',
            icon: Icons.play_circle_outline_rounded,
            color: const Color(
              0xFFE67E22,
            ), // Orange for "To Attend" (Warning/Action)
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalSubjectCard(BuildContext context, SubjectStats subject) {
    final isSafe = subject.isSafe;
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: theme.cardColor,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/subject/${subject.subject.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.subject.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: subject.subject.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSafe
                              ? '${subject.classesSkippable} skips available'
                              : 'Attend next ${subject.classesNeededFor75}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${subject.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${subject.present}/${subject.conducted}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
