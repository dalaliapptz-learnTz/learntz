import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../admin/admin_providers.dart';
import '../curriculum/curriculum_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../learners/learner_models.dart';
import '../learners/learner_providers.dart';
import '../auth/auth_screens.dart';
import 'account_providers.dart';
import 'account_repository.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
    final profile = ref.watch(parentProfileProvider);
    final learners = ref.watch(parentLearnersProvider);
    final adminAccess = ref.watch(adminCapabilitiesProvider);
    final curriculumAccess = ref.watch(curriculumStaffCapabilitiesProvider);
    final incomingInvitations = ref.watch(incomingGuardianInvitationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.parentDashboardTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.parentDashboardDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              profile.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => AppCard(
                  child: AuthInlineMessage(
                    message: _accountErrorMessage(error, l10n),
                    isError: true,
                  ),
                ),
                data: (value) => AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(user?.email ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        value.countryCode,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go(AppRoutes.editParentProfile),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.editProfileAction),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.accountSettings),
                icon: const Icon(Icons.settings_outlined),
                label: Text(l10n.accountSettingsAction),
              ),
              if (adminAccess.asData?.value.canAccessAdmin ?? false) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(l10n.adminPortalAction),
                ),
              ],
              if (curriculumAccess.asData?.value.canAccess ?? false) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.curriculumAdmin),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.curriculumAdminTitle),
                ),
              ],
              if (incomingInvitations.asData?.value.isNotEmpty ?? false) ...[
                const SizedBox(height: 20),
                _IncomingInvitationsCard(
                  invitations: incomingInvitations.requireValue,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.learnersSectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.addLearner),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addLearnerAction),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.learnerCount(learners.asData?.value.length ?? 0),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              learners.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => AppCard(
                  child: AuthInlineMessage(
                    message: _accountErrorMessage(error, l10n),
                    isError: true,
                  ),
                ),
                data: (items) => items.isEmpty
                    ? AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.noLearnersTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.noLearnersDescription),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.go(AppRoutes.addLearner),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: Text(l10n.addLearnerAction),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 820
                              ? 3
                              : constraints.maxWidth >= 540
                              ? 2
                              : 1;
                          final cardWidth =
                              (constraints.maxWidth - (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final learner in items)
                                SizedBox(
                                  width: cardWidth,
                                  child: _LearnerCard(
                                    learner: learner,
                                    onSelected: () async {
                                      try {
                                        await ref
                                            .read(
                                              activeLearnerProvider.notifier,
                                            )
                                            .select(learner.id);
                                        if (context.mounted) {
                                          context.go(
                                            AppRoutes.learnerProfile(
                                              learner.id,
                                            ),
                                          );
                                        }
                                      } on PostgrestException {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(l10n.requestFailed),
                                            ),
                                          );
                                        }
                                      } on NotSignedInException {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.signInRequired,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    onEdit: () => context.go(
                                      AppRoutes.editLearner(learner.id),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(authRepositoryProvider)?.signOut();
                    } on AuthException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOutAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnerCard extends ConsumerWidget {
  const _LearnerCard({
    required this.learner,
    required this.onSelected,
    required this.onEdit,
  });

  final Learner learner;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(educationCatalogProvider).asData?.value;
    final activeLearner = ref.watch(activeLearnerProvider);
    final isSelected = activeLearner?.id == learner.id;
    final countryName =
        catalog?.country(learner.countryCode)?.name ?? learner.countryCode;
    final grade = catalog?.grade(learner.gradeId)?.name ?? '';
    final level = catalog?.level(learner.educationLevelId)?.name ?? '';
    final system = catalog?.system(learner.educationSystemId)?.name ?? '';

    return AppCard(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    learner.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.editLearnerAction,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            Text([level, grade].where((part) => part.isNotEmpty).join(' • ')),
            const SizedBox(height: 4),
            Text('$countryName${system.isEmpty ? '' : ' • $system'}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(_learnerStatus(learner.status, l10n)),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (isSelected)
                  Text(
                    l10n.activeLearnerLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditParentProfileScreen extends ConsumerWidget {
  const EditParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(parentProfileProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(24),
            child: AuthInlineMessage(
              message: _accountErrorMessage(error, l10n),
              isError: true,
            ),
          ),
          data: (profile) =>
              _ProfileEditForm(key: ValueKey(profile.userId), profile: profile),
        );
  }
}

class _ProfileEditForm extends ConsumerStatefulWidget {
  const _ProfileEditForm({required this.profile, super.key});

  final ParentProfile profile;

  @override
  ConsumerState<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<_ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(accountRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await repository.updateFullName(_name.text);
      ref.invalidate(parentProfileProvider);
      if (mounted) context.go(AppRoutes.account);
    } on PostgrestException {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.requestFailed);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.editProfileTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l10n.fullNameLabel),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.requiredField
                        : value.trim().length > 120
                        ? l10n.nameTooLong
                        : null,
                  ),
                  if (_error != null)
                    AuthInlineMessage(message: _error!, isError: true),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l10n.saveChangesAction,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _statusFormKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _reason = TextEditingController();
  String? _emailMessage;
  String? _passwordMessage;
  String? _statusMessage;
  bool _emailMessageIsError = false;
  bool _passwordMessageIsError = false;
  bool _statusMessageIsError = false;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  bool _isRequestingStatus = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(
      text: ref.read(supabaseClientProvider)?.auth.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUpdatingEmail = true;
      _emailMessage = null;
      _emailMessageIsError = false;
    });
    try {
      await repository.requestEmailChange(_email.text);
      if (mounted) setState(() => _emailMessage = l10n.emailChangeRequested);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _emailMessage = error.message;
          _emailMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isUpdatingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUpdatingPassword = true;
      _passwordMessage = null;
      _passwordMessageIsError = false;
    });
    try {
      await repository.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (mounted) {
        _currentPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
        setState(() => _passwordMessage = l10n.passwordUpdated);
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _passwordMessage = error.message;
          _passwordMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _requestAccountStatus(String status) async {
    if (!_statusFormKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final isDeletion = status == 'deletion_requested';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDeletion
              ? l10n.requestDeletionTitle
              : l10n.requestDeactivationTitle,
        ),
        content: Text(
          isDeletion
              ? l10n.requestDeletionConfirmation
              : l10n.requestDeactivationConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.submitRequestAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _isRequestingStatus = true;
      _statusMessage = null;
      _statusMessageIsError = false;
    });
    try {
      await repository.requestAccountStatus(
        status: status,
        reason: _reason.text,
      );
      ref.invalidate(accountStatusProvider);
      if (mounted) setState(() => _statusMessage = l10n.accountRequestReceived);
    } on PostgrestException {
      if (mounted) {
        setState(() {
          _statusMessage = l10n.requestFailed;
          _statusMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isRequestingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(accountStatusProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.accountSettingsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.changeEmailTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: l10n.newEmailLabel,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => _validEmail(value, l10n),
                      ),
                      if (_emailMessage != null)
                        AuthInlineMessage(
                          message: _emailMessage!,
                          isError: _emailMessageIsError,
                        ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.requestEmailChangeAction,
                        onPressed: _isUpdatingEmail ? null : _updateEmail,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.changePasswordTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPassword,
                        decoration: InputDecoration(
                          labelText: l10n.currentPasswordLabel,
                        ),
                        obscureText: true,
                        validator: (value) => value == null || value.isEmpty
                            ? l10n.requiredField
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPassword,
                        decoration: InputDecoration(
                          labelText: l10n.newPasswordLabel,
                        ),
                        obscureText: true,
                        validator: (value) => _validPassword(value, l10n),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassword,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPasswordLabel,
                        ),
                        obscureText: true,
                        validator: (value) => value != _newPassword.text
                            ? l10n.passwordsDoNotMatch
                            : null,
                      ),
                      if (_passwordMessage != null)
                        AuthInlineMessage(
                          message: _passwordMessage!,
                          isError: _passwordMessageIsError,
                        ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.changePasswordAction,
                        onPressed: _isUpdatingPassword ? null : _changePassword,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Form(
                  key: _statusFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.accountRequestsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.accountRequestDescription),
                      const SizedBox(height: 12),
                      status.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stackTrace) => AuthInlineMessage(
                          message: _accountErrorMessage(error, l10n),
                          isError: true,
                        ),
                        data: (value) => Text(
                          l10n.accountStatusLabel(
                            _localizedStatus(value, l10n),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reason,
                        decoration: InputDecoration(
                          labelText: l10n.optionalRequestReasonLabel,
                        ),
                        maxLength: 500,
                        maxLines: 3,
                        validator: (value) => (value?.length ?? 0) > 500
                            ? l10n.requestReasonTooLong
                            : null,
                      ),
                      if (_statusMessage != null)
                        AuthInlineMessage(
                          message: _statusMessage!,
                          isError: _statusMessageIsError,
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed:
                            _isRequestingStatus ||
                                status.asData?.value != 'active'
                            ? null
                            : () => _requestAccountStatus(
                                'deactivation_requested',
                              ),
                        child: Text(l10n.requestDeactivationAction),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed:
                            _isRequestingStatus ||
                                status.asData?.value != 'active'
                            ? null
                            : () => _requestAccountStatus('deletion_requested'),
                        child: Text(l10n.requestDeletionAction),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _accountErrorMessage(Object error, AppLocalizations l10n) {
  if (error is AuthNotConfiguredException) return l10n.authNotConfiguredAction;
  if (error is NotSignedInException) return l10n.signInRequired;
  if (error is PostgrestException) return l10n.requestFailed;
  return l10n.requestFailed;
}

String? _validEmail(String? value, AppLocalizations l10n) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.requiredField;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : l10n.invalidEmail;
}

String? _validPassword(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.requiredField;
  return value.length >= 10 ? null : l10n.passwordMinimumLength;
}

String _localizedStatus(String value, AppLocalizations l10n) => switch (value) {
  'active' => l10n.accountStatusActive,
  'deactivation_requested' => l10n.accountStatusDeactivationRequested,
  'deletion_requested' => l10n.accountStatusDeletionRequested,
  'deactivated' => l10n.accountStatusDeactivated,
  'deleted' => l10n.accountStatusDeleted,
  _ => l10n.accountStatusUnknown,
};

String _learnerStatus(String value, AppLocalizations l10n) => switch (value) {
  'active' => l10n.learnerStatusActive,
  'inactive' => l10n.learnerStatusInactive,
  'deletion_requested' => l10n.learnerStatusDeletionRequested,
  _ => l10n.accountStatusUnknown,
};

class _IncomingInvitationsCard extends ConsumerWidget {
  const _IncomingInvitationsCard({required this.invitations});

  final List<IncomingGuardianInvitation> invitations;

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String invitationId,
    bool accept,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(learnerRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.respondGuardianInvitation(
        invitationId: invitationId,
        accept: accept,
      );
      ref.invalidate(incomingGuardianInvitationsProvider);
      ref.invalidate(parentLearnersProvider);
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_add_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.incomingInvitationsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final inv in invitations) ...[
            Text(
              l10n.incomingInvitationPrompt(inv.inviterName, inv.learnerName),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _respond(context, ref, inv.id, true),
                  child: Text(l10n.acceptInvitationAction),
                ),
                OutlinedButton(
                  onPressed: () => _respond(context, ref, inv.id, false),
                  child: Text(l10n.declineInvitationAction),
                ),
              ],
            ),
            if (inv != invitations.last) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}
