import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/class_detail_screen.dart';
import 'screens/gradebook_screen.dart';
import 'screens/manage_class_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/people_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screens.dart';
import 'screens/student_home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/teacher_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/class_chat_screen.dart';
import 'screens/create_assignment_screen.dart';
import 'screens/student_assignment_screen.dart';
import 'screens/grade_assignment_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appState = AppState();
  final result = await appState.checkAuthState();
  final isLoggedIn = result['isLoggedIn'] as bool;
  final role = result['role'] as String;

  // Mock data for testing (in background to avoid blocking splash/runApp)
  appState.seedMockData().catchError((dynamic e) {
    debugPrint('Error seeding mock data: $e');
  });

  // ✅ Route to teacher or student home based on saved role
  final initialRoute = isLoggedIn
      ? (role == 'teacher' ? '/teacher-home' : '/student-home')
      : '/';

  runApp(EduClassApp(appState: appState, initialRoute: initialRoute));
}

class EduClassApp extends StatelessWidget {
  final AppState appState;
  final String initialRoute;

  const EduClassApp({
    super.key,
    required this.appState,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EduClass',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          initialRoute: initialRoute,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              // ── Entry ──────────────────────────────────────────────
              case '/':
                return MaterialPageRoute(
                    builder: (_) => const WelcomeScreen());

              case '/login':
                return MaterialPageRoute(
                  builder: (_) => AuthScreen(
                    isRegister: false,
                    role: (settings.arguments as String?) ?? 'student',
                  ),
                );

              case '/register':
                return MaterialPageRoute(
                  builder: (_) => AuthScreen(
                    isRegister: true,
                    role: (settings.arguments as String?) ?? 'student',
                  ),
                );

              // ── Role-based Home Screens ──────────────────────────
              case '/teacher-home':
                return MaterialPageRoute(
                    builder: (_) => const TeacherHomeScreen());

              case '/student-home':
                return MaterialPageRoute(
                    builder: (_) => const StudentHomeScreen());

              // Legacy /home → redirect based on role
              case '/home':
                final role = appState.currentUser?.role ?? 'student';
                return MaterialPageRoute(
                    builder: (_) => role == 'teacher'
                        ? const TeacherHomeScreen()
                        : const StudentHomeScreen());

              // ── Shared Screens ───────────────────────────────────
              case '/class':
                return MaterialPageRoute(
                  builder: (_) => ClassDetailScreen(
                      classId: settings.arguments as String),
                );

              case '/people':
                return MaterialPageRoute(
                  builder: (_) =>
                      PeopleScreen(classId: settings.arguments as String),
                );

              case '/chat':
                return MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(classId: settings.arguments as String),
                );

              case '/class-tasks':
                return MaterialPageRoute(
                  builder: (_) =>
                      TasksScreen(classId: settings.arguments as String),
                );

              case '/calendar':
                return MaterialPageRoute(
                    builder: (_) => const CalendarScreen());

              case '/profile':
                return MaterialPageRoute(
                    builder: (_) => const ProfileScreen());

              case '/notifications':
                return MaterialPageRoute(
                    builder: (_) => const NotificationsScreen());

              case '/account-settings':
                return MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen());

              case '/notification-settings':
                return MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen());

              case '/privacy-settings':
                return MaterialPageRoute(
                    builder: (_) => const PrivacySettingsScreen());

              case '/manage-class':
                return MaterialPageRoute(
                  builder: (_) => ManageClassScreen(
                      classId: settings.arguments as String),
                );

              case '/gradebook':
                return MaterialPageRoute(
                  builder: (_) =>
                      GradebookScreen(classId: settings.arguments as String),
                );

              // ── Advanced Tasks Flow ─────────────────────────────────────
              case '/create-assignment':
                return MaterialPageRoute(
                  builder: (_) => CreateAssignmentScreen(
                      classId: settings.arguments as String),
                );
              case '/student-assignment':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => StudentAssignmentScreen(
                      classId: args['classId'] as String,
                      assignmentId: args['assignmentId'] as String),
                );
              case '/grade-assignment':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => GradeAssignmentScreen(
                      classId: args['classId'] as String,
                      assignmentId: args['assignmentId'] as String),
                );

              // ── 404 ─────────────────────────────────────────────
              default:
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Page not found: ${settings.name}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
