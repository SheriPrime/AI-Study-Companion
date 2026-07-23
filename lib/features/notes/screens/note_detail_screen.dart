import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/core/widgets/subject_chip.dart';
import 'package:ai_study_companion/core/widgets/shimmer_card.dart';
import 'package:ai_study_companion/core/widgets/loading_button.dart';
import 'package:ai_study_companion/models/note.dart';
import 'package:ai_study_companion/models/summary.dart';
import 'package:ai_study_companion/models/quiz.dart';
import 'package:ai_study_companion/models/youtube_video.dart';
import 'package:ai_study_companion/features/notes/controllers/ai_hub_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/notes_controller.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';

/// AI Hub — the detail screen for a single note.
///
/// Shows note metadata, provides two hero actions (Generate Summary &
/// Generate Quiz) with premium pulsing shimmer animations during loading,
/// and renders beautiful summary / quiz result cards.
class NoteDetailScreen extends StatefulWidget {
  /// The note ID from the route parameter.
  final String noteId;

  /// Optionally passed note object via GoRouter `extra`.
  final Note? note;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
    this.note,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  int _selectedTab = 0; // 0: AI Assistant, 1: Visual Learning

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Load YouTube recommendations once we know the note
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final note = widget.note ?? _findNote();
      if (note != null) {
        final query = '${note.title} ${note.subject}';
        context.read<AiHubController>().loadRecommendedVideos(query);
      }
    });
  }

  Note? _findNote() {
    try {
      return context.read<NotesController>().notes.firstWhere(
            (n) => n.id.toString() == widget.noteId,
          );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Note? note = widget.note;
    if (note == null) {
      try {
        note = context.read<NotesController>().notes.firstWhere(
              (n) => n.id.toString() == widget.noteId,
            );
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          note?.title ?? 'Note Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.read<AiHubController>().resetAll();
            context.pop();
          },
        ),
      ),
      body: Consumer<AiHubController>(
        builder: (context, controller, _) {
          if (note == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading note details...'),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Note info card ────────────────────────────────────
                _NoteInfoCard(note: note),
                const SizedBox(height: 20),

                // ── Segmented Tab Toggle ──────────────────────────────
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? AppColors.surfaceWhite
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: _selectedTab == 0
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Assistant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 0
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? AppColors.surfaceWhite
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_fill,
                                  size: 18,
                                  color: _selectedTab == 1
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Visual Learning',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 1
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_selectedTab == 0) ...[
                  // ── Action buttons ────────────────────────────────────
                  _ActionButtonRow(
                    localFilePath: note.localFilePath,
                    controller: controller,
                  ),
                  const SizedBox(height: 24),

                  // ── Error message ─────────────────────────────────────
                  if (controller.errorMessage != null)
                    _ErrorBanner(message: controller.errorMessage!),

                  // ── Generating shimmer ────────────────────────────────
                  if (controller.isGeneratingSummary)
                    _PulsingShimmerSection(
                      animation: _pulseAnimation,
                      label: 'Generating AI Summary…',
                      icon: Icons.auto_awesome,
                      color: AppColors.primary,
                    ),

                  if (controller.isGeneratingQuiz)
                    _PulsingShimmerSection(
                      animation: _pulseAnimation,
                      label: 'Generating AI Quiz…',
                      icon: Icons.quiz_outlined,
                      color: AppColors.quizPurple,
                    ),

                  // ── Summary results ───────────────────────────────────
                  if (controller.summary != null &&
                      !controller.isGeneratingSummary)
                    _SummarySection(summary: controller.summary!),

                  // ── Quiz results ──────────────────────────────────────
                  if (controller.quiz != null && !controller.isGeneratingQuiz)
                    _QuizSection(
                      quiz: controller.quiz!,
                      controller: controller,
                    ),
                ] else ...[
                  // ── YouTube Recommendations (Visual Learning Tab) ─────
                  _YouTubeSection(
                    videos: controller.recommendedVideos,
                    isLoading: controller.isLoadingVideos,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Note Info Card
// ═══════════════════════════════════════════════════════════════════════════════

class _NoteInfoCard extends StatelessWidget {
  final Note note;

  const _NoteInfoCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getSubjectColor(note.subject),
                  AppColors.getSubjectColor(note.subject).withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SubjectChip(subject: note.subject),
                    const SizedBox(width: 10),
                    Icon(Icons.insert_drive_file_outlined,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        note.fileName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Action Buttons
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionButtonRow extends StatelessWidget {
  final String localFilePath;
  final AiHubController controller;

  const _ActionButtonRow({
    required this.localFilePath,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientActionButton(
            label: 'Generate Summary',
            icon: Icons.auto_awesome,
            colors: [AppColors.primary, AppColors.primaryLight],
            isLoading: controller.isGeneratingSummary,
            onTap: controller.isGeneratingSummary || controller.isGeneratingQuiz
                ? null
                : () => controller.generateSummary(localFilePath),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientActionButton(
            label: 'Generate Quiz',
            icon: Icons.quiz_outlined,
            colors: [AppColors.quizPurple, const Color(0xFFa78bfa)],
            isLoading: controller.isGeneratingQuiz,
            onTap: controller.isGeneratingSummary || controller.isGeneratingQuiz
                ? null
                : () => _showQuestionCountDialog(context),
          ),
        ),
      ],
    );
  }

  void _showQuestionCountDialog(BuildContext context) {
    int selectedCount = 10;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              title: const Row(
                children: [
                  Icon(Icons.quiz_outlined, color: AppColors.quizPurple),
                  SizedBox(width: 8),
                  Text('Quiz Question Count'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How many conceptual MCQs would you like Gemini AI to generate for this note?',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [5, 10, 15, 20].map((count) {
                      final isSelected = selectedCount == count;
                      return ChoiceChip(
                        label: Text('$count Questions'),
                        selected: isSelected,
                        selectedColor: AppColors.quizPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => selectedCount = count);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        controller.generateQuiz(localFilePath, count: selectedCount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.quizPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('Generate Quiz'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: onTap == null
                  ? colors.map((c) => c.withValues(alpha: 0.5)).toList()
                  : colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Pulsing Shimmer (AI generation loading state)
// ═══════════════════════════════════════════════════════════════════════════════

class _PulsingShimmerSection extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final IconData icon;
  final Color color;

  const _PulsingShimmerSection({
    required this.animation,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerCard(height: 100),
          const SizedBox(height: 12),
          const ShimmerCard(height: 140),
          const SizedBox(height: 12),
          const ShimmerCard(height: 80),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Error Banner
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Summary Section
// ═══════════════════════════════════════════════════════════════════════════════

class _SummarySection extends StatelessWidget {
  final Summary summary;

  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.auto_awesome,
          title: 'AI Summary',
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),

        // Overview card
        _PremiumCard(
          title: 'Overview',
          icon: Icons.remove_red_eye_outlined,
          accentColor: AppColors.accent,
          child: Text(
            summary.overview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
          ),
        ),
        const SizedBox(height: 14),

        // Key Points card
        _PremiumCard(
          title: 'Key Points',
          icon: Icons.lightbulb_outline,
          accentColor: AppColors.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: summary.keyPoints
                .map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              point,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Definitions card
        if (summary.definitions.isNotEmpty)
          _PremiumCard(
            title: 'Key Definitions',
            icon: Icons.menu_book_outlined,
            accentColor: AppColors.notesTeal,
            child: Column(
              children: List.generate(summary.definitions.length, (i) {
                final def = summary.definitions[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i > 0)
                      Divider(
                        color: AppColors.divider,
                        height: 20,
                      ),
                    Text(
                      def.term,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      def.meaning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                );
              }),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quiz Section
// ═══════════════════════════════════════════════════════════════════════════════

class _QuizSection extends StatelessWidget {
  final Quiz quiz;
  final AiHubController controller;

  const _QuizSection({
    required this.quiz,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.quiz_outlined,
          title: 'AI Quiz',
          color: AppColors.quizPurple,
        ),

        // Score banner (when results are shown)
        if (controller.showResults) ...[
          const SizedBox(height: 12),
          _ScoreBanner(
            score: controller.score,
            total: quiz.questions.length,
          ),
        ],
        const SizedBox(height: 16),

        // Questions
        ...List.generate(quiz.questions.length, (qi) {
          final question = quiz.questions[qi];
          return _QuestionCard(
            index: qi,
            total: quiz.questions.length,
            question: question,
            selectedAnswer: controller.selectedAnswers[qi],
            showResults: controller.showResults,
            onSelect: (oi) => controller.selectAnswer(qi, oi),
          );
        }),

        const SizedBox(height: 8),

        // Submit or retake button
        if (controller.showResults)
          LoadingButton(
            text: 'Retake Quiz',
            icon: Icons.refresh,
            onPressed: controller.resetQuiz,
            backgroundColor: AppColors.quizPurple,
          )
        else
          Builder(
            builder: (ctx) {
              return LoadingButton(
                text: 'Submit Answers',
                icon: Icons.check_circle_outline,
                onPressed: controller.allAnswered
                    ? () {
                        final uid = ctx.read<AuthController>().currentUser?.id;
                        controller.submitQuiz(uid);
                      }
                    : null,
                backgroundColor: AppColors.quizPurple,
              );
            },
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ScoreBanner extends StatelessWidget {
  final int score;
  final int total;

  const _ScoreBanner({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (score / total) : 0.0;
    final color = percentage >= 0.8
        ? AppColors.success
        : percentage >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(percentage * 100).round()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$score/$total correct',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  percentage >= 0.8
                      ? 'Excellent work! 🎉'
                      : percentage >= 0.5
                          ? 'Good effort, keep studying! 💪'
                          : 'Keep practicing, you\'ll get there! 📚',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final int total;
  final QuizQuestion question;
  final int? selectedAnswer;
  final bool showResults;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.selectedAnswer,
    required this.showResults,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.quizPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${index + 1}/$total',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.quizPurple,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question text
          Text(
            question.question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),

          // Option cards
          ...List.generate(question.options.length, (oi) {
            final isSelected = selectedAnswer == oi;
            final isCorrect = question.correctIndex == oi;

            Color borderColor = AppColors.divider;
            Color bgColor = AppColors.surfaceWhite;
            Color textColor = AppColors.textPrimary;
            IconData? trailingIcon;
            Color? trailingColor;

            if (showResults) {
              if (isCorrect) {
                borderColor = AppColors.success;
                bgColor = AppColors.success.withValues(alpha: 0.06);
                trailingIcon = Icons.check_circle;
                trailingColor = AppColors.success;
              } else if (isSelected && !isCorrect) {
                borderColor = AppColors.error;
                bgColor = AppColors.error.withValues(alpha: 0.06);
                textColor = AppColors.error;
                trailingIcon = Icons.cancel;
                trailingColor = AppColors.error;
              }
            } else if (isSelected) {
              borderColor = AppColors.quizPurple;
              bgColor = AppColors.quizPurple.withValues(alpha: 0.06);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: showResults ? null : () => onSelect(oi),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Radio-style indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (showResults
                                    ? (isCorrect
                                        ? AppColors.success
                                        : AppColors.error)
                                    : AppColors.quizPurple)
                                : AppColors.textHint,
                            width: 2,
                          ),
                          color: isSelected
                              ? (showResults
                                  ? (isCorrect
                                      ? AppColors.success
                                      : AppColors.error)
                                  : AppColors.quizPurple)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.circle,
                                    size: 8, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[oi],
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                      if (trailingIcon != null)
                        Icon(trailingIcon, color: trailingColor, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _PremiumCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// YouTube Recommendations Section
// ═══════════════════════════════════════════════════════════════════════════════

class _YouTubeSection extends StatelessWidget {
  final List<YouTubeVideo> videos;
  final bool isLoading;

  const _YouTubeSection({
    required this.videos,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (idx) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerCard(height: 110),
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'No recommended videos found for this topic.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Recommended Visuals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
          itemBuilder: (ctx, index) => _YouTubeVideoCard(
            video: videos[index],
          ),
        ),
      ],
    );
  }
}

class _YouTubeVideoCard extends StatelessWidget {
  final YouTubeVideo video;

  const _YouTubeVideoCard({required this.video});

  Future<void> _openVideo(BuildContext context) async {
    final webUri = Uri.parse(video.videoUrl);
    try {
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch video: ${video.videoUrl}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openVideo(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail with play overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        video.thumbnailUrl,
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.videocam_off, color: Colors.grey),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 80,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.red,
                        size: 36,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Title and channel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              video.channelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.open_in_new, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Watch on YouTube',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
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
    );
  }
}
