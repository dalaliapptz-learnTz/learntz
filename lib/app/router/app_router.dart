import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_placeholder_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/parent/add_pupil_screen.dart';
import '../../features/parent/parent_dashboard_screen.dart';
import '../../features/parent/pupils_screen.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/content/content_library_screen.dart';
import '../../features/content/learner_selection_screen.dart';
import '../../features/content/lesson_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (_, state) {
      final path = state.uri.path;
      if (path == '/splash') return null;
      if (!auth.isSignedIn && path.startsWith('/parent')) return '/auth';
      if (auth.isSignedIn && path.startsWith('/auth')) return '/parent';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/learn', builder: (_, _) => const LearnerSelectionScreen()),
          GoRoute(
            path: '/learn/:learnerId',
            builder: (_, state) => ContentLibraryScreen(learnerId: state.pathParameters['learnerId']),
          ),
          GoRoute(
            path: '/learn/lesson/:lessonId',
            builder: (_, state) => LessonScreen(
              lessonId: state.pathParameters['lessonId']!,
              learnerId: state.uri.queryParameters['learnerId'],
            ),
          ),
          GoRoute(path: '/auth', builder: (_, _) => const AuthPlaceholderScreen()),
          GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),
          GoRoute(path: '/auth/register', builder: (_, _) => const RegisterScreen()),
          GoRoute(path: '/parent', builder: (_, _) => const ParentDashboardScreen()),
          GoRoute(path: '/parent/pupils', builder: (_, _) => const PupilsScreen()),
          GoRoute(path: '/parent/pupils/add', builder: (_, _) => const AddPupilScreen()),
        ],
      ),
    ],
    errorBuilder: (_, state) => ErrorPage(uri: state.uri.toString()),
  );
});

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.uri});

  final String uri;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Page not found: $uri')));
}
