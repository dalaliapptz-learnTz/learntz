import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/state/app_providers.dart';
import '../../features/about/about_screen.dart';
import '../../features/account/account_screens.dart';
import '../../features/admin/admin_providers.dart';
import '../../features/admin/admin_screens.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/billing/subscription_screen.dart';
import '../../features/country/select_country_screen.dart';
import '../../features/curriculum/curriculum_explorer_screen.dart';
import '../../features/curriculum/curriculum_providers.dart';
import '../../features/curriculum/curriculum_screens.dart';
import '../../features/help/help_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learners/learner_screens.dart';
import '../../features/learning/flashcard_study_screen.dart';
import '../../features/learning/learning_screens.dart';
import '../../features/learning/parent_dashboard_screen.dart';
import '../../features/learning/resource_library_screen.dart';
import '../../features/learning/revision_centre_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../shared/widgets/app_scaffold.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const home = '/home';
  static const about = '/about';
  static const country = '/country';
  static const help = '/help';
  static const signIn = '/sign-in';
  static const signUp = '/register';
  static const verifyEmail = '/verify-email';
  static const authCallback = '/auth/callback';
  static const forgotPassword = '/forgot-password';
  static const passwordRecovery = '/password-recovery';
  static const account = '/account';
  static const editParentProfile = '/account/profile';
  static const accountSettings = '/account/settings';
  static const subscriptions = '/account/subscriptions';
  static const parentDashboard = '/account/parent-dashboard';
  static const curriculumExplorer = '/curriculum/explorer';
  static const learn = '/learn';
  static const revisionCentre = '/learn/revision';
  static String flashcardStudy(String deckId) =>
      '/learn/revision/flashcards/$deckId';
  static const resourceLibrary = '/learn/resources';
  static String lessonReader(String lessonId) => '/learn/lessons/$lessonId';
  static String lessonQuiz(String lessonId) => '/learn/lessons/$lessonId/quiz';
  static const admin = '/admin';
  static const curriculumAdmin = '/admin/curriculum';
  static const addLearner = '/account/learners/add';
  static String learnerProfile(String learnerId) =>
      '/account/learners/$learnerId';
  static String editLearner(String learnerId) =>
      '/account/learners/$learnerId/edit';
}

final _routerAuthListenerProvider = Provider<_RouterAuthListener>((ref) {
  final listener = _RouterAuthListener();
  ref.listen(authStateChangesProvider, (previous, next) {
    listener.refresh();
  });
  ref.listen(passwordRecoveryModeProvider, (previous, next) {
    listener.refresh();
  });
  ref.listen(curriculumStaffCapabilitiesProvider, (previous, next) {
    listener.refresh();
  });
  ref.listen(adminCapabilitiesProvider, (previous, next) {
    listener.refresh();
  });
  ref.onDispose(listener.dispose);
  return listener;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: ref.watch(_routerAuthListenerProvider),
    redirect: (context, state) {
      final path = state.uri.path;
      final client = ref.read(supabaseClientProvider);
      final isSignedIn = client?.auth.currentSession != null;
      final isPasswordRecovery = ref.read(passwordRecoveryModeProvider);

      if (isPasswordRecovery && path != AppRoutes.passwordRecovery) {
        return AppRoutes.passwordRecovery;
      }
      if (path == AppRoutes.passwordRecovery &&
          isSignedIn &&
          !isPasswordRecovery) {
        return AppRoutes.accountSettings;
      }

      final isAdminRoute =
          path == AppRoutes.admin ||
          path == AppRoutes.curriculumAdmin ||
          path.startsWith('/admin/');
      if (isAdminRoute) {
        if (!isSignedIn) {
          return Uri(
            path: AppRoutes.signIn,
            queryParameters: {'next': path},
          ).toString();
        }
        if (path == AppRoutes.curriculumAdmin) {
          final staffCapabilities =
              ref.read(curriculumStaffCapabilitiesProvider).asData?.value;
          if (staffCapabilities != null && !staffCapabilities.canAccess) {
            return AppRoutes.account;
          }
        } else {
          final adminCapabilities =
              ref.read(adminCapabilitiesProvider).asData?.value;
          if (adminCapabilities != null && !adminCapabilities.canAccessAdmin) {
            return AppRoutes.account;
          }
        }
      }

      final isProtected =
          path == AppRoutes.account ||
          path.startsWith('${AppRoutes.account}/') ||
          path == AppRoutes.learn ||
          path.startsWith('${AppRoutes.learn}/');
      if (isProtected && !isSignedIn) {
        return Uri(
          path: AppRoutes.signIn,
          queryParameters: {'next': path},
        ).toString();
      }

      final isAuthenticationRoute = {
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.verifyEmail,
        AppRoutes.authCallback,
        AppRoutes.forgotPassword,
      }.contains(path);
      if (isSignedIn && (isAuthenticationRoute || path == AppRoutes.welcome)) {
        return AppRoutes.account;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.welcome,
            builder: (context, state) => const WelcomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.country,
            builder: (context, state) => const SelectCountryScreen(),
          ),
          GoRoute(
            path: AppRoutes.help,
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: AppRoutes.signIn,
            builder: (context, state) =>
                SignInScreen(next: state.uri.queryParameters['next']),
          ),
          GoRoute(
            path: AppRoutes.signUp,
            builder: (context, state) => const SignUpScreen(),
          ),
          GoRoute(
            path: AppRoutes.verifyEmail,
            builder: (context, state) => EmailVerificationScreen(
              email: state.uri.queryParameters['email'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.authCallback,
            builder: (context, state) => const AuthCallbackScreen(),
          ),
          GoRoute(
            path: AppRoutes.forgotPassword,
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: AppRoutes.passwordRecovery,
            builder: (context, state) => const PasswordRecoveryScreen(),
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: AppRoutes.editParentProfile,
            builder: (context, state) => const EditParentProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountSettings,
            builder: (context, state) => const AccountSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.subscriptions,
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.parentDashboard,
            builder: (context, state) => const ParentDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.curriculumExplorer,
            builder: (context, state) => const CurriculumExplorerScreen(),
          ),
          GoRoute(
            path: AppRoutes.learn,
            builder: (context, state) => const LearningHubScreen(),
          ),
          GoRoute(
            path: AppRoutes.revisionCentre,
            builder: (context, state) => const RevisionCentreScreen(),
          ),
          GoRoute(
            path: '/learn/revision/flashcards/:deckId',
            builder: (context, state) => FlashcardStudyScreen(
              deckId: state.pathParameters['deckId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.resourceLibrary,
            builder: (context, state) => const ResourceLibraryScreen(),
          ),
          GoRoute(
            path: '/learn/lessons/:lessonId',
            builder: (context, state) => LessonReaderScreen(
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
          GoRoute(
            path: '/learn/lessons/:lessonId/quiz',
            builder: (context, state) => PracticeQuizScreen(
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.admin,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.curriculumAdmin,
            builder: (context, state) => const CurriculumAdminScreen(),
          ),
          GoRoute(
            path: AppRoutes.addLearner,
            builder: (context, state) => const LearnerFormScreen(),
          ),
          GoRoute(
            path: '/account/learners/:learnerId',
            builder: (context, state) => LearnerProfileScreen(
              learnerId: state.pathParameters['learnerId']!,
            ),
          ),
          GoRoute(
            path: '/account/learners/:learnerId/edit',
            builder: (context, state) => LearnerFormScreen(
              learnerId: state.pathParameters['learnerId']!,
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _RouterAuthListener extends ChangeNotifier {
  void refresh() => notifyListeners();
}
