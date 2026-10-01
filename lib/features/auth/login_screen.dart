import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_form.dart';
import 'state/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (ref.read(authControllerProvider).isSignedIn) context.go('/parent');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: AuthForm(
        formKey: _formKey,
        title: 'Welcome back',
        subtitle: 'Sign in as a parent or guardian to continue.',
        emailController: _emailController,
        passwordController: _passwordController,
        isLoading: auth.status == AuthStatus.loading,
        errorMessage: auth.errorMessage,
        submitLabel: 'Sign in',
        onSubmit: _submit,
        footer: TextButton(
          onPressed: () => context.go('/auth/register'),
          child: const Text('Create a parent account'),
        ),
      ),
    );
  }
}
