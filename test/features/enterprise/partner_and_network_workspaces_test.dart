import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/enterprise/organization_models.dart';
import 'package:learntz/features/enterprise/organization_providers.dart';
import 'package:learntz/features/enterprise/screens/development_partner_workspace_screen.dart';
import 'package:learntz/features/enterprise/screens/research_institution_workspace_screen.dart';
import 'package:learntz/features/enterprise/screens/school_network_workspace_screen.dart';

void main() {
  group('Sub-Stage 4 Partner & Network Workspace Models Tests', () {
    test('SchoolNetworkWorkspaceKpis.fromJson parses network metrics and campuses', () {
      final json = {
        'network_org_id': 'd0000000-0000-0000-0000-000000000003',
        'network_name': 'Feza Schools Network',
        'country_code': 'TZ',
        'brand_color': '#059669',
        'campuses_count': 3,
        'total_enrolled_learners': 1860,
        'total_teaching_staff': 114,
        'network_average_performance_pct': 87.2,
        'campuses': [
          {
            'id': 'a0000000-0000-0000-0000-000000000021',
            'name': 'Feza Boys High School',
            'registration_number': 'TZ-SCH-FEZA-BOYS',
            'is_boarding': true,
            'status': 'active',
          }
        ],
      };

      final kpis = SchoolNetworkWorkspaceKpis.fromJson(json);
      expect(kpis.networkName, 'Feza Schools Network');
      expect(kpis.campusesCount, 3);
      expect(kpis.totalEnrolledLearners, 1860);
      expect(kpis.totalTeachingStaff, 114);
      expect(kpis.networkAveragePerformancePct, 87.2);
      expect(kpis.campuses.length, 1);
      expect(kpis.campuses.first['name'], 'Feza Boys High School');
    });

    test('ResearchInstitutionWorkspaceKpis.fromJson parses differential privacy cohorts', () {
      final json = {
        'research_org_id': 'd0000000-0000-0000-0000-000000000002',
        'institution_name': 'East African Institute of Educational Research',
        'country_code': 'TZ',
        'differential_privacy_standard': 'k-anonymity (k>=25)',
        'anonymized_cohorts_count': 24,
        'total_anonymized_observations': 68400,
        'statistical_mastery_index': 0.762,
        'subject_mastery_distribution': [
          {
            'subject': 'Mathematics',
            'cohort_size': 14200,
            'mean_mastery': 0.71,
            'std_dev': 0.14,
          }
        ],
        'available_datasets': [
          {
            'key': 'TZ_2025_CSEE_STEM_ANON',
            'title': 'Tanzania 2025 CSEE Secondary STEM Differential Privacy Cohort',
            'format': 'CSV / JSON',
            'sample_size': 35300,
            'privacy_level': 'k-anonymity-25',
          }
        ],
      };

      final kpis = ResearchInstitutionWorkspaceKpis.fromJson(json);
      expect(kpis.institutionName, contains('East African Institute'));
      expect(kpis.differentialPrivacyStandard, 'k-anonymity (k>=25)');
      expect(kpis.anonymizedCohortsCount, 24);
      expect(kpis.totalAnonymizedObservations, 68400);
      expect(kpis.statisticalMasteryIndex, 0.762);
      expect(kpis.availableDatasets.length, 1);
    });

    test('DevelopmentPartnerWorkspaceKpis.fromJson parses SDG 4 indicators and interventions', () {
      final json = {
        'partner_org_id': 'd0000000-0000-0000-0000-000000000001',
        'partner_name': 'UNICEF East Africa Education Initiative',
        'country_code': 'TZ',
        'supported_schools_count': 42,
        'beneficiary_learners_count': 18900,
        'active_intervention_programs_count': 3,
        'sdg4_benchmarks': {
          'foundational_literacy_rate_pct': 81.2,
          'gender_parity_index': 0.99,
          'stem_female_participation_pct': 51.4,
          'average_study_hours_monthly': 16.8,
        },
        'interventions': [
          {
            'name': 'Rural Girls in STEM Digital Accelerator',
            'target_region': 'Dodoma & Manyara',
            'status': 'active',
            'beneficiaries': 5200,
            'completion_pct': 68.0,
          }
        ],
      };

      final kpis = DevelopmentPartnerWorkspaceKpis.fromJson(json);
      expect(kpis.partnerName, contains('UNICEF'));
      expect(kpis.supportedSchoolsCount, 42);
      expect(kpis.beneficiaryLearnersCount, 18900);
      expect(kpis.sdg4Benchmarks['gender_parity_index'], 0.99);
      expect(kpis.interventions.length, 1);
    });

    test('ResearchExportResult.fromJson parses audit record and download URL', () {
      final json = {
        'export_id': 'e0000000-0000-0000-0000-000000000001',
        'dataset_key': 'TZ_2025_CSEE_STEM_ANON',
        'institution_name': 'East African Institute of Educational Research',
        'exported_at': '2026-11-14T10:00:00Z',
        'privacy_standard': 'Differential Privacy (k >= 25) - ZERO PII EXPOSURE',
        'records_count': 1250,
        'download_url': '/api/research/download/e0000000-0000-0000-0000-000000000001',
      };

      final result = ResearchExportResult.fromJson(json);
      expect(result.datasetKey, 'TZ_2025_CSEE_STEM_ANON');
      expect(result.recordsCount, 1250);
      expect(result.privacyStandard, contains('ZERO PII EXPOSURE'));
      expect(result.downloadUrl, contains('/api/research/download/'));
    });
  });

  group('Sub-Stage 4 Partner & Network Workspaces UI Widget Tests', () {
    testWidgets('SchoolNetworkWorkspaceScreen renders campus hierarchy and metrics',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'd0000000-0000-0000-0000-000000000003';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'Feza Schools Network',
                slug: 'feza-schools-network',
                type: OrganizationType.schoolNetwork,
              ),
            ),
            schoolNetworkWorkspaceKpisProvider(testOrgId).overrideWith(
              (ref) async => const SchoolNetworkWorkspaceKpis(
                networkOrgId: testOrgId,
                networkName: 'Feza Schools Network',
                countryCode: 'TZ',
                campusesCount: 4,
                totalEnrolledLearners: 2480,
                totalTeachingStaff: 152,
                networkAveragePerformancePct: 88.5,
                campuses: [
                  {
                    'id': 'c1',
                    'name': 'Feza Boys High School',
                    'registration_number': 'TZ-SCH-FEZA-BOYS',
                    'is_boarding': true,
                    'status': 'active',
                  }
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: SchoolNetworkWorkspaceScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Feza Schools Network'), findsOneWidget);
      expect(find.text('Independent Multi-Campus Network'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2480'), findsOneWidget);
      expect(find.text('152'), findsOneWidget);
      expect(find.text('88.5%'), findsOneWidget);
      expect(find.text('Feza Boys High School'), findsOneWidget);
    });

    testWidgets('ResearchInstitutionWorkspaceScreen renders datasets and privacy metrics',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'd0000000-0000-0000-0000-000000000002';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'East African Institute of Educational Research',
                slug: 'ea-ier-research',
                type: OrganizationType.researchInstitution,
              ),
            ),
            researchInstitutionWorkspaceKpisProvider(testOrgId).overrideWith(
              (ref) async => const ResearchInstitutionWorkspaceKpis(
                researchOrgId: testOrgId,
                institutionName: 'East African Institute of Educational Research',
                countryCode: 'TZ',
                differentialPrivacyStandard: 'k-anonymity (k>=25)',
                anonymizedCohortsCount: 28,
                totalAnonymizedObservations: 75000,
                statisticalMasteryIndex: 0.784,
                subjectMasteryDistribution: [
                  {
                    'subject': 'Mathematics',
                    'cohort_size': 15000,
                    'mean_mastery': 0.74,
                    'std_dev': 0.12,
                  }
                ],
                availableDatasets: [
                  {
                    'key': 'TZ_2025_CSEE_STEM_ANON',
                    'title': 'Tanzania 2025 CSEE STEM Anonymized Cohort',
                    'format': 'CSV',
                    'sample_size': 35000,
                    'privacy_level': 'k-anonymity-25',
                  }
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: ResearchInstitutionWorkspaceScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text('East African Institute of Educational Research'), findsOneWidget);
      expect(find.text('Differential Privacy (Zero PII)'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('75000'), findsOneWidget);
      expect(find.text('78.4%'), findsOneWidget);
      expect(
          find.text('Tanzania 2025 CSEE STEM Anonymized Cohort'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('DevelopmentPartnerWorkspaceScreen renders SDG 4 indicators and interventions',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'd0000000-0000-0000-0000-000000000001';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'UNICEF East Africa Education Initiative',
                slug: 'unicef-east-africa',
                type: OrganizationType.developmentPartner,
              ),
            ),
            developmentPartnerWorkspaceKpisProvider(testOrgId).overrideWith(
              (ref) async => const DevelopmentPartnerWorkspaceKpis(
                partnerOrgId: testOrgId,
                partnerName: 'UNICEF East Africa Education Initiative',
                countryCode: 'TZ',
                supportedSchoolsCount: 50,
                beneficiaryLearnersCount: 22000,
                activeInterventionProgramsCount: 3,
                sdg4Benchmarks: {
                  'foundational_literacy_rate_pct': 82.5,
                  'gender_parity_index': 1.0,
                  'stem_female_participation_pct': 52.0,
                  'average_study_hours_monthly': 18.2,
                },
                interventions: [
                  {
                    'name': 'Rural Solar Pods Initiative',
                    'target_region': 'Lake Zone',
                    'status': 'active',
                    'beneficiaries': 8500,
                    'completion_pct': 75.0,
                  }
                ],
              ),
            ),
          ],
          child: const MaterialApp(
            home: DevelopmentPartnerWorkspaceScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text('UNICEF East Africa Education Initiative'), findsOneWidget);
      expect(find.text('SDG 4 Education Impact'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('22000'), findsOneWidget);
      expect(find.text('Rural Solar Pods Initiative'), findsOneWidget);
      expect(find.text('75.0% completed'), findsOneWidget);
    });
  });
}
