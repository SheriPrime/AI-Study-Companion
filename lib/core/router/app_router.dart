import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';
import 'package:ai_study_companion/features/auth/screens/login_screen.dart';
import 'package:ai_study_companion/features/auth/screens/signup_screen.dart';
import 'package:ai_study_companion/features/dashboard/screens/dashboard_screen.dart';
import 'package:ai_study_companion/features/notes/screens/notes_screen.dart';
import 'package:ai_study_companion/features/notes/screens/note_detail_screen.dart';
import 'package:ai_study_companion/features/planner/screens/planner_screen.dart';
import 'package:ai_study_companion/features/progress/screens/progress_screen.dart';
import 'package:ai_study_companion/features/profile/screens/profile_screen.dart';
import 'package:ai_study_companion/features/shell/shell_screen.dart';
import 'package:ai_study_companion/models/note.dart';

/// Creates and configures the application's [GoRouter].
///
/// The router reacts to [authController] changes via [refreshListenable]
/// and automatically redirects unauthenticated users to the login page.
GoRouter createRouter(AuthController authController) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authController,
    debugLogDiagnostics: false,

    // ── Auth redirect ────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authController.isLoggedIn;
      final currentPath = state.uri.path;

      final isAuthRoute = currentPath == '/login' || currentPath == '/signup';

      // Not logged in and trying to access protected route → login.
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Already logged in but on auth page → dashboard.
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null; // No redirect needed.
    },

    // ── Routes ───────────────────────────────────────────────────────
    routes: [
      // Auth routes (no shell / bottom nav)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Main app with bottom navigation shell
      ShellRoute(
        builder: (context, state, child) {
          return ShellScreen(
            state: state,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
            routes: [
              GoRoute(
                path: ':noteId',
                builder: (context, state) {
                  final noteId = state.pathParameters['noteId']!;
                  final note = state.extra as Note?;
                  return NoteDetailScreen(noteId: noteId, note: note);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/planner',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],

    // ── Error / 404 page ─────────────────────────────────────────────
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                '404',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
