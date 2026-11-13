import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/design_system/components/components.dart';
import 'package:learntz/core/design_system/tokens/design_tokens.dart';

void main() {
  group('LearnTZ Design System 2.0 Shared Components', () {
    testWidgets('AppBrandLogo renders logo and country badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBrandLogo(
              height: 40,
              countryBadge: 'TZ',
              showTagline: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TZ'), findsOneWidget);
      expect(find.text('Learn Anywhere, Anytime'), findsOneWidget);
    });

    testWidgets('AppButton renders variants, sizes, and loading state', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: 'Primary Button',
                  icon: Icons.check,
                  onPressed: () => tapped = true,
                ),
                const AppButton(
                  label: 'Loading Button',
                  isLoading: true,
                  onPressed: null,
                ),
                AppButton(
                  label: 'Secondary Button',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Outlined Button',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.md,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Destructive Button',
                  variant: AppButtonVariant.destructive,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Primary Button'));
      expect(tapped, isTrue);
    });

    testWidgets('AppIconButton enforces 48dp touch target and tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppIconButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                size: 32.0,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.renderObject<RenderBox>(find.byType(AppIconButton));
      expect(box.size.width >= LearnTzSpacing.mobileMinTouchTarget, isTrue);
      expect(box.size.height >= LearnTzSpacing.mobileMinTouchTarget, isTrue);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('AppTextField renders label and toggles password visibility', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppTextField(
                label: 'Password',
                hint: 'Enter your secret',
                controller: controller,
                isPassword: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Enter your secret'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('AppCard renders child and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              variant: AppCardVariant.interactive,
              onTap: () => tapped = true,
              child: const Text('Interactive Card Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Interactive Card Content'), findsOneWidget);
      await tester.tap(find.text('Interactive Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppBadge renders labels across variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AppBadge(label: 'Success Badge', variant: AppBadgeVariant.success),
                AppBadge(label: 'Warning Badge', variant: AppBadgeVariant.warning),
                AppBadge(label: 'Error Badge', variant: AppBadgeVariant.error),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Success Badge'), findsOneWidget);
      expect(find.text('Warning Badge'), findsOneWidget);
      expect(find.text('Error Badge'), findsOneWidget);
    });

    testWidgets('AppAvatar renders initials and online status indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              initials: 'TZ',
              size: AppAvatarSize.lg,
              isOnline: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TZ'), findsOneWidget);
    });

    testWidgets('AppStatCard renders metric, label, and trend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStatCard(
              label: 'Completed Lessons',
              value: '42',
              trend: '+15%',
              isTrendPositive: true,
              icon: Icons.auto_stories_outlined,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed Lessons'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+15%'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    });

    testWidgets('AppProgressBar and AppProgressRing render correct progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppProgressBar(
                  value: 0.75,
                  label: 'Mathematics Mastery',
                  showPercentage: true,
                ),
                AppProgressRing(
                  value: 0.85,
                  centerText: '85%',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics Mastery'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('AppEmptyState displays placeholder and action', (tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Active Assignments',
              message: 'Check back later for newly assigned practice tests.',
              actionLabel: 'Refresh',
              onAction: () => actionClicked = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Assignments'), findsOneWidget);
      expect(find.text('Check back later for newly assigned practice tests.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionClicked, isTrue);
    });

    testWidgets('AppDialog renders modal dialog and actions', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.show(
                      context: context,
                      title: 'Confirm Submission',
                      description: 'Are you sure you want to finish the exam?',
                      confirmLabel: 'Submit Now',
                      onConfirm: () {
                        confirmed = true;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Submission'), findsOneWidget);
      expect(find.text('Are you sure you want to finish the exam?'), findsOneWidget);
      expect(find.text('Submit Now'), findsOneWidget);

      await tester.tap(find.text('Submit Now'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });
  });
}
