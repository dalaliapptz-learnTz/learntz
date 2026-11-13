import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/design_system/layouts/layouts.dart';

void main() {
  group('LearnTZ Design System 2.0 Role Layout Shells', () {
    testWidgets('LearnerShell renders bottom nav on mobile and rail on desktop', (tester) async {
      final destinations = [
        const LearnerNavDestination(route: '/learn', label: 'Learn', icon: Icons.school_outlined),
        const LearnerNavDestination(route: '/revision', label: 'Revision', icon: Icons.quiz_outlined),
      ];

      // Mobile test
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: LearnerShell(
            currentPath: '/learn',
            destinations: destinations,
            onNavigate: (_) {},
            streakDays: 5,
            learnerName: 'Amina',
            child: const Text('Learner Mobile View'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('5 Days'), findsOneWidget);
      expect(find.text('Learner Mobile View'), findsOneWidget);

      // Desktop test
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: LearnerShell(
            currentPath: '/learn',
            destinations: destinations,
            onNavigate: (_) {},
            streakDays: 5,
            learnerName: 'Amina',
            child: const Text('Learner Desktop View'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Learner Desktop View'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('ParentShell displays child switcher and destinations', (tester) async {
      final destinations = [
        const ParentNavDestination(route: '/overview', label: 'Overview', icon: Icons.dashboard_outlined),
        const ParentNavDestination(route: '/learners', label: 'Learners', icon: Icons.people_outline),
      ];
      final children = [
        const ChildSelectorOption(id: 'c1', fullName: 'Baraka', gradeLevel: 'Std 4'),
        const ChildSelectorOption(id: 'c2', fullName: 'Fatma', gradeLevel: 'Std 7'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ParentShell(
            currentPath: '/overview',
            destinations: destinations,
            children: children,
            selectedChildId: 'c1',
            onNavigate: (_) {},
            child: const Text('Parent Cockpit Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Baraka (Std 4)'), findsOneWidget);
      expect(find.text('Parent Cockpit Content'), findsOneWidget);
    });

    testWidgets('AdminPortalShell displays sidebar, breadcrumbs, and role badge', (tester) async {
      final groups = [
        const AdminNavGroup(
          title: 'Management',
          items: [
            AdminNavItem(route: '/admin', label: 'Overview', icon: Icons.insights_outlined),
            AdminNavItem(route: '/admin/curriculum', label: 'Curriculum', icon: Icons.book_outlined),
          ],
        ),
      ];

      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPortalShell(
            currentPath: '/admin/curriculum',
            groups: groups,
            roleBadge: 'Super Admin',
            staffEmail: 'admin@learntz.com',
            breadcrumbs: const ['Portal', 'Curriculum', 'Sources'],
            onNavigate: (_) {},
            child: const Text('Admin Main View'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('admin@learntz.com'), findsOneWidget);
      expect(find.text('Curriculum'), findsAtLeast(1));
      expect(find.text('Admin Main View'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
