import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthPlaceholderScreen extends StatelessWidget {
  const AuthPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.family_restroom, size: 56),
                const SizedBox(height: 16),
                Text('Learning starts with your family', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Create a parent account to add pupils and follow their learning journey.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => context.go('/auth/register'), child: const Text('Create parent account'))),
                TextButton(onPressed: () => context.go('/auth/login'), child: const Text('Sign in')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
