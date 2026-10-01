import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learntz/app/app.dart';
import 'package:learntz/app/config/app_config.dart';

void main() {
  testWidgets('LearnTZ opens the home shell after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LearnTzApp(config: AppConfig(
      productName: 'LearnTZ',
      countryCode: 'TZ',
      supabaseUrl: '',
      supabaseAnonKey: '',
    ))));
    await tester.pump();
    expect(find.text('LearnTZ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(find.text('Welcome to LearnTZ'), findsOneWidget);
  });
}
