import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/core/widgets/shimmer_list.dart';
import 'package:ai_study_companion/core/widgets/app_text_field.dart';
import 'package:ai_study_companion/core/widgets/loading_button.dart';
import 'package:ai_study_companion/core/widgets/empty_state.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/features/planner/controllers/planner_controller.dart';

/// The main Study Planner screen.
///
/// Displays tasks grouped by status (overdue → pending → done) in a
/// timeline-style list. A FAB allows adding new tasks via a dialog.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlannerController>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Planner')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      body: Consumer<PlannerController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: ShimmerList(itemCount: 6),
            );
          }

          if (controller.errorMessage != null) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: controller.errorMessage!,
              action: TextButton.icon(
                onPressed: controller.loadTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }

          if (controller.tasks.isEmpty) {
            return const EmptyState(
              icon: Icons.event_note_rounded,
              title: 'No tasks yet',
              subtitle: 'Tap + to add your first study task.',
            );
          }

          return _TaskListView(controller: controller);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add-task dialog
  // ---------------------------------------------------------------------------

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'New Task',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 20),

                        // Title field
                        AppTextField(
                          label: 'Task Title',
                          controller: titleController,
                          prefixIcon: Icons.task_alt,
                          onChanged: (text) => setDialogState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a task title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description field (optional)
                        AppTextField(
                          label: 'Description (optional)',
                          controller: descriptionController,
                          prefixIcon: Icons.notes,
                        ),
                        const SizedBox(height: 16),

                        // Date picker
                        _PickerTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: DateFormat.yMMMd().format(selectedDate),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 1)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Time picker
                        _PickerTile(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: selectedTime.format(ctx),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedTime = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        Consumer<PlannerController>(
                          builder: (_, controller, child) {
                            final isValid =
                                titleController.text.trim().isNotEmpty;
                            return LoadingButton(
                              text: 'Add Task',
                              icon: Icons.add_task,
                              isLoading: controller.isAddingTask,
                              onPressed: isValid
                                  ? () => _submitTask(
                                        dialogContext,
                                        controller,
                                        formKey,
                                        titleController,
                                        descriptionController,
                                        selectedDate,
                                        selectedTime,
                                      )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitTask(
    BuildContext dialogContext,
    PlannerController controller,
    GlobalKey<FormState> formKey,
    TextEditingController titleCtrl,
    TextEditingController descCtrl,
    DateTime date,
    TimeOfDay time,
  ) async {
    if (!formKey.currentState!.validate()) return;

    final task = StudyTask(
      title: titleCtrl.text.trim(),
      description:
          descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
      date: date,
      time: time,
      status: TaskStatus.pending,
    );

    await controller.addTask(task);

    if (!dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: const Text('Task added!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// Task list view – renders sections in order: Overdue, Pending, Done
// =============================================================================

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.controller});
  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Overdue section
        if (controller.overdueTasks.isNotEmpty) ...[
          _SectionHeader(
            title: 'Overdue (${controller.overdueTasks.length})',
            color: AppColors.error,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 8),
          ...controller.overdueTasks.map(
            (t) => _TaskCard(task: t, controller: controller),
          ),
          const SizedBox(height: 20),
        ],

        // Pending section
        if (controller.pendingTasks.isNotEmpty) ...[
          _SectionHeader(
            title: 'Upcoming (${controller.pendingTasks.length})',
            color: AppColors.warning,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 8),
          ...controller.pendingTasks.map(
            (t) => _TaskCard(task: t, controller: controller),
          ),
          const SizedBox(height: 20),
        ],

        // Done section
        if (controller.doneTasks.isNotEmpty) ...[
          _SectionHeader(
            title: 'Completed (${controller.doneTasks.length})',
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 8),
          ...controller.doneTasks.map(
            (t) => _TaskCard(task: t, controller: controller),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Section header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.color,
    required this.icon,
  });
  final String title;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// =============================================================================
// Individual task card
// =============================================================================

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.controller});
  final StudyTask task;
  final PlannerController controller;

  Color get _borderColor {
    switch (task.status) {
      case TaskStatus.overdue:
        return AppColors.error;
      case TaskStatus.done:
        return AppColors.success;
      case TaskStatus.pending:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == TaskStatus.done;
    final isOverdue = task.status == TaskStatus.overdue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isDone
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),

                      // Description
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Date + time row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(task.date),
                            style: theme.textTheme.labelSmall,
                          ),
                          if (task.time != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(task.time!),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Status action icon
              SizedBox(
                width: 48,
                height: 48,
                child: isOverdue
                    ? const Center(
                        child: Icon(
                          Icons.warning_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          if (task.id != null) {
                            controller.toggleTask(task.id!);
                          }
                        },
                        icon: Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone
                              ? AppColors.success
                              : AppColors.textHint,
                          size: 24,
                        ),
                        tooltip: isDone ? 'Mark pending' : 'Mark done',
                        splashRadius: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats [TimeOfDay] as "2:30 PM".
  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// =============================================================================
// Picker tile — date / time selector row
// =============================================================================

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
