import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/state/auth_controller.dart';

class AddPupilScreen extends ConsumerStatefulWidget {
  const AddPupilScreen({super.key});

  @override
  ConsumerState<AddPupilScreen> createState() => _AddPupilScreenState();
}

class _AddPupilScreenState extends ConsumerState<AddPupilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).addLearner(
          fullName: _nameController.text,
          grade: _gradeController.text,
        );
    if (!mounted) return;
    if (ref.read(authControllerProvider).errorMessage == null) context.go('/parent/pupils');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add pupil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Set up a learner profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Start with the basics. More curriculum details can be added as the platform grows.'),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Pupil full name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter the pupil name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(labelText: 'Grade or form'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter the grade or form' : null,
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(auth.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _submit, child: const Text('Save pupil'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
