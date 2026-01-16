import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/attendance_provider.dart';
import 'package:attendance_intelligence/core/presentation/animations/fade_in_slide.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/presentation/widgets/info_tag.dart';
import '../data/models/subject_model.dart';
import 'widgets/subject_form_sheet.dart';

class ManageSubjectsScreen extends ConsumerWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subjectsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                  sliver: subjectsAsync.when(
                    data: (subjects) {
                      if (subjects.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.book_outlined,
                            title: 'No Subjects Added',
                            subtitle:
                                'Tap the + button to add your first subject.',
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
                              child: AppCard(
                                padding: EdgeInsets.zero,
                                backgroundColor: Theme.of(context).cardColor,
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
                                            color: subject.color.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                  InfoTag(
                                                    icon: Icons
                                                        .track_changes_rounded,
                                                    label:
                                                        '${subject.minimumAttendancePercentage.toInt()}% Target',
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.tertiary,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  InfoTag(
                                                    icon: Icons
                                                        .access_time_rounded,
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
                          );
                        }, childCount: subjects.length),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, s) => SliverFillRemaining(
                      child: Center(child: Text('Error: $e')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showSubjectSheet(context, null);
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3436),
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showSubjectSheet(BuildContext context, Subject? subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => SubjectFormSheet(subjectToEdit: subject),
    );
  }
}
