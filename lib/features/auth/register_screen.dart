import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_form.dart';
import 'state/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(
          fullName: _nameController.text,
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
      appBar: AppBar(title: const Text('Create account')),
      body: AuthForm(
        formKey: _formKey,
        title: 'Create a parent account',
        subtitle: 'One account can manage learning for multiple pupils.',
        fullNameController: _nameController,
        emailController: _emailController,
        passwordController: _passwordController,
        isLoading: auth.status == AuthStatus.loading,
        errorMessage: auth.errorMessage,
        submitLabel: 'Create account',
        onSubmit: _submit,
        footer: TextButton(
          onPressed: () => context.go('/auth/login'),
          child: const Text('Already have an account? Sign in'),
        ),
      ),
    );
  }
}
