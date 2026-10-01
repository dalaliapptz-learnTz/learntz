import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_placeholder_screen.dart';
import '../../features/home/home_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../shared/widgets/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/auth', builder: (_, _) => const AuthPlaceholderScreen()),
          GoRoute(path: '/auth/login', builder: (_, _) => const PlaceholderScreen(title: 'Login')),
          GoRoute(path: '/auth/register', builder: (_, _) => const PlaceholderScreen(title: 'Registration')),
          GoRoute(path: '/parent', builder: (_, _) => const PlaceholderScreen(title: 'Parent area')),
          GoRoute(path: '/parent/pupils', builder: (_, _) => const PlaceholderScreen(title: 'Pupils')),
          GoRoute(path: '/parent/pupils/add', builder: (_, _) => const PlaceholderScreen(title: 'Add pupil')),
        ],
      ),
    ],
    errorBuilder: (_, state) => PlaceholderScreen(title: 'Page not found: ${state.uri}'),
  );
});
