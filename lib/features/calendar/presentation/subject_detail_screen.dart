import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/subject_stats.dart';
import 'providers/attendance_provider.dart';
import '../../../../core/presentation/animations/fade_in_slide.dart';
import 'widgets/subject_history_list.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(subjectStatsFamily(subjectId));

    return Scaffold(
      body: statsAsync.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('Subject not found'));
          }
          final subject = stats.subject;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                title: Text(
                  'Subject Details',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: false,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Hero Section (Minimal Typography)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            subject.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Huge Percentage Display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                stats.percentage.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  letterSpacing: -4,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: stats.isSafe
                                  ? const Color(0xFF27AE60).withOpacity(0.1)
                                  : const Color(0xFFC0392B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              stats.isSafe ? 'Safe Zone' : 'Attention Required',
                              style: TextStyle(
                                color: stats.isSafe
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFFC0392B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Minimal Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMinimalStatItem(
                                context,
                                'Present',
                                '${stats.present}',
                                Icons.check_circle_outline_rounded,
                                const Color(0xFF27AE60),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                            ),
                            Expanded(
                              child: _buildMinimalStatItem(
                                context,
                                'Absent',
                                '${stats.absent}',
                                Icons.cancel_outlined,
                                const Color(0xFFC0392B),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                            ),
                            Expanded(
                              child: _buildMinimalStatItem(
                                context,
                                'Skippable',
                                '${stats.classesSkippable}',
                                Icons.pause_circle_outline_rounded,
                                const Color(0xFF2980B9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Analysis Section
                      FadeInSlide(
                        duration: const Duration(milliseconds: 600),
                        child: _buildAnalysisSection(context, stats),
                      ),

                      const SizedBox(height: 32),

                      // History Header
                      FadeInSlide(
                        duration: const Duration(milliseconds: 700),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'HISTORY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // History List
                      FadeInSlide(
                        duration: const Duration(milliseconds: 800),
                        child: SubjectHistoryList(history: stats.history),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAnalysisSection(BuildContext context, SubjectStats stats) {
    return Column(
      children: [
        // Prediction Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2980B9).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF2980B9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forecast',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attending the next class will boost you to ${stats.predictionNextClass.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Insight/Advice Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: stats.isSafe
                ? const Color(0xFF27AE60).withOpacity(0.05)
                : const Color(0xFFC0392B).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: stats.isSafe
                  ? const Color(0xFF27AE60).withOpacity(0.1)
                  : const Color(0xFFC0392B).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: stats.isSafe
                    ? const Color(0xFF27AE60).withOpacity(0.05)
                    : const Color(0xFFC0392B).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                stats.isSafe
                    ? Icons.verified_user_rounded
                    : Icons.warning_rounded,
                color: stats.isSafe
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFC0392B),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  stats.isSafe
                      ? 'You are in the safe zone. You can skip ${stats.classesSkippable} more classes while staying above ${stats.subject.minimumAttendancePercentage.toInt()}%.'
                      : 'Critical Status! You must attend the next ${stats.classesNeededFor75} classes to restore safe attendance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: stats.isSafe
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFC0392B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color.withOpacity(0.8)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}
