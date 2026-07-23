import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// The app shell that wraps all main tabs with a bottom navigation bar.
///
/// Used as the builder for [ShellRoute] in GoRouter. The [child] parameter
/// receives the currently routed page, and [state] carries the current
/// router state for determining the active tab.
class ShellScreen extends StatefulWidget {
  /// The routed child widget rendered in the body.
  final Widget child;

  /// The current [GoRouterState], used to derive the selected tab index.
  final GoRouterState state;

  const ShellScreen({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  /// Maps a route location to its corresponding tab index.
  int _getSelectedIndex(String location) {
    if (location.startsWith('/notes')) return 1;
    if (location.startsWith('/planner')) return 2;
    if (location.startsWith('/progress')) return 3;
    // Default to dashboard (including /profile and /dashboard)
    return 0;
  }

  /// The four main tab routes.
  static const List<String> _routes = [
    '/dashboard',
    '/notes',
    '/planner',
    '/progress',
  ];

  void _onTabTapped(int index) {
    // Only navigate if the tab is different from the current one.
    if (index != _getSelectedIndex(GoRouterState.of(context).uri.toString())) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = widget.state.uri.toString();
    final selectedIndex = _getSelectedIndex(currentLocation);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_rounded),
                activeIcon: Icon(Icons.description_rounded),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_note_rounded),
                activeIcon: Icon(Icons.event_note_rounded),
                label: 'Planner',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_rounded),
                activeIcon: Icon(Icons.insights_rounded),
                label: 'Progress',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
