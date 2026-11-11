import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import 'account_providers.dart';
import 'account_repository.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(supabaseClientProvider)?.auth.currentUser;

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
              ref
                  .watch(parentProfileProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => AppCard(
                      child: AuthInlineMessage(
                        message: _accountErrorMessage(error, l10n),
                        isError: true,
                      ),
                    ),
                    data: (profile) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(user?.email ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            profile.countryCode,
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
