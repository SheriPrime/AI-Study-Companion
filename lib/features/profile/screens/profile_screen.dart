import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';
import 'package:ai_study_companion/features/profile/controllers/profile_controller.dart';

/// Profile screen displaying user information with a premium gradient header,
/// interactive circular avatar with camera badge, info cards, and a logout action.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Extracts the user's initials from their full name.
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final profileController = context.watch<ProfileController>();
    final user = authController.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header with Avatar ──────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient background
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                        AppColors.accent,
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),

                // Title
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Profile',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Avatar – positioned to overlap the gradient bottom
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _ProfileAvatar(
                      initials: user != null ? _getInitials(user.name) : '?',
                      profileImage: profileController.profileImage,
                      isLoading: profileController.isPickingImage,
                      onTap: () => _showImagePickerSheet(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── User Name & Email ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  Text(
                    user?.name ?? 'Unknown User',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Info Cards ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.school,
                        label: 'University',
                        value: user?.university ?? '—',
                        iconColor: AppColors.primary,
                      ),
                      const Divider(height: 1, indent: 56),
                      _InfoRow(
                        icon: Icons.account_tree,
                        label: 'Department',
                        value: user?.department ?? '—',
                        iconColor: AppColors.accent,
                      ),
                      const Divider(height: 1, indent: 56),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Timeline',
                        value: user?.timeline ?? '—',
                        iconColor: AppColors.streakOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Logout Button ────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        authController.logout();
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Image Picker Bottom Sheet ──────────────────────────────────────────────

  void _showImagePickerSheet(BuildContext context) {
    final profileController = context.read<ProfileController>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
                  'Update Profile Photo',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to add your photo',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),

                // Options row
                Row(
                  children: [
                    // Take Photo option
                    Expanded(
                      child: _ImagePickerOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Take Photo',
                        color: AppColors.primary,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final success =
                              await profileController.pickFromCamera();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Profile photo updated!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else if (profileController.errorMessage !=
                              null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    profileController.errorMessage!),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Choose from Gallery option
                    Expanded(
                      child: _ImagePickerOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: AppColors.accent,
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final success =
                              await profileController.pickFromGallery();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Profile photo updated!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else if (profileController.errorMessage !=
                              null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    profileController.errorMessage!),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Remove photo option (only shown if a photo is set)
                if (profileController.profileImage != null)
                  TextButton.icon(
                    onPressed: () {
                      profileController.clearProfileImage();
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Profile photo removed'),
                          backgroundColor: AppColors.textSecondary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                    label: Text(
                      'Remove Photo',
                      style:
                          Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Interactive profile avatar with camera badge overlay.
///
/// Displays the user's profile image if available, otherwise shows initials.
/// Shows a loading spinner when an image pick operation is in progress.
/// A camera badge icon indicates the avatar is tappable/editable.
class _ProfileAvatar extends StatelessWidget {
  final String initials;
  final File? profileImage;
  final bool isLoading;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.initials,
    required this.profileImage,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          children: [
            // Avatar with border & shadow
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceWhite,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : null,
                child: _buildAvatarContent(theme),
              ),
            ),

            // Loading overlay
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            // Camera badge
            if (!isLoading)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceWhite,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Shows initials when no profile image is set, nothing when image is present.
  Widget? _buildAvatarContent(ThemeData theme) {
    if (profileImage != null) return null;
    return Text(
      initials,
      style: theme.textTheme.displayMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// A tappable image-picker option tile (Camera / Gallery).
class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded card that wraps a list of [_InfoRow] widgets.
class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// A single info row with an icon, label, and value.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
