import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/country_configuration.dart';
import '../../core/config/country_providers.dart';
import '../../core/routing/app_router.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.next});

  final String? next;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.signIn(email: _email.text, password: _password.text);
      if (mounted) context.go(_safeNextPath(widget.next));
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }

    return AuthFormFrame(
      title: l10n.signInTitle,
      description: l10n.signInDescription,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) => _validateEmail(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) => _required(value, l10n),
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_error != null) AuthInlineMessage(message: _error!, isError: true),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.signInAction,
          onPressed: _isSubmitting ? null : _submit,
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.forgotPassword),
          child: Text(l10n.forgotPasswordAction),
        ),
        AuthLink(
          text: l10n.noAccountPrompt,
          label: l10n.createAccountAction,
          onPressed: () => context.go(AppRoutes.signUp),
        ),
      ],
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  String? _countryCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final response = await repository.signUp(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        countryCode: _countryCode!,
      );
      if (!mounted) return;
      if (response.session != null) {
        context.go(AppRoutes.account);
      } else {
        context.go(
          Uri(
            path: AppRoutes.verifyEmail,
            queryParameters: {'email': _email.text.trim()},
          ).toString(),
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }
    return ref
        .watch(countriesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => AuthFormFrame(
            title: l10n.signUpTitle,
            description: l10n.signUpDescription,
            children: [
              AuthInlineMessage(
                message: error is CountriesBackendNotConfiguredException
                    ? l10n.countriesNotConfigured
                    : l10n.requestFailed,
                isError: true,
              ),
              TextButton(
                onPressed: () => ref.invalidate(countriesProvider),
                child: Text(l10n.tryAgainAction),
              ),
            ],
          ),
          data: (countries) => _buildForm(context, l10n, countries),
        );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    List<CountryConfiguration> countries,
  ) {
    if (_countryCode == null && countries.isNotEmpty) {
      _countryCode = countries
          .firstWhere(
            (country) => country.isDefault,
            orElse: () => countries.first,
          )
          .countryCode;
    }
    return AuthFormFrame(
      title: l10n.signUpTitle,
      description: l10n.signUpDescription,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _countryCode,
                decoration: InputDecoration(labelText: l10n.countryTitle),
                items: [
                  for (final country in countries)
                    DropdownMenuItem(
                      value: country.countryCode,
                      child: Text(country.displayName),
                    ),
                ],
                onChanged: (value) => setState(() => _countryCode = value),
                validator: (value) => value == null ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.fullNameLabel),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) => _validateName(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) => _validateEmail(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => _validatePassword(value, l10n),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordLabel,
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    value != _password.text ? l10n.passwordsDoNotMatch : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_error != null) AuthInlineMessage(message: _error!, isError: true),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.createAccountAction,
          onPressed: _isSubmitting ? null : _submit,
        ),
        AuthLink(
          text: l10n.haveAccountPrompt,
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  String? _error;
  bool _isSending = false;
  bool _sentAgain = false;

  Future<void> _resend() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await repository.resendVerificationEmail(widget.email);
      if (mounted) setState(() => _sentAgain = true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }
    return AuthFormFrame(
      title: l10n.verifyEmailTitle,
      description: l10n.verifyEmailDescription(widget.email),
      children: [
        if (_sentAgain) AuthInlineMessage(message: l10n.verificationResent),
        if (_error != null) AuthInlineMessage(message: _error!, isError: true),
        AppButton(
          label: l10n.resendVerificationAction,
          onPressed: _isSending || widget.email.isEmpty ? null : _resend,
        ),
        AuthLink(
          text: l10n.alreadyVerifiedPrompt,
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  bool _requestSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.requestPasswordReset(_email.text);
      if (mounted) setState(() => _requestSent = true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }

    return AuthFormFrame(
      title: l10n.forgotPasswordTitle,
      description: l10n.forgotPasswordDescription,
      children: [
        if (_requestSent)
          AuthInlineMessage(message: l10n.passwordResetEmailSent)
        else ...[
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (value) => _validateEmail(value, l10n),
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
          if (_error != null)
            AuthInlineMessage(message: _error!, isError: true),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.sendResetLinkAction,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
        AuthLink(
          text: l10n.rememberPasswordPrompt,
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  bool _isSubmitting = false;
  bool _updated = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.updatePassword(_password.text);
      if (mounted) setState(() => _updated = true);
      ref.read(passwordRecoveryModeProvider.notifier).complete();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ref.watch(supabaseClientProvider) == null) {
      return const AuthBackendNotice();
    }
    final isRecoverySession = ref.watch(passwordRecoveryModeProvider);

    return AuthFormFrame(
      title: l10n.passwordRecoveryTitle,
      description: isRecoverySession
          ? l10n.passwordRecoveryDescription
          : l10n.openResetLinkFirst,
      children: [
        if (_updated)
          AuthInlineMessage(message: l10n.passwordUpdated)
        else if (isRecoverySession) ...[
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(labelText: l10n.newPasswordLabel),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validatePassword(value, l10n),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassword,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPasswordLabel,
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value != _password.text ? l10n.passwordsDoNotMatch : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          if (_error != null)
            AuthInlineMessage(message: _error!, isError: true),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.updatePasswordAction,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
        AuthLink(
          text: '',
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class AuthCallbackScreen extends ConsumerWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return const AuthBackendNotice();
    if (client.auth.currentSession != null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AuthFormFrame(
      title: l10n.emailLinkProcessedTitle,
      description: l10n.emailLinkProcessedDescription,
      children: [
        AppButton(
          label: l10n.signInAction,
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}

class AuthFormFrame extends StatelessWidget {
  const AuthFormFrame({
    required this.title,
    required this.description,
    required this.children,
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(description, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBackendNotice extends StatelessWidget {
  const AuthBackendNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthFormFrame(
      title: l10n.authNotConfiguredTitle,
      description: l10n.authNotConfiguredDescription,
      children: [
        AuthInlineMessage(message: l10n.authNotConfiguredAction, isError: true),
      ],
    );
  }
}

class AuthInlineMessage extends StatelessWidget {
  const AuthInlineMessage({
    required this.message,
    this.isError = false,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  const AuthLink({
    required this.text,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String text;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (text.isNotEmpty) Text(text),
        TextButton(onPressed: onPressed, child: Text(label)),
      ],
    );
  }
}

String? _required(String? value, AppLocalizations l10n) {
  return value == null || value.trim().isEmpty ? l10n.requiredField : null;
}

String? _validateName(String? value, AppLocalizations l10n) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return l10n.requiredField;
  return name.length <= 120 ? null : l10n.nameTooLong;
}

String? _validateEmail(String? value, AppLocalizations l10n) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.requiredField;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return l10n.invalidEmail;
  }
  return null;
}

String? _validatePassword(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.requiredField;
  if (value.length < 10) return l10n.passwordMinimumLength;
  return null;
}

String _safeNextPath(String? path) {
  if (path == AppRoutes.account ||
      path == AppRoutes.editParentProfile ||
      path == AppRoutes.accountSettings) {
    return path!;
  }
  return AppRoutes.account;
}
