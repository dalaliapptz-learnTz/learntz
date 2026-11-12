import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learners/learner_providers.dart';
import 'package:learntz/features/learners/learner_screens.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';

EducationCatalog createRegionalCatalog() {
  return const EducationCatalog(
    countries: [
      EducationCountry(code: 'TZ', name: 'Tanzania'),
      EducationCountry(code: 'KE', name: 'Kenya'),
      EducationCountry(code: 'UG', name: 'Uganda'),
    ],
    systems: [
      EducationSystem(
        id: 'tz-sys-id',
        countryCode: 'TZ',
        name: 'Tanzania National Education System',
      ),
      EducationSystem(
        id: 'ke-sys-id',
        countryCode: 'KE',
        name: 'Kenya Competency Based Curriculum System',
      ),
      EducationSystem(
        id: 'ug-sys-id',
        countryCode: 'UG',
        name: 'Uganda National Education System',
      ),
    ],
    curricula: [
      Curriculum(
        id: 'tz-curr-id',
        countryCode: 'TZ',
        educationSystemId: 'tz-sys-id',
        name: 'Tanzania Institute of Education',
        code: 'TIE',
      ),
      Curriculum(
        id: 'ke-curr-id',
        countryCode: 'KE',
        educationSystemId: 'ke-sys-id',
        name: 'Competency Based Curriculum',
        code: 'CBC',
      ),
      Curriculum(
        id: 'ug-curr-id',
        countryCode: 'UG',
        educationSystemId: 'ug-sys-id',
        name: 'Uganda National Curriculum',
        code: 'NCDC_CURRICULUM',
      ),
    ],
    levels: [
      // Kenya levels
      EducationLevel(
        id: 'ke-lvl-pre',
        curriculumId: 'ke-curr-id',
        name: 'Pre-Primary education',
        code: 'PRE_PRIMARY',
        sequence: 1,
      ),
      EducationLevel(
        id: 'ke-lvl-pri',
        curriculumId: 'ke-curr-id',
        name: 'Primary education',
        code: 'PRIMARY',
        sequence: 2,
      ),
      EducationLevel(
        id: 'ke-lvl-jss',
        curriculumId: 'ke-curr-id',
        name: 'Junior Secondary education',
        code: 'JUNIOR_SECONDARY',
        sequence: 3,
      ),
      EducationLevel(
        id: 'ke-lvl-sss',
        curriculumId: 'ke-curr-id',
        name: 'Senior Secondary education',
        code: 'SENIOR_SECONDARY',
        sequence: 4,
      ),
      // Uganda levels
      EducationLevel(
        id: 'ug-lvl-pri',
        curriculumId: 'ug-curr-id',
        name: 'Primary education',
        code: 'PRIMARY',
        sequence: 1,
      ),
      EducationLevel(
        id: 'ug-lvl-lsec',
        curriculumId: 'ug-curr-id',
        name: 'Lower Secondary education',
        code: 'LOWER_SECONDARY',
        sequence: 2,
      ),
      EducationLevel(
        id: 'ug-lvl-usec',
        curriculumId: 'ug-curr-id',
        name: 'Upper Secondary education',
        code: 'UPPER_SECONDARY',
        sequence: 3,
      ),
    ],
    grades: [
      // Kenya grades
      EducationGrade(
        id: 'ke-grd-pp1',
        educationLevelId: 'ke-lvl-pre',
        curriculumId: 'ke-curr-id',
        name: 'Pre-Primary 1',
        code: 'PP1',
        sequence: 1,
      ),
      EducationGrade(
        id: 'ke-grd-g6',
        educationLevelId: 'ke-lvl-pri',
        curriculumId: 'ke-curr-id',
        name: 'Grade 6',
        code: 'GRADE_6',
        sequence: 6,
      ),
      EducationGrade(
        id: 'ke-grd-g7',
        educationLevelId: 'ke-lvl-jss',
        curriculumId: 'ke-curr-id',
        name: 'Grade 7',
        code: 'GRADE_7',
        sequence: 1,
      ),
      EducationGrade(
        id: 'ke-grd-g8',
        educationLevelId: 'ke-lvl-jss',
        curriculumId: 'ke-curr-id',
        name: 'Grade 8',
        code: 'GRADE_8',
        sequence: 2,
      ),
      EducationGrade(
        id: 'ke-grd-g9',
        educationLevelId: 'ke-lvl-jss',
        curriculumId: 'ke-curr-id',
        name: 'Grade 9',
        code: 'GRADE_9',
        sequence: 3,
      ),
      EducationGrade(
        id: 'ke-grd-g10',
        educationLevelId: 'ke-lvl-sss',
        curriculumId: 'ke-curr-id',
        name: 'Grade 10',
        code: 'GRADE_10',
        sequence: 1,
      ),
      // Uganda grades
      EducationGrade(
        id: 'ug-grd-p7',
        educationLevelId: 'ug-lvl-pri',
        curriculumId: 'ug-curr-id',
        name: 'Primary 7',
        code: 'P7',
        sequence: 7,
      ),
      EducationGrade(
        id: 'ug-grd-s1',
        educationLevelId: 'ug-lvl-lsec',
        curriculumId: 'ug-curr-id',
        name: 'Senior 1',
        code: 'S1',
        sequence: 1,
      ),
      EducationGrade(
        id: 'ug-grd-s2',
        educationLevelId: 'ug-lvl-lsec',
        curriculumId: 'ug-curr-id',
        name: 'Senior 2',
        code: 'S2',
        sequence: 2,
      ),
      EducationGrade(
        id: 'ug-grd-s4',
        educationLevelId: 'ug-lvl-lsec',
        curriculumId: 'ug-curr-id',
        name: 'Senior 4',
        code: 'S4',
        sequence: 4,
      ),
      EducationGrade(
        id: 'ug-grd-s5',
        educationLevelId: 'ug-lvl-usec',
        curriculumId: 'ug-curr-id',
        name: 'Senior 5',
        code: 'S5',
        sequence: 1,
      ),
    ],
    schools: [],
  );
}

