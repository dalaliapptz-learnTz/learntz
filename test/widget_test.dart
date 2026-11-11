import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/app.dart';
import 'package:learntz/core/config/country_configuration.dart';
import 'package:learntz/core/routing/app_router.dart';
import 'package:learntz/core/state/app_providers.dart';

const _testCountry = CountryConfiguration(
  countryCode: 'KE',
  displayName: 'Kenya',
  productName: 'LearnKE',
  primaryBrandColor: 0xFF6A1B9A,
  accentBrandColor: 0xFFEF6C00,
  currencyCode: 'KES',
  educationSystem: 'Configured curriculum',
  supportedLanguageCodes: ['en'],
  isDefault: false,
);

class _TestCountryNotifier extends SelectedCountryNotifier {
  @override
  CountryConfiguration build() => _testCountry;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('welcome navigates to home and country selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const ProviderScope(child: LearnTzApp()));
    await tester.pumpAndSettle();

    expect(find.text('Learning that moves with your child.'), findsOneWidget);

    await tester.tap(find.text('Explore LearnTZ'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to LearnTZ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-/country')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Country options require the LearnTZ database to be configured and available.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('language menu switches the app to Kiswahili', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LearnTzApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Change language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiswahili'));
    await tester.pumpAndSettle();

    expect(find.text('Elimu inayosonga pamoja na mtoto wako.'), findsOneWidget);
    expect(find.text('Karibu'), findsOneWidget);
  });

  testWidgets('wide layout uses the top navigation without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const ProviderScope(child: LearnTzApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('nav-/about')), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('unauthenticated users are redirected from account routes', (
    tester,
  ) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LearnTzApp(),
      ),
    );
    container.read(appRouterProvider).go(AppRoutes.account);
    await tester.pumpAndSettle();

    expect(find.text('Authentication is not connected'), findsOneWidget);
    expect(find.text('Parent dashboard'), findsNothing);
    expect(tester.takeException(), isNull);

    container.dispose();
  });

  testWidgets('selected country drives product name and brand palette', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedCountryProvider.overrideWith(_TestCountryNotifier.new),
        ],
        child: const LearnTzApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LearnKE'), findsOneWidget);
    expect(find.text('Explore LearnKE'), findsOneWidget);
    expect(find.text('Learning, rooted in Kenya'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, const Color(0xFF6A1B9A));

    await tester.tap(find.text('Explore LearnKE'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to LearnKE'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
