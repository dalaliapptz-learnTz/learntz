import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../app/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../data/auth_repository.dart';
import '../models/account_models.dart';

enum AuthStatus { signedOut, loading, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._config);

  final AuthRepository _repository;
  final AppConfig _config;

  AuthStatus status = AuthStatus.signedOut;
  ParentProfile? parent;
  List<LearnerProfile> learners = const [];
  String? errorMessage;

  bool get isSignedIn => status == AuthStatus.signedIn;
  bool get isDemoMode => !_repository.isRemote;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _run(() async {
      final userId = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      parent = ParentProfile(id: userId, fullName: fullName.trim(), email: email.trim());
      learners = const [];
      status = AuthStatus.signedIn;
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await _run(() async {
      final userId = await _repository.signIn(email: email, password: password);
      parent = ParentProfile(id: userId, fullName: 'LearnTZ parent', email: email.trim());
      status = AuthStatus.signedIn;
    });
  }

  Future<void> signOut() async {
    await _run(() async {
      await _repository.signOut();
      status = AuthStatus.signedOut;
      parent = null;
      learners = const [];
    });
  }

  Future<void> addLearner({
    required String fullName,
    required String grade,
    String? countryCode,
    String? curriculumCode,
    String? curriculum,
    String? educationSystem,
    String? educationLevel,
    String? gradeCode,
  }) async {
    final name = fullName.trim();
    final level = grade.trim();
    if (name.isEmpty || level.isEmpty) {
      errorMessage = 'Enter the learner name and grade or form.';
      notifyListeners();
      return;
    }
    learners = [
      ...learners,
      LearnerProfile(
        id: 'learner-${DateTime.now().microsecondsSinceEpoch}',
        fullName: name,
        grade: level,
        countryCode: countryCode ?? _config.countryCode,
        curriculum: curriculum ?? 'Default curriculum',
        curriculumCode: curriculumCode ?? '',
        educationSystem: educationSystem ?? '',
        educationLevel: educationLevel ?? '',
        gradeCode: gradeCode ?? '',
      ),
    ];
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() operation) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
    } on AppError catch (error) {
      errorMessage = error.message;
      if (status == AuthStatus.loading) status = AuthStatus.signedOut;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      if (status == AuthStatus.loading) status = AuthStatus.signedOut;
    }
    notifyListeners();
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthController(createAuthRepository(config), config);
});
