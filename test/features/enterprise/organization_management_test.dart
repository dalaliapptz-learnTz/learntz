import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/enterprise/organization_models.dart';
import 'package:learntz/features/enterprise/organization_providers.dart';
import 'package:learntz/features/enterprise/screens/organization_directory_screen.dart';
import 'package:learntz/features/enterprise/screens/organization_registration_screen.dart';
import 'package:learntz/features/enterprise/screens/organization_staff_directory_screen.dart';

void main() {
  group('Sub-Stage 1 Organization Models Tests', () {
    test('Organization.fromJson parses JSON correctly', () {
      final json = {
        'id': 'a0000000-0000-0000-0000-000000000001',
        'country_code': 'TZ',
        'name': 'Ministry of Education, Science and Technology (MoEST)',
        'slug': 'tz-moest',
        'type': 'ministry',
        'parent_name': null,
        'status': 'active',
        'brand_color': '#0F4C81',
        'created_at': '2026-11-14T08:00:00Z',
      };

      final org = Organization.fromJson(json);
      expect(org.id, 'a0000000-0000-0000-0000-000000000001');
      expect(org.countryCode, 'TZ');
      expect(org.name, contains('MoEST'));
      expect(org.slug, 'tz-moest');
      expect(org.type, OrganizationType.ministry);
      expect(org.status, OrganizationStatus.active);
      expect(org.brandColor, '#0F4C81');
    });

    test('OrganizationDetails.fromJson parses nested counts and settings', () {
      final json = {
        'id': 'a0000000-0000-0000-0000-000000000001',
        'country_code': 'TZ',
        'name': 'Ministry of Education, Science and Technology',
        'slug': 'tz-moest',
        'type': 'ministry',
        'registration_number': 'TZ-GOV-MOEST',
        'parent_organization_id': null,
        'parent_name': null,
        'parent_slug': null,
        'website_url': 'https://moe.go.tz',
        'contact_email': 'info@moe.go.tz',
        'contact_phone': '+255 26 296 3533',
        'status': 'active',
        'settings': {'sso_enabled': true},
        'direct_children_count': 2,
        'total_descendants_count': 5,
        'created_at': '2026-11-14T08:00:00Z',
      };

      final details = OrganizationDetails.fromJson(json);
      expect(details.directChildrenCount, 2);
      expect(details.totalDescendantsCount, 5);
      expect(details.settings['sso_enabled'], isTrue);
      expect(details.websiteUrl, 'https://moe.go.tz');
    });

    test('SubordinateOrganizationItem.fromJson parses depth and hierarchy', () {
      final json = {
        'id': 'a0000000-0000-0000-0000-000000000005',
        'name': 'Azania Secondary School',
        'slug': 'tz-school-azania',
        'type': 'school',
        'depth': 3,
        'parent_id': 'a0000000-0000-0000-0000-000000000004',
        'status': 'active',
      };

      final item = SubordinateOrganizationItem.fromJson(json);
      expect(item.name, 'Azania Secondary School');
      expect(item.type, OrganizationType.school);
      expect(item.depth, 3);
      expect(item.parentId, 'a0000000-0000-0000-0000-000000000004');
    });
  });

  group('OrganizationDirectoryScreen Widget Tests', () {
    final sampleOrganizations = [
      const Organization(
        id: 'org-1',
        countryCode: 'TZ',
        name: 'Ministry of Education, Science and Technology',
        slug: 'tz-moest',
        type: OrganizationType.ministry,
        status: OrganizationStatus.active,
      ),
      const Organization(
        id: 'org-2',
        countryCode: 'TZ',
        name: 'Dar es Salaam Regional Education Office',
        slug: 'tz-reo-dar',
        type: OrganizationType.regionalOffice,
        parentName: 'Ministry of Education, Science and Technology',
        status: OrganizationStatus.active,
      ),
    ];

    const sampleDetails = OrganizationDetails(
      id: 'org-1',
      countryCode: 'TZ',
      name: 'Ministry of Education, Science and Technology',
      slug: 'tz-moest',
      type: OrganizationType.ministry,
      directChildrenCount: 1,
      totalDescendantsCount: 4,
    );

    final sampleSubordinates = [
      const SubordinateOrganizationItem(
        id: 'org-1',
        name: 'Ministry of Education, Science and Technology',
        slug: 'tz-moest',
        type: OrganizationType.ministry,
        depth: 0,
      ),
      const SubordinateOrganizationItem(
        id: 'org-2',
        name: 'Dar es Salaam Regional Education Office',
        slug: 'tz-reo-dar',
        type: OrganizationType.regionalOffice,
        depth: 1,
      ),
    ];

    testWidgets('renders directory header, filters, and organization cards',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationsListProvider.overrideWith(
              (ref) async => sampleOrganizations,
            ),
            organizationDetailsProvider('org-1').overrideWith(
              (ref) async => sampleDetails,
            ),
            subordinateOrganizationsProvider((orgId: 'org-1', type: null))
                .overrideWith((ref) async => sampleSubordinates),
          ],
          child: const MaterialApp(
            home: OrganizationDirectoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and subtitle
      expect(find.text('Enterprise Institutional Directory'), findsOneWidget);
      expect(
        find.textContaining('Multi-tenant governance connecting Ministries'),
        findsOneWidget,
      );

      // Register button
      expect(find.byKey(const Key('register-organization-btn')), findsOneWidget);

      // Filter chips
      expect(find.text('All Countries'), findsOneWidget);
      expect(find.text('🇹🇿 Tanzania'), findsOneWidget);
      expect(find.text('🇰🇪 Kenya'), findsOneWidget);
      expect(find.text('🇺🇬 Uganda'), findsOneWidget);

      // Organization cards
      expect(
        find.text('Ministry of Education, Science and Technology'),
        findsOneWidget,
      );
      expect(
        find.text('Dar es Salaam Regional Education Office'),
        findsOneWidget,
      );
      expect(find.text('Parent Body: Ministry of Education, Science and Technology'), findsOneWidget);

      // Tap Hierarchy on org-1
      final hierarchyBtn = find.text('Hierarchy').first;
      await tester.tap(hierarchyBtn);
      await tester.pumpAndSettle();

      // Bottom sheet shows stats and subtree
      expect(find.text('Direct Children'), findsOneWidget);
      expect(find.text('Total Descendants'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Nested Hierarchy Subtree:'), findsOneWidget);
      expect(find.textContaining('(Regional Office)'), findsOneWidget);
    });
  });

  group('OrganizationRegistrationScreen Widget Tests', () {
    testWidgets('renders onboarding form fields and responds to input',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OrganizationRegistrationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title
      expect(find.text('Institutional Onboarding'), findsOneWidget);
      expect(find.text('1. Jurisdiction & Entity Type'), findsOneWidget);
      expect(find.text('2. Identity & Official Profile'), findsOneWidget);
      expect(find.text('3. Contact & Digital Channels'), findsOneWidget);

      // Input fields
      expect(find.byKey(const Key('org-name-field')), findsOneWidget);
      expect(find.byKey(const Key('org-slug-field')), findsOneWidget);
      expect(find.byKey(const Key('org-reg-field')), findsOneWidget);
      expect(find.byKey(const Key('org-email-field')), findsOneWidget);
      expect(find.byKey(const Key('submit-org-registration-btn')), findsOneWidget);

      // Enter organization name
      await tester.enterText(
        find.byKey(const Key('org-name-field')),
        'Aga Khan Education Service',
      );
      await tester.pumpAndSettle();

      // Auto-slug generated
      expect(find.text('aga-khan-education-service'), findsOneWidget);
    });
  });

  group('Sub-Stage 2 Institutional RBAC Models & Widget Tests', () {
    test('InstitutionalMember.fromJson parses staff record correctly', () {
      final json = {
        'membership_id': 'mem-101',
        'user_id': 'user-201',
        'full_name': 'Dr. Mkwawa Principal',
        'email': 'principal@azania.ac.tz',
        'role': 'school_principal',
        'job_title': 'Head of School',
        'department': 'Administration',
        'status': 'active',
        'created_at': '2026-11-14T09:00:00Z',
      };

      final member = InstitutionalMember.fromJson(json);
      expect(member.membershipId, 'mem-101');
      expect(member.userId, 'user-201');
      expect(member.fullName, 'Dr. Mkwawa Principal');
      expect(member.role, InstitutionalRole.schoolPrincipal);
      expect(member.jobTitle, 'Head of School');
      expect(member.department, 'Administration');
      expect(member.status, 'active');
    });

    test('UserWorkspace.fromJson parses workspace metadata correctly', () {
      final json = {
        'organization_id': 'org-501',
        'name': 'Azania Secondary School',
        'slug': 'tz-school-azania',
        'type': 'school',
        'country_code': 'TZ',
        'brand_color': '#0F4C81',
        'role': 'teacher',
        'job_title': 'Physics & Math Instructor',
        'department': 'Science',
      };

      final ws = UserWorkspace.fromJson(json);
      expect(ws.organizationId, 'org-501');
      expect(ws.name, 'Azania Secondary School');
      expect(ws.slug, 'tz-school-azania');
      expect(ws.type, OrganizationType.school);
      expect(ws.role, InstitutionalRole.teacher);
      expect(ws.jobTitle, 'Physics & Math Instructor');
    });

    final sampleMembers = [
      const InstitutionalMember(
        membershipId: 'mem-1',
        userId: 'user-1',
        fullName: 'Dr. Mkwawa Principal',
        email: 'principal@azania.ac.tz',
        role: InstitutionalRole.schoolPrincipal,
        jobTitle: 'Head of School',
        department: 'Executive Administration',
      ),
      const InstitutionalMember(
        membershipId: 'mem-2',
        userId: 'user-2',
        fullName: 'Prof. Mary Nyerere',
        email: 'math-hod@azania.ac.tz',
        role: InstitutionalRole.headOfDepartment,
        jobTitle: 'Head of Mathematics',
        department: 'Science & STEM',
      ),
    ];

    const sampleOrgDetails = OrganizationDetails(
      id: 'org-test',
      countryCode: 'TZ',
      name: 'Azania Secondary School',
      slug: 'tz-school-azania',
      type: OrganizationType.school,
    );

    testWidgets('renders staff directory header, metrics, member cards, and invite dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider('org-test').overrideWith(
              (ref) async => sampleOrgDetails,
            ),
            organizationMembersProvider('org-test').overrideWith(
              (ref) async => sampleMembers,
            ),
          ],
          child: const MaterialApp(
            home: OrganizationStaffDirectoryScreen(orgId: 'org-test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Azania Secondary School'), findsOneWidget);
      expect(
        find.textContaining('Role-based staff directory, institutional permission management'),
        findsOneWidget,
      );

      // Metrics
      expect(find.text('Total Staff'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Leadership'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // Leadership 1, Educators 1
      expect(find.text('Educators'), findsOneWidget);

      // Member Cards
      expect(find.text('Dr. Mkwawa Principal'), findsOneWidget);
      expect(find.text('Prof. Mary Nyerere'), findsOneWidget);
      expect(find.text('School Principal / Head'), findsOneWidget);
      expect(find.text('Head of Department'), findsOneWidget);
      expect(find.textContaining('Executive Administration'), findsOneWidget);
      expect(find.textContaining('Science & STEM'), findsOneWidget);

      // Open Invite Dialog
      final inviteBtn = find.byKey(const Key('invite-staff-member-btn'));
      expect(inviteBtn, findsOneWidget);
      await tester.tap(inviteBtn);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Invite Institutional Staff'), findsOneWidget);
      expect(find.byKey(const Key('invite-email-field')), findsOneWidget);
      expect(find.byKey(const Key('invite-job-title-field')), findsOneWidget);
      expect(find.byKey(const Key('confirm-invite-btn')), findsOneWidget);
    });
  });
}
