import 'package:flutter/material.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// A colored chip widget that displays a subject label.
/// Automatically maps subject names to colors from [AppColors.subjectColors].
class SubjectChip extends StatelessWidget {
  final String subject;
  final bool isSelected;
  final VoidCallback? onTap;

  const SubjectChip({
    super.key,
    required this.subject,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getSubjectColor(subject);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          subject,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
        ),
      ),
    );
  }
}