void main() {
  group('TASK-601: Kenya CBC & EducationCatalog Filtering', () {
    final catalog = createRegionalCatalog();

    test('catalog correctly isolates Kenya education systems', () {
      final keSystems = catalog.systemsForCountry('KE');
      expect(keSystems.length, 1);
      expect(keSystems.first.name, 'Kenya Competency Based Curriculum System');
      expect(keSystems.first.id, 'ke-sys-id');
    });

    test('catalog isolates CBC curriculum for Kenya system', () {
      final curricula = catalog.curriculaForSystem('ke-sys-id');
      expect(curricula.length, 1);
      expect(curricula.first.code, 'CBC');
      expect(curricula.first.name, 'Competency Based Curriculum');
    });

    test('catalog returns 4 distinct CBC education levels in sequence', () {
      final levels = catalog.levelsForCurriculum('ke-curr-id');
      expect(levels.map((l) => l.code), [
        'PRE_PRIMARY',
        'PRIMARY',
        'JUNIOR_SECONDARY',
        'SENIOR_SECONDARY',
      ]);
    });

    test('catalog filters grades specifically by CBC level', () {
      final jssGrades = catalog.gradesForLevel('ke-lvl-jss');
      expect(jssGrades.map((g) => g.code), ['GRADE_7', 'GRADE_8', 'GRADE_9']);

      final sssGrades = catalog.gradesForLevel('ke-lvl-sss');
      expect(sssGrades.map((g) => g.code), ['GRADE_10']);
    });
  });

  group('TASK-602: Uganda NCDC & EducationCatalog Filtering', () {
    final catalog = createRegionalCatalog();

    test('catalog correctly isolates Uganda education systems', () {
      final ugSystems = catalog.systemsForCountry('UG');
      expect(ugSystems.length, 1);
      expect(ugSystems.first.name, 'Uganda National Education System');
    });

    test('catalog isolates NCDC curriculum for Uganda system', () {
      final curricula = catalog.curriculaForSystem('ug-sys-id');
      expect(curricula.length, 1);
      expect(curricula.first.code, 'NCDC_CURRICULUM');
    });

    test('catalog returns 3 distinct NCDC levels in sequence', () {
      final levels = catalog.levelsForCurriculum('ug-curr-id');
      expect(levels.map((l) => l.code), [
        'PRIMARY',
        'LOWER_SECONDARY',
        'UPPER_SECONDARY',
      ]);
    });

    test('catalog filters grades specifically by NCDC level', () {
      final lsecGrades = catalog.gradesForLevel('ug-lvl-lsec');
      expect(lsecGrades.map((g) => g.code), ['S1', 'S2', 'S4']);

      final priGrades = catalog.gradesForLevel('ug-lvl-pri');
      expect(priGrades.map((g) => g.code), ['P7']);
    });
  });

  group('LearnerFormScreen Cascading Selection Widget Tests', () {
    final catalog = createRegionalCatalog();

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          educationCatalogProvider.overrideWith((ref) => Future.value(catalog)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnerFormScreen(),
          ),
        ),
      );
    }

    testWidgets('cascading dropdowns populate Kenya CBC structure correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Verify country dropdown contains Kenya
      final countryDropdown = find.byKey(const ValueKey('country-null'));
      expect(countryDropdown, findsOneWidget);

      // Tap country dropdown and select Kenya
      await tester.tap(countryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kenya').last);
      await tester.pumpAndSettle();

      // 2. Verify System dropdown populated with Kenya CBC System
      final systemDropdown = find.byKey(const ValueKey('system-null'));
      expect(systemDropdown, findsOneWidget);

      await tester.tap(systemDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kenya Competency Based Curriculum System').last);
      await tester.pumpAndSettle();

      // 3. Verify Curriculum dropdown populated with CBC
      final curriculumDropdown = find.byKey(const ValueKey('curriculum-null'));
      expect(curriculumDropdown, findsOneWidget);

      await tester.tap(curriculumDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Competency Based Curriculum').last);
      await tester.pumpAndSettle();

      // 4. Verify Education Level dropdown populated with 4 Kenya levels
      final levelDropdown = find.byKey(const ValueKey('level-null'));
      expect(levelDropdown, findsOneWidget);

      await tester.tap(levelDropdown);
      await tester.pumpAndSettle();
      expect(find.text('Pre-Primary education'), findsWidgets);
      expect(find.text('Primary education'), findsWidgets);
      expect(find.text('Junior Secondary education'), findsWidgets);
      expect(find.text('Senior Secondary education'), findsWidgets);

      // Select Junior Secondary
      await tester.tap(find.text('Junior Secondary education').last);
      await tester.pumpAndSettle();

      // 5. Verify Grades dropdown populated with Junior Secondary grades (Grade 7, 8, 9)
      final gradeDropdown = find.byKey(const ValueKey('grade-null'));
      expect(gradeDropdown, findsOneWidget);

      await tester.tap(gradeDropdown);
      await tester.pumpAndSettle();
      expect(find.text('Grade 7'), findsWidgets);
      expect(find.text('Grade 8'), findsWidgets);
      expect(find.text('Grade 9'), findsWidgets);
      expect(find.text('Grade 10'), findsNothing);

      // Select Grade 8
      await tester.tap(find.text('Grade 8').last);
      await tester.pumpAndSettle();

      // 6. Switching country resets subsequent dropdowns
      final selectedCountryDropdown = find.byKey(const ValueKey('country-KE'));
      expect(selectedCountryDropdown, findsOneWidget);

      await tester.tap(selectedCountryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uganda').last);
      await tester.pumpAndSettle();

      // System should now be reset to null and offer Uganda system
      final resetSystemDropdown = find.byKey(const ValueKey('system-null'));
      expect(resetSystemDropdown, findsOneWidget);

      await tester.tap(resetSystemDropdown);
      await tester.pumpAndSettle();
      expect(find.text('Uganda National Education System'), findsWidgets);
      expect(find.text('Kenya Competency Based Curriculum System'), findsNothing);
    });
  });
}
