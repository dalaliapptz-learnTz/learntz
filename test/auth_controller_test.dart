import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/app/config/app_config.dart';
import 'package:learntz/features/auth/data/auth_repository.dart';
import 'package:learntz/features/auth/state/auth_controller.dart';

void main() {
  const config = AppConfig(
    productName: 'LearnTZ',
    countryCode: 'TZ',
    supabaseUrl: '',
    supabaseAnonKey: '',
  );

  test('parent can register, sign out, and sign in again', () async {
    final controller = AuthController(LocalAuthRepository(), config);

    await controller.register(
      fullName: 'Amina Hassan',
      email: 'amina@example.com',
      password: 'secret123',
    );
    expect(controller.isSignedIn, isTrue);
    expect(controller.parent?.fullName, 'Amina Hassan');

    await controller.signOut();
    expect(controller.isSignedIn, isFalse);

    await controller.signIn(email: 'amina@example.com', password: 'secret123');
    expect(controller.isSignedIn, isTrue);
  });

  test('parent can add more than one pupil', () async {
    final controller = AuthController(LocalAuthRepository(), config);
    await controller.register(
      fullName: 'Parent User',
      email: 'parent@example.com',
      password: 'secret123',
    );

    await controller.addLearner(fullName: 'Juma', grade: 'Standard 4');
    await controller.addLearner(fullName: 'Neema', grade: 'Form 1');

    expect(controller.learners, hasLength(2));
    expect(controller.learners.map((learner) => learner.fullName), containsAll(<String>['Juma', 'Neema']));
  });
}
