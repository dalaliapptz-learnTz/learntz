import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/platform_configuration.dart';
import '../auth/state/auth_controller.dart';

class AddPupilScreen extends ConsumerStatefulWidget {
  const AddPupilScreen({super.key});

  @override
  ConsumerState<AddPupilScreen> createState() => _AddPupilScreenState();
}

class _AddPupilScreenState extends ConsumerState<AddPupilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _countryCode;
  String? _curriculumCode;
  String? _educationSystemCode;
  String? _educationLevelCode;
  String? _gradeCode;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final countries = PlatformCatalog.countries;
    final country = countries.firstWhere((item) => item.code == (_countryCode ?? countries.first.code));
    final curriculum = country.curricula.firstWhere((item) => item.code == (_curriculumCode ?? country.curricula.first.code));
    final system = curriculum.educationSystems.firstWhere((item) => item.code == (_educationSystemCode ?? curriculum.educationSystems.first.code));
    final level = system.levels.firstWhere((item) => item.code == (_educationLevelCode ?? system.levels.first.code));
    final grade = level.grades.firstWhere((item) => item.code == (_gradeCode ?? level.grades.first.code));
    await ref.read(authControllerProvider.notifier).addLearner(
          fullName: _nameController.text,
          grade: grade.name,
          countryCode: country.code,
          curriculumCode: curriculum.code,
          curriculum: curriculum.name,
          educationSystem: system.name,
          educationLevel: level.name,
          gradeCode: grade.code,
        );
    if (!mounted) return;
    if (ref.read(authControllerProvider).errorMessage == null) context.go('/parent/pupils');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final countries = PlatformCatalog.countries;
    final country = countries.firstWhere((item) => item.code == (_countryCode ?? countries.first.code));
    final curricula = country.curricula;
    final curriculum = curricula.firstWhere((item) => item.code == (_curriculumCode ?? curricula.first.code));
    final systems = curriculum.educationSystems;
    final system = systems.firstWhere((item) => item.code == (_educationSystemCode ?? systems.first.code));
    final levels = system.levels;
    final level = levels.firstWhere((item) => item.code == (_educationLevelCode ?? levels.first.code));
    final grades = level.grades;
    return Scaffold(
      appBar: AppBar(title: const Text('Add pupil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Set up a learner profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Choose the learner\'s education context so recommendations can be configured correctly.'),
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
                DropdownButtonFormField<String>(
                  key: ValueKey('country-${country.code}'),
                  initialValue: country.code,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: countries.map((item) => DropdownMenuItem(value: item.code, child: Text(item.productName))).toList(),
                  onChanged: (value) => setState(() {
                    _countryCode = value;
                    _curriculumCode = null;
                    _educationSystemCode = null;
                    _educationLevelCode = null;
                    _gradeCode = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('curriculum-${curriculum.code}'),
                  initialValue: curriculum.code,
                  decoration: const InputDecoration(labelText: 'Curriculum'),
                  items: curricula.map((item) => DropdownMenuItem(value: item.code, child: Text(item.name))).toList(),
                  onChanged: (value) => setState(() {
                    _curriculumCode = value;
                    _educationSystemCode = null;
                    _educationLevelCode = null;
                    _gradeCode = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('system-${system.code}'),
                  initialValue: system.code,
                  decoration: const InputDecoration(labelText: 'Education system'),
                  items: systems.map((item) => DropdownMenuItem(value: item.code, child: Text(item.name))).toList(),
                  onChanged: (value) => setState(() {
                    _educationSystemCode = value;
                    _educationLevelCode = null;
                    _gradeCode = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('level-${level.code}'),
                  initialValue: level.code,
                  decoration: const InputDecoration(labelText: 'Education level'),
                  items: levels.map((item) => DropdownMenuItem(value: item.code, child: Text(item.name))).toList(),
                  onChanged: (value) => setState(() {
                    _educationLevelCode = value;
                    _gradeCode = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('grade-${grades.first.code}-${_gradeCode ?? grades.first.code}'),
                  initialValue: grades.firstWhere((item) => item.code == (_gradeCode ?? grades.first.code)).code,
                  decoration: const InputDecoration(labelText: 'Grade or form'),
                  items: grades.map((item) => DropdownMenuItem(value: item.code, child: Text(item.name))).toList(),
                  onChanged: (value) => setState(() => _gradeCode = value),
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
