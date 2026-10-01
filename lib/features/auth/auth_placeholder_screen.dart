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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text('Account access', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Authentication will be introduced in Stage 1.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/auth/login'), child: const Text('Open login placeholder')),
            ],
          ),
        ),
      ),
    );
  }
}
