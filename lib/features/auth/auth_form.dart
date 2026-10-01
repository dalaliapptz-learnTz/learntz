import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.submitLabel,
    required this.onSubmit,
    required this.footer,
    this.fullNameController,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? fullNameController;
  final bool isLoading;
  final String? errorMessage;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle),
                const SizedBox(height: 28),
                if (fullNameController != null) ...[
                  TextFormField(
                    controller: fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter your full name' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(onPressed: isLoading ? null : onSubmit, child: Text(isLoading ? 'Please wait...' : submitLabel)),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
