import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/enterprise/organization_models.dart';
import 'package:learntz/features/enterprise/organization_providers.dart';
import 'package:learntz/features/enterprise/screens/enterprise_support_screen.dart';
import 'package:learntz/features/enterprise/screens/institutional_billing_screen.dart';

void main() {
  group('Sub-Stage 5 Institutional Billing & Support Models Tests', () {
    test('OrganizationSubscriptionStatus.fromJson parses quotas and plan details', () {
      final json = {
        'has_subscription': true,
        'subscription_id': 'f0000000-0000-0000-0000-000000000001',
        'plan_id': 'school_standard',
        'plan_name': 'Standard School License',
        'tier': 'standard_school',
        'status': 'active',
        'billing_cycle': 'annual',
        'currency': 'TZS',
        'current_price': 3500000,
        'allocated_student_seats': 1000,
        'used_student_seats': 450,
        'allocated_teacher_seats': 60,
        'used_teacher_seats': 32,
        'allocated_storage_gb': 100,
        'used_storage_gb': 18,
        'period_start': '2026-08-01T00:00:00Z',
        'period_end': '2027-08-01T00:00:00Z',
        'tax_id': 'TZ-TIN-987-654-321',
        'sla_response_hours': 24,
      };

      final sub = OrganizationSubscriptionStatus.fromJson(json);
      expect(sub.hasSubscription, isTrue);
      expect(sub.planId, 'school_standard');
      expect(sub.planName, 'Standard School License');
      expect(sub.tier, 'standard_school');
      expect(sub.status, 'active');
      expect(sub.currency, 'TZS');
      expect(sub.currentPrice, 3500000.0);
      expect(sub.allocatedStudentSeats, 1000);
      expect(sub.usedStudentSeats, 450);
      expect(sub.allocatedTeacherSeats, 60);
      expect(sub.usedTeacherSeats, 32);
      expect(sub.allocatedStorageGb, 100);
      expect(sub.usedStorageGb, 18);
      expect(sub.taxId, 'TZ-TIN-987-654-321');
      expect(sub.slaResponseHours, 24);
    });

    test('OrganizationSupportTicket.fromJson parses ticket details and status', () {
      final json = {
        'id': 't0000000-0000-0000-0000-000000000001',
        'ticket_number': 'TICK-20261114-A1B2',
        'subject': 'Curriculum CSV Bulk Import Sync Issue',
        'description': 'Form 4 Physics question bank import stopped at item 85',
        'category': 'curriculum_import',
        'priority': 'urgent',
        'status': 'open',
        'sla_due_at': '2026-11-14T11:00:00Z',
        'created_at': '2026-11-14T10:00:00Z',
        'message_count': 3,
      };

      final ticket = OrganizationSupportTicket.fromJson(json);
      expect(ticket.ticketNumber, 'TICK-20261114-A1B2');
      expect(ticket.subject, contains('Curriculum CSV'));
      expect(ticket.category, 'curriculum_import');
      expect(ticket.priority, 'urgent');
      expect(ticket.status, 'open');
      expect(ticket.messageCount, 3);
      expect(ticket.slaDueAt, isNotNull);
    });
  });

  group('Sub-Stage 5 Institutional Billing & Support UI Widget Tests', () {
    testWidgets('InstitutionalBillingScreen renders quotas, subscription card and SLA info',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'a0000000-0000-0000-0000-000000000005';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'Azania Secondary School',
                slug: 'tz-school-azania',
                type: OrganizationType.school,
              ),
            ),
            organizationSubscriptionStatusProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationSubscriptionStatus(
                hasSubscription: true,
                subscriptionId: 'sub-azania-1',
                planId: 'school_standard',
                planName: 'Standard School License',
                tier: 'standard_school',
                status: 'active',
                billingCycle: 'annual',
                currency: 'TZS',
                currentPrice: 3500000,
                allocatedStudentSeats: 1000,
                usedStudentSeats: 450,
                allocatedTeacherSeats: 60,
                usedTeacherSeats: 32,
                allocatedStorageGb: 100,
                usedStorageGb: 18,
                taxId: 'TZ-TIN-987-654-321',
                slaResponseHours: 24,
              ),
            ),
          ],
          child: const MaterialApp(
            home: InstitutionalBillingScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Azania Secondary School'), findsOneWidget);
      expect(find.text('Enterprise Subscription'), findsOneWidget);
      expect(find.text('Standard School License'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('TZS 3500000'), findsOneWidget);
      expect(find.text('24h Response Time'), findsOneWidget);
      expect(find.text('Student Seats'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
      expect(find.text('Teacher Faculty Seats'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('Storage Capacity'), findsOneWidget);
      expect(find.text('TZ-TIN-987-654-321'), findsOneWidget);
    });

    testWidgets('EnterpriseSupportScreen renders tickets and opens create ticket modal',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testOrgId = 'a0000000-0000-0000-0000-000000000005';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            organizationDetailsProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationDetails(
                id: testOrgId,
                countryCode: 'TZ',
                name: 'Azania Secondary School',
                slug: 'tz-school-azania',
                type: OrganizationType.school,
              ),
            ),
            organizationSubscriptionStatusProvider(testOrgId).overrideWith(
              (ref) async => const OrganizationSubscriptionStatus(
                hasSubscription: true,
                planId: 'school_standard',
                planName: 'Standard School License',
                tier: 'standard_school',
                status: 'active',
                allocatedStudentSeats: 1000,
                usedStudentSeats: 450,
                allocatedTeacherSeats: 60,
                usedTeacherSeats: 32,
                allocatedStorageGb: 100,
                usedStorageGb: 18,
                slaResponseHours: 24,
              ),
            ),
            organizationSupportTicketsProvider(testOrgId).overrideWith(
              (ref) async => [
                const OrganizationSupportTicket(
                  id: 't1',
                  ticketNumber: 'TICK-20261114-A1B2',
                  subject: 'Curriculum CSV Bulk Import Sync Issue',
                  description: 'Form 4 Physics question bank import stopped at item 85',
                  category: 'curriculum_import',
                  priority: 'urgent',
                  status: 'open',
                  messageCount: 2,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: EnterpriseSupportScreen(orgId: testOrgId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Azania Secondary School'), findsOneWidget);
      expect(find.text('SLA: 24h Guaranteed'), findsOneWidget);
      expect(find.text('TICK-20261114-A1B2'), findsOneWidget);
      expect(find.text('Curriculum CSV Bulk Import Sync Issue'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);

      // Tap Open New Ticket button
      await tester.tap(find.byKey(const Key('open-new-ticket-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Open Enterprise Support Ticket'), findsOneWidget);
      expect(find.byKey(const Key('ticket-subject-field')), findsOneWidget);
      expect(find.byKey(const Key('ticket-desc-field')), findsOneWidget);
      expect(find.byKey(const Key('confirm-create-ticket-btn')), findsOneWidget);
    });
  });
}
