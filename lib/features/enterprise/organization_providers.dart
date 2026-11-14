import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import 'organization_models.dart';
import 'organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrganizationRepository(client);
});

typedef OrganizationFilter = ({
  String? countryCode,
  OrganizationType? type,
  String? search,
  OrganizationStatus? status,
});

class OrganizationFilterNotifier extends Notifier<OrganizationFilter> {
  @override
  OrganizationFilter build() {
    return (
      countryCode: null,
      type: null,
      search: null,
      status: OrganizationStatus.active,
    );
  }

  void setCountry(String? countryCode) {
    state = (
      countryCode: countryCode,
      type: state.type,
      search: state.search,
      status: state.status,
    );
  }

  void setType(OrganizationType? type) {
    state = (
      countryCode: state.countryCode,
      type: type,
      search: state.search,
      status: state.status,
    );
  }

  void setSearch(String? search) {
    state = (
      countryCode: state.countryCode,
      type: state.type,
      search: search,
      status: state.status,
    );
  }

  void setStatus(OrganizationStatus? status) {
    state = (
      countryCode: state.countryCode,
      type: state.type,
      search: state.search,
      status: status,
    );
  }
}

final organizationFilterProvider =
    NotifierProvider<OrganizationFilterNotifier, OrganizationFilter>(
  OrganizationFilterNotifier.new,
);

final organizationsListProvider = FutureProvider<List<Organization>>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  final filter = ref.watch(organizationFilterProvider);

  return repo.listOrganizations(
    countryCode: filter.countryCode,
    type: filter.type,
    search: filter.search,
    status: filter.status,
  );
});

final organizationDetailsProvider =
    FutureProvider.family<OrganizationDetails?, String>((ref, orgId) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getOrganizationDetails(orgId);
});

final subordinateOrganizationsProvider = FutureProvider.family<
    List<SubordinateOrganizationItem>,
    ({String orgId, OrganizationType? type})>((ref, args) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.listSubordinateOrganizations(args.orgId, type: args.type);
});

final userInstitutionalWorkspacesProvider =
    FutureProvider<List<UserWorkspace>>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getUserInstitutionalWorkspaces();
});

final organizationMembersProvider = FutureProvider.family<
    List<InstitutionalMember>, String>((ref, orgId) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.listOrganizationMembers(orgId);
});
