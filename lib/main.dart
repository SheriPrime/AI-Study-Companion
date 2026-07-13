import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_study_companion/core/theme/app_theme.dart';
import 'package:ai_study_companion/core/router/app_router.dart';
import 'package:ai_study_companion/services/mock_auth_service.dart';
import 'package:ai_study_companion/services/mock_database_service.dart';
import 'package:ai_study_companion/services/mock_gemini_service.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';
import 'package:ai_study_companion/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/notes_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/ai_hub_controller.dart';
import 'package:ai_study_companion/features/planner/controllers/planner_controller.dart';
import 'package:ai_study_companion/features/progress/controllers/progress_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AIStudyCompanionApp());
}

/// Root widget for the AI Study Companion application.
///
/// Sets up all service and controller providers via [MultiProvider],
/// then builds [MaterialApp.router] with the GoRouter configuration.
class AIStudyCompanionApp extends StatelessWidget {
  const AIStudyCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Services ───────────────────────────────────────────────
        Provider<MockAuthService>(
          create: (_) => MockAuthService(),
        ),
        Provider<MockDatabaseService>(
          create: (_) => MockDatabaseService(),
        ),
        Provider<MockGeminiService>(
          create: (_) => MockGeminiService(),
        ),

        // ── Controllers ────────────────────────────────────────────
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(ctx.read<MockAuthService>()),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (ctx) => DashboardController(ctx.read<MockDatabaseService>()),
        ),
        ChangeNotifierProvider<NotesController>(
          create: (ctx) => NotesController(ctx.read<MockDatabaseService>()),
        ),
        ChangeNotifierProvider<AiHubController>(
          create: (ctx) => AiHubController(ctx.read<MockGeminiService>()),
        ),
        ChangeNotifierProvider<PlannerController>(
          create: (ctx) => PlannerController(ctx.read<MockDatabaseService>()),
        ),
        ChangeNotifierProvider<ProgressController>(
          create: (ctx) => ProgressController(ctx.read<MockDatabaseService>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Create the router AFTER providers are available so we can
          // pass the AuthController for redirect & refreshListenable.
          final authController = context.read<AuthController>();
          final router = createRouter(authController);

          return MaterialApp.router(
            title: 'AI Study Companion',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
