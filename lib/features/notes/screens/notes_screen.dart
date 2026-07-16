import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/core/widgets/subject_chip.dart';
import 'package:ai_study_companion/core/widgets/shimmer_list.dart';
import 'package:ai_study_companion/core/widgets/loading_button.dart';
import 'package:ai_study_companion/core/widgets/empty_state.dart';
import 'package:ai_study_companion/core/widgets/app_text_field.dart';
import 'dart:io';
import 'package:ai_study_companion/models/note.dart';
import 'package:ai_study_companion/features/notes/controllers/notes_controller.dart';
import 'package:ai_study_companion/services/local_file_service.dart';

/// The Notes listing screen.
///
/// Displays all uploaded notes with horizontal subject-chip filtering,
/// a shimmer loading skeleton, and a FAB to upload new notes via a
/// modern bottom sheet.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    // Load notes once the frame is ready so Provider context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesController>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Notes'),
        centerTitle: false,
      ),
      body: Consumer<NotesController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: ShimmerList(itemCount: 6, itemHeight: 96),
            );
          }

          return Column(
            children: [
              // ── Subject filter chips ──────────────────────────────────
              _SubjectFilterBar(controller: controller),

              // ── Notes list ────────────────────────────────────────────
              Expanded(
                child: controller.filteredNotes.isEmpty
                    ? EmptyState(
                        icon: Icons.note_add_outlined,
                        title: 'No notes yet',
                        subtitle: controller.selectedSubject != null
                            ? 'No notes found for "${controller.selectedSubject}".\nTry a different filter or upload a new note.'
                            : 'Upload your first study note\nto get started with AI summaries & quizzes.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: controller.filteredNotes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _NoteCard(
                            note: controller.filteredNotes[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Upload Note',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // ── Upload bottom sheet ─────────────────────────────────────────────────────

  void _showUploadSheet(BuildContext context) {
    final titleController = TextEditingController();
    String? selectedSubject;
    File? selectedFile;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Upload New Note',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a study note to unlock AI summaries & quizzes',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Note title field
                      AppTextField(
                        label: 'Note Title',
                        controller: titleController,
                        prefixIcon: Icons.title,
                        onChanged: (text) => setSheetState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Subject dropdown row with "+ Add Custom Course" button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                prefixIcon: Icon(Icons.category_outlined, size: 22),
                              ),
                              items: context.read<NotesController>().subjects
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onChanged: (v) => setSheetState(() => selectedSubject = v),
                              validator: (v) => v == null ? 'Please select a subject' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showAddCourseDialog(context, (newCourse) {
                              setSheetState(() {
                                selectedSubject = newCourse;
                              });
                            }),
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            tooltip: 'Add Course',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Actual file picker button
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          try {
                            final file = await ctx.read<LocalFileService>().pickStudyFile();
                            if (file != null) {
                              setSheetState(() {
                                selectedFile = file;
                                if (titleController.text.trim().isEmpty) {
                                  // Auto-fill title with file name without extension
                                  final name = file.path.split('/').last;
                                  final extIndex = name.lastIndexOf('.');
                                  titleController.text = extIndex != -1
                                      ? name.substring(0, extIndex).replaceAll('_', ' ').replaceAll('-', ' ')
                                      : name;
                                }
                              });
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error picking file: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedFile != null ? AppColors.success : AppColors.divider,
                              width: selectedFile != null ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            color: selectedFile != null
                                ? AppColors.success.withValues(alpha: 0.05)
                                : AppColors.surface,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selectedFile != null ? Icons.check_circle_outline : Icons.upload_file,
                                color: selectedFile != null ? AppColors.success : AppColors.accent,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedFile != null
                                      ? selectedFile!.path.split('/').last
                                      : 'Select PDF or PowerPoint',
                                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                        color: selectedFile != null ? AppColors.success : AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Upload button
                      Consumer<NotesController>(
                        builder: (_, ctrl, child) {
                          final isValid = titleController.text.trim().isNotEmpty &&
                              selectedSubject != null &&
                              selectedFile != null;
                          return LoadingButton(
                            text: 'Upload Note',
                            icon: Icons.cloud_upload_outlined,
                            isLoading: ctrl.isUploading,
                            onPressed: isValid
                                ? () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final success = await ctrl.uploadNote(
                                      titleController.text.trim(),
                                      selectedSubject!,
                                      selectedFile!,
                                    );
                                    if (!ctx.mounted) return;
                                    if (success) {
                                      Navigator.of(ctx).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Note uploaded successfully!'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(ctrl.errorMessage ?? 'Upload failed. Please try again.'),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCourseDialog(BuildContext context, ValueChanged<String> onCourseAdded) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Course'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create a custom subject category for your notes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Course Name (e.g. Networks)',
                      controller: controller,
                      prefixIcon: Icons.book_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                      onChanged: (text) {
                        setDialogState(() {}); // Rebuild to toggle button state
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (controller.text.trim().isEmpty || isSaving)
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final newCourse = controller.text.trim();
                            await context.read<NotesController>().addCourse(newCourse);
                            onCourseAdded(newCourse);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Course "$newCourse" created successfully!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add course: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(100, 44),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Course'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Horizontal scrollable subject chip bar with an "All" option.
class _SubjectFilterBar extends StatelessWidget {
  final NotesController controller;

  const _SubjectFilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final subjects = controller.subjects;
    if (subjects.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SubjectChip(
              subject: 'All',
              isSelected: controller.selectedSubject == null,
              onTap: () => controller.filterBySubject(null),
            ),
          ),
          ...subjects.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SubjectChip(
                  subject: s,
                  isSelected: controller.selectedSubject == s,
                  onTap: () => controller.filterBySubject(s),
                ),
              )),
        ],
      ),
    );
  }
}

/// A single note card in the list.
class _NoteCard extends StatelessWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMM d, yyyy').format(note.dateAdded);

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/notes/${note.id}', extra: note),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.getSubjectColor(note.subject)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppColors.getSubjectColor(note.subject),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SubjectChip(subject: note.subject),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            note.fileName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
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

              // Date
              Text(
                dateFormatted,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
