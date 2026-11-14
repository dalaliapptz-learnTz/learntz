import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/enterprise/organization_models.dart';
import 'package:learntz/features/enterprise/organization_providers.dart';
import 'package:learntz/features/enterprise/screens/exam_authority_workspace_screen.dart';
import 'package:learntz/features/enterprise/screens/ministry_workspace_screen.dart';
import 'package:learntz/features/enterprise/screens/regional_district_workspace_screen.dart';

void main() {
  group('Sub-Stage 3 Public Sector Workspace Models Tests', () {
    test('MinistryWorkspaceKpis.fromJson parses correctly', () {
      final json = {
        'ministry_org_id': 'a0000000-0000-0000-0000-000000000001',
        'country_code': 'TZ',
        'subordinate_schools_count': 12,
        'registered_learners_count': 5400,
        'active_syllabus_modules_count': 48,
        'recent_schools': [
          {
            'id': 'a0000000-0000-0000-0000-000000000005',
            'name': 'Azania Secondary School',
            'status': 'active',
          }
        ],
      };

      final kpis = MinistryWorkspaceKpis.fromJson(json);
      expect(kpis.ministryOrgId, 'a0000000-0000-0000-0000-000000000001');
      expect(kpis.countryCode, 'TZ');
      expect(kpis.subordinateSchoolsCount, 12);
      expect(kpis.registeredLearnersCount, 5400);
      expect(kpis.activeSyllabusModulesCount, 48);
      expect(kpis.recentSchools.length, 1);
      expect(kpis.recentSchools.first['name'], 'Azania Secondary School');
    });

    test('ExamAuthorityWorkspaceKpis.fromJson parses correctly', () {
      final json = {
        'authority_org_id': 'a0000000-0000-0000-0000-000000000002',
        'authority_code': 'NECTA',
        'country_code': 'TZ',
        'archived_papers_count': 35,
        'approved_questions_count': 420,
        'active_blueprints_count': 8,
        'average_predictive_validity_index': 0.892,
        'recent_papers': [
          {
            'id': 'b0000000-0000-0000-0000-000000000001',
            'title': 'CSEE Mathematics Paper 1',
            'tier': 'national',
            'year': 2025,
            'total_marks': 100,
          }
        ],
      };

      final kpis = ExamAuthorityWorkspaceKpis.fromJson(json);
      expect(kpis.authorityCode, 'NECTA');
      expect(kpis.countryCode, 'TZ');
      expect(kpis.archivedPapersCount, 35);
      expect(kpis.approvedQuestionsCount, 420);
      expect(kpis.activeBlueprintsCount, 8);
      expect(kpis.averagePredictiveValidityIndex, closeTo(0.892, 0.001));
      expect(kpis.recentPapers.length, 1);
    });

    test('GovernanceOfficeWorkspaceKpis.fromJson parses correctly', () {
      final json = {
        'office_org_id': 'a0000000-0000-0000-0000-000000000004',
        'office_name': 'Ilala Municipal District Education Office',
        'office_type': 'district_office',
        'country_code': 'TZ',
        'subordinate_schools_count': 6,
        'total_learners_count': 2700,
        'average_mock_performance_pct': 74.5,
        'schools_in_jurisdiction': [
          {
            'id': 'a0000000-0000-0000-0000-000000000005',
            'name': 'Azania Secondary School',
            'slug': 'tz-school-azania',
            'status': 'active',
          }
        ],
      };

      final kpis = GovernanceOfficeWorkspaceKpis.fromJson(json);
      expect(kpis.officeName, contains('Ilala Municipal'));
      expect(kpis.officeType, 'district_office');
      expect(kpis.subordinateSchoolsCount, 6);
      expect(kpis.totalLearnersCount, 2700);
      expect(kpis.averageMockPerformancePct, 74.5);
      expect(kpis.schoolsInJurisdiction.length, 1);
    });
  });

  group('Sub-Stage 3 Public Sector Workspaces UI Widget Tests', () {
    testWidgets('MinistryWorkspaceScreen renders KPIs and school hierarchy',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'a0000000-0000-0000-0000-000000000001';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'Ministry of Education, Science and Technology',
                slug: 'tz-moest',
                type: OrganizationType.ministry,
              ),
            ),
            ministryWorkspaceKpisProvider(testOrgId).overrideWith(
              (ref) async => const MinistryWorkspaceKpis(
                ministryOrgId: testOrgId,
                countryCode: 'TZ',
                subordinateSchoolsCount: 14,
                registeredLearnersCount: 6300,
                activeSyllabusModulesCount: 52,
                recentSchools: [
                  {
                    'id': 's1',
                    'name': 'Azania Secondary School',
                    'status': 'active',
                  }
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: MinistryWorkspaceScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ministry of Education, Science and Technology'),
          findsOneWidget);
      expect(find.text('National Apex Entity'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('6300'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);
      expect(find.text('Azania Secondary School'), findsOneWidget);
    });

    testWidgets('ExamAuthorityWorkspaceScreen renders KPIs and assessment papers',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'a0000000-0000-0000-0000-000000000002';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'National Examinations Council of Tanzania (NECTA)',
                slug: 'tz-necta',
                type: OrganizationType.examinationAuthority,
              ),
            ),
            examAuthorityWorkspaceKpisProvider(testOrgId).overrideWith(
              (ref) async => const ExamAuthorityWorkspaceKpis(
                authorityOrgId: testOrgId,
                authorityCode: 'NECTA',
                countryCode: 'TZ',
                archivedPapersCount: 42,
                approvedQuestionsCount: 512,
                activeBlueprintsCount: 10,
                averagePredictiveValidityIndex: 0.915,
                recentPapers: [
                  {
                    'id': 'p1',
                    'title': 'CSEE Mathematics 2025 Paper 1',
                    'tier': 'national',
                    'year': 2025,
                    'total_marks': 100,
                  }
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: ExamAuthorityWorkspaceScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text('National Examinations Council of Tanzania (NECTA)'),
          findsOneWidget);
      expect(find.text('Standardized Assessment'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('512'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('91.5%'), findsOneWidget);
      expect(find.text('CSEE Mathematics 2025 Paper 1'), findsOneWidget);
    });

    testWidgets('RegionalDistrictWorkspaceScreen renders jurisdiction schools',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'a0000000-0000-0000-0000-000000000004';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'Ilala Municipal District Education Office',
                slug: 'tz-district-ilala',
                type: OrganizationType.districtOffice,
              ),
            ),
            governanceOfficeWorkspaceKpisProvider(testOrgId).overrideWith(
              (ref) async => const GovernanceOfficeWorkspaceKpis(
                officeOrgId: testOrgId,
                officeName: 'Ilala Municipal District Education Office',
                officeType: 'district_office',
                countryCode: 'TZ',
                subordinateSchoolsCount: 8,
                totalLearnersCount: 3600,
                averageMockPerformancePct: 76.4,
                schoolsInJurisdiction: [
                  {
                    'id': 'sch1',
                    'name': 'Tambaza High School',
                    'slug': 'tz-school-tambaza',
                    'status': 'active',
                  }
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: RegionalDistrictWorkspaceScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text('Ilala Municipal District Education Office'), findsOneWidget);
      expect(find.text('Local Governance'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('3600'), findsOneWidget);
      expect(find.text('76.4%'), findsOneWidget);
      expect(find.text('Tambaza High School'), findsOneWidget);
    });
  });
}
