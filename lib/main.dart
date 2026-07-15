import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_study_companion/core/theme/app_theme.dart';
import 'package:ai_study_companion/core/router/app_router.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/services/local_auth_service.dart';
import 'package:ai_study_companion/services/local_file_service.dart';
import 'package:ai_study_companion/services/gemini_service.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';
import 'package:ai_study_companion/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/notes_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/ai_hub_controller.dart';
import 'package:ai_study_companion/features/planner/controllers/planner_controller.dart';
import 'package:ai_study_companion/features/progress/controllers/progress_controller.dart';
import 'package:ai_study_companion/features/profile/controllers/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize the database
  await DatabaseHelper.instance.database;

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
        Provider<LocalAuthService>(
          create: (_) => LocalAuthService(),
        ),
        Provider<LocalFileService>(
          create: (_) => LocalFileService(),
        ),
        Provider<GeminiService>(
          create: (_) => GeminiService(),
        ),
        Provider<DatabaseHelper>(
          create: (_) => DatabaseHelper.instance,
        ),

        // ── Controllers ────────────────────────────────────────────
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(ctx.read<LocalAuthService>())
            ..checkLoginStatus(),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (ctx) => DashboardController(ctx.read<DatabaseHelper>()),
        ),
        ChangeNotifierProvider<NotesController>(
          create: (ctx) => NotesController(
            ctx.read<DatabaseHelper>(),
            ctx.read<LocalFileService>(),
          ),
        ),
        ChangeNotifierProvider<AiHubController>(
          create: (ctx) => AiHubController(
            ctx.read<GeminiService>(),
            ctx.read<LocalFileService>(),
          ),
        ),
        ChangeNotifierProvider<PlannerController>(
          create: (ctx) => PlannerController(ctx.read<DatabaseHelper>()),
        ),
        ChangeNotifierProvider<ProgressController>(
          create: (ctx) => ProgressController(ctx.read<DatabaseHelper>()),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(),
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
