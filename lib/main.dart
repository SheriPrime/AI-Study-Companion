import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_study_companion/core/theme/app_theme.dart';
import 'package:ai_study_companion/core/router/app_router.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/services/firebase_auth_service.dart';
import 'package:ai_study_companion/services/firestore_service.dart';
import 'package:ai_study_companion/services/local_file_service.dart';
import 'package:ai_study_companion/services/gemini_service.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';
import 'package:ai_study_companion/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/notes_controller.dart';
import 'package:ai_study_companion/features/notes/controllers/ai_hub_controller.dart';
import 'package:ai_study_companion/features/planner/controllers/planner_controller.dart';
import 'package:ai_study_companion/features/progress/controllers/progress_controller.dart';
import 'package:ai_study_companion/features/profile/controllers/profile_controller.dart';
import 'package:ai_study_companion/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase using a default config with placeholders so the app compiles
  // and starts instantly without crashing, even if a user has not set up their
  // local google-services.json file yet.
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "placeholder-api-key-ai-study-companion",
        appId: "1:placeholder:android:123456",
        messagingSenderId: "1234567890",
        projectId: "placeholder-project-id",
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // Initialize the SQLite local database
  await DatabaseHelper.instance.database;

  // Initialize the local notification service
  await NotificationService().init();

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
        Provider<FirebaseAuthService>(
          create: (_) => FirebaseAuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
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
          create: (ctx) => AuthController(ctx.read<FirebaseAuthService>())
            ..checkLoginStatus(),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (ctx) => DashboardController(
            ctx.read<DatabaseHelper>(),
            ctx.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<NotesController>(
          create: (ctx) => NotesController(
            ctx.read<DatabaseHelper>(),
            ctx.read<LocalFileService>(),
            ctx.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<AiHubController>(
          create: (ctx) => AiHubController(
            ctx.read<GeminiService>(),
            ctx.read<LocalFileService>(),
          ),
        ),
        ChangeNotifierProvider<PlannerController>(
          create: (ctx) => PlannerController(ctx.read<FirestoreService>()),
        ),
        ChangeNotifierProvider<ProgressController>(
          create: (ctx) => ProgressController(
            ctx.read<DatabaseHelper>(),
            ctx.read<FirestoreService>(),
          ),
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
