import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import 'learner_models.dart';
import 'learner_providers.dart';
import 'learner_repository.dart';

class LearnerFormScreen extends ConsumerWidget {
  const LearnerFormScreen({super.key, this.learnerId});

  final String? learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(educationCatalogProvider);
    final l10n = AppLocalizations.of(context)!;
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: AuthInlineMessage(message: l10n.requestFailed, isError: true),
      ),
      data: (education) {
        if (learnerId == null) {
          return _LearnerForm(catalog: education);
        }
        return ref
            .watch(learnerProvider(learnerId!))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(24),
                child: AuthInlineMessage(
                  message: l10n.requestFailed,
                  isError: true,
                ),
              ),
              data: (learner) => _LearnerForm(
                key: ValueKey(learner.id),
                catalog: education,
                learner: learner,
              ),
            );
      },
    );
  }
}

class _LearnerForm extends ConsumerStatefulWidget {
  const _LearnerForm({required this.catalog, this.learner, super.key});

  final EducationCatalog catalog;
  final Learner? learner;

  @override
  ConsumerState<_LearnerForm> createState() => _LearnerFormState();
}

class _LearnerFormState extends ConsumerState<_LearnerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final String _registrationRequestId;
  late String? _countryCode;
  late String? _educationSystemId;
  late String? _curriculumId;
  late String? _educationLevelId;
  late String? _gradeId;
  late String? _schoolId;
  late String? _gender;
  DateTime? _dateOfBirth;
  String? _dateError;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final learner = widget.learner;
    _firstName = TextEditingController(text: learner?.firstName);
    _middleName = TextEditingController(text: learner?.middleName);
    _lastName = TextEditingController(text: learner?.lastName);
    _registrationRequestId = LearnerRepository.newRegistrationRequestId();
    _countryCode = learner?.countryCode;
    _educationSystemId = learner?.educationSystemId;
    _curriculumId = learner?.curriculumId;
    _educationLevelId = learner?.educationLevelId;
    _gradeId = learner?.gradeId;
    _schoolId = learner?.schoolId;
    _gender = learner?.gender;
    _dateOfBirth = learner?.dateOfBirth;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateOfBirth = selected;
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() => _dateError = AppLocalizations.of(context)!.requiredField);
      return;
    }

    final countryCode = _countryCode;
    final systemId = _educationSystemId;
    final curriculumId = _curriculumId;
    final levelId = _educationLevelId;
    final gradeId = _gradeId;
    if (countryCode == null ||
        systemId == null ||
        curriculumId == null ||
        levelId == null ||
        gradeId == null) {
      setState(() => _error = AppLocalizations.of(context)!.requiredField);
      return;
    }
    final repository = ref.read(learnerRepositoryProvider);
    if (repository == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final learner = widget.learner;
      if (learner == null) {
        await repository.createLearner(
          registrationRequestId: _registrationRequestId,
          firstName: _firstName.text,
          middleName: _middleName.text,
          lastName: _lastName.text,
          dateOfBirth: _dateOfBirth!,
          gender: _gender,
          countryCode: countryCode,
          educationSystemId: systemId,
          curriculumId: curriculumId,
          educationLevelId: levelId,
          gradeId: gradeId,
          schoolId: _schoolId,
        );
      } else {
        final updatedLearner = await repository.updateLearner(
          learnerId: learner.id,
          firstName: _firstName.text,
          middleName: _middleName.text,
          lastName: _lastName.text,
          dateOfBirth: _dateOfBirth!,
          gender: _gender,
          countryCode: countryCode,
          educationSystemId: systemId,
          curriculumId: curriculumId,
          educationLevelId: levelId,
          gradeId: gradeId,
          schoolId: _schoolId,
        );
        if (ref.read(activeLearnerProvider)?.id == learner.id) {
          await ref
              .read(activeLearnerProvider.notifier)
              .select(updatedLearner.id);
        }
      }
      ref.invalidate(parentLearnersProvider);
      if (learner != null) ref.invalidate(learnerProvider(learner.id));
      if (mounted) context.go(AppRoutes.account);
    } on PostgrestException {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.requestFailed);
      }
    } on NotSignedInException {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.signInRequired);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final learner = widget.learner;
    final availableCountries = widget.catalog.countries
        .where(
          (country) =>
              widget.catalog.systemsForCountry(country.code).isNotEmpty,
        )
        .toList(growable: false);
    final selectedCountryCode =
        availableCountries.any((country) => country.code == _countryCode)
        ? _countryCode
        : null;
    final systems = widget.catalog.systemsForCountry(selectedCountryCode);
    final selectedSystemId =
        systems.any((system) => system.id == _educationSystemId)
        ? _educationSystemId
        : null;
    final curricula = widget.catalog.curriculaForSystem(selectedSystemId);
    final selectedCurriculumId =
        curricula.any((curriculum) => curriculum.id == _curriculumId)
        ? _curriculumId
        : null;
    final levels = widget.catalog.levelsForCurriculum(selectedCurriculumId);
    final selectedLevelId = levels.any((level) => level.id == _educationLevelId)
        ? _educationLevelId
        : null;
    final grades = widget.catalog.gradesForLevel(selectedLevelId);
    final selectedGradeId = grades.any((grade) => grade.id == _gradeId)
        ? _gradeId
        : null;
    final schools = widget.catalog.schoolsForSystem(
      selectedCountryCode,
      selectedSystemId,
    );
    final selectedSchoolId = schools.any((school) => school.id == _schoolId)
        ? _schoolId
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    learner == null
                        ? l10n.addLearnerTitle
                        : l10n.editLearnerTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.learnerFormDescription),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _firstName,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.firstNameLabel),
                    validator: (value) => _requiredText(value, l10n),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _middleName,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.middleNameLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastName,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.lastNameLabel),
                    validator: (value) => _requiredText(value, l10n),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dateOfBirthLabel,
                      errorText: _dateError,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _dateOfBirth == null
                              ? l10n.selectDateAction
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_dateOfBirth!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('gender-$_gender'),
                    initialValue: _gender ?? '',
                    decoration: InputDecoration(labelText: l10n.genderLabel),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.preferNotToSayLabel),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(l10n.genderFemale),
                      ),
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(l10n.genderMale),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(l10n.genderOther),
                      ),
                      DropdownMenuItem(
                        value: 'prefer_not_to_say',
                        child: Text(l10n.preferNotToSayLabel),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _gender = value == null || value.isEmpty
                          ? null
                          : value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('country-$selectedCountryCode'),
                    initialValue: selectedCountryCode,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.countryLabel),
                    items: [
                      for (final country in availableCountries)
                        DropdownMenuItem(
                          value: country.code,
                          child: Text(country.name),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    onChanged: (value) => setState(() {
                      _countryCode = value;
                      _educationSystemId = null;
                      _curriculumId = null;
                      _educationLevelId = null;
                      _gradeId = null;
                      _schoolId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('system-$selectedSystemId'),
                    initialValue: selectedSystemId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.educationSystemNameLabel,
                    ),
                    items: [
                      for (final system in systems)
                        DropdownMenuItem(
                          value: system.id,
                          child: Text(system.name),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    onChanged: (value) => setState(() {
                      _educationSystemId = value;
                      _curriculumId = null;
                      _educationLevelId = null;
                      _gradeId = null;
                      _schoolId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('curriculum-$selectedCurriculumId'),
                    initialValue: selectedCurriculumId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.curriculumLabel,
                    ),
                    items: [
                      for (final curriculum in curricula)
                        DropdownMenuItem(
                          value: curriculum.id,
                          child: Text(curriculum.name),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    onChanged: (value) => setState(() {
                      _curriculumId = value;
                      _educationLevelId = null;
                      _gradeId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('level-$selectedLevelId'),
                    initialValue: selectedLevelId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.educationLevelLabel,
                    ),
                    items: [
                      for (final level in levels)
                        DropdownMenuItem(
                          value: level.id,
                          child: Text(level.name),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    onChanged: (value) => setState(() {
                      _educationLevelId = value;
                      _gradeId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('grade-$selectedGradeId'),
                    initialValue: selectedGradeId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.gradeLabel),
                    items: [
                      for (final grade in grades)
                        DropdownMenuItem(
                          value: grade.id,
                          child: Text(grade.name),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    onChanged: (value) => setState(() => _gradeId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('school-${selectedSchoolId ?? ''}'),
                    initialValue: selectedSchoolId ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.schoolOptionalLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.noSchoolSelected),
                      ),
                      for (final school in schools)
                        DropdownMenuItem(
                          value: school.id,
                          child: Text(school.name),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => _schoolId = value == null || value.isEmpty
                          ? null
                          : value,
                    ),
                  ),
                  if (_error != null)
                    AuthInlineMessage(message: _error!, isError: true),
                  const SizedBox(height: 16),
                  AppButton(
                    label: learner == null
                        ? l10n.addLearnerAction
                        : l10n.saveChangesAction,
                    onPressed: _isSaving ? null : _save,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.account),
                    child: Text(l10n.cancelAction),
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

class LearnerProfileScreen extends ConsumerStatefulWidget {
  const LearnerProfileScreen({required this.learnerId, super.key});

  final String learnerId;

  @override
  ConsumerState<LearnerProfileScreen> createState() =>
      _LearnerProfileScreenState();
}

class _LearnerProfileScreenState extends ConsumerState<LearnerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(activeLearnerProvider.notifier).select(widget.learnerId);
      } on PostgrestException {
        if (mounted) _showError(AppLocalizations.of(context)!.requestFailed);
      } on NotSignedInException {
        if (mounted) _showError(AppLocalizations.of(context)!.signInRequired);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setStatus({required bool deletion}) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          deletion ? l10n.requestDeletionTitle : l10n.deactivateLearnerTitle,
        ),
        content: Text(
          deletion
              ? l10n.learnerDeletionConfirmation
              : l10n.learnerDeactivationConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repository = ref.read(learnerRepositoryProvider);
    if (repository == null) return;
    try {
      if (deletion) {
        await repository.requestDeletion(widget.learnerId);
      } else {
        await repository.deactivateLearner(widget.learnerId);
      }
      ref.invalidate(learnerProvider(widget.learnerId));
      ref.invalidate(parentLearnersProvider);
      ref.invalidate(learnerStatusHistoryProvider(widget.learnerId));
      ref.invalidate(learnerChangeHistoryProvider(widget.learnerId));
      ref.read(activeLearnerProvider.notifier).clear();
    } on PostgrestException {
      if (mounted) _showError(l10n.requestFailed);
    } on NotSignedInException {
      if (mounted) _showError(l10n.signInRequired);
    }
  }

  Future<void> _recordPromotion(
    Learner learner,
    EducationCatalog catalog,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final targetGradeId = await showDialog<String>(
      context: context,
      builder: (context) =>
          _PromotionDialog(catalog: catalog, currentGradeId: learner.gradeId),
    );
    if (targetGradeId == null || !mounted) return;

    final targetGrade = catalog.grade(targetGradeId);
    final targetLevel = targetGrade == null
        ? null
        : catalog.level(targetGrade.educationLevelId);
    final targetCurriculum = targetLevel == null
        ? null
        : catalog.curriculum(targetLevel.curriculumId);
    final targetSystem = targetCurriculum == null
        ? null
        : catalog.system(targetCurriculum.educationSystemId);
    if (targetGrade == null ||
        targetLevel == null ||
        targetCurriculum == null ||
        targetSystem == null) {
      _showError(l10n.requestFailed);
      return;
    }

    final promotionType = targetSystem.id != learner.educationSystemId
        ? 'system_changed'
        : targetGrade.id == learner.gradeId
        ? 'repeated'
        : 'promoted';
    final repository = ref.read(learnerRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.recordPromotion(
        learnerId: learner.id,
        targetGrade: targetGrade,
        targetLevel: targetLevel,
        targetCurriculum: targetCurriculum,
        targetSystem: targetSystem,
        schoolId: targetSystem.id == learner.educationSystemId
            ? learner.schoolId
            : null,
        promotionType: promotionType,
        effectiveOn: DateTime.now().toUtc(),
      );
      ref.invalidate(learnerProvider(learner.id));
      ref.invalidate(learnerPromotionHistoryProvider(learner.id));
      ref.invalidate(learnerStatusHistoryProvider(learner.id));
      ref.invalidate(learnerChangeHistoryProvider(learner.id));
      ref.invalidate(parentLearnersProvider);
      if (ref.read(activeLearnerProvider)?.id == learner.id) {
        await ref.read(activeLearnerProvider.notifier).select(learner.id);
      }
    } on PostgrestException {
      if (mounted) _showError(l10n.promotionFailed);
    } on NotSignedInException {
      if (mounted) _showError(l10n.signInRequired);
    }
  }

  Future<void> _inviteGuardian(Learner learner) async {
    final l10n = AppLocalizations.of(context)!;
    final email = await showDialog<String>(
      context: context,
      builder: (context) => const _InviteGuardianDialog(),
    );
    if (email == null || !mounted) return;

    final repository = ref.read(learnerRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.inviteGuardianByEmail(
        learnerId: learner.id,
        email: email,
      );
      ref.invalidate(sentGuardianInvitationsProvider(learner.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inviteSentMessage(email))),
        );
      }
    } on PostgrestException catch (error) {
      if (mounted) _showError(error.message);
    } on NotSignedInException {
      if (mounted) _showError(l10n.signInRequired);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final learnerState = ref.watch(learnerProvider(widget.learnerId));
    final catalogState = ref.watch(educationCatalogProvider);
    if (learnerState.isLoading || catalogState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (learnerState.hasError || catalogState.hasError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AuthInlineMessage(message: l10n.requestFailed, isError: true),
      );
    }
    final learner = learnerState.requireValue;
    final catalog = catalogState.requireValue;
    final countryName =
        catalog.country(learner.countryCode)?.name ?? learner.countryCode;
    final systemName = catalog.system(learner.educationSystemId)?.name ?? '';
    final curriculumName = catalog.curriculum(learner.curriculumId)?.name ?? '';
    final levelName = catalog.level(learner.educationLevelId)?.name ?? '';
    final gradeName = catalog.grade(learner.gradeId)?.name ?? '';
    final schoolName = catalog.school(learner.schoolId)?.name;
    final isActive = learner.status == 'active';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      learner.fullName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.editLearnerAction,
                    onPressed: isActive
                        ? () => context.go(AppRoutes.editLearner(learner.id))
                        : null,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileLine(
                      label: l10n.dateOfBirthLabel,
                      value: MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(learner.dateOfBirth),
                    ),
                    _ProfileLine(
                      label: l10n.genderLabel,
                      value: _genderLabel(learner.gender, l10n),
                    ),
                    _ProfileLine(label: l10n.countryLabel, value: countryName),
                    _ProfileLine(
                      label: l10n.educationSystemNameLabel,
                      value: systemName,
                    ),
                    _ProfileLine(
                      label: l10n.curriculumLabel,
                      value: curriculumName,
                    ),
                    _ProfileLine(
                      label: l10n.educationLevelLabel,
                      value: levelName,
                    ),
                    _ProfileLine(label: l10n.gradeLabel, value: gradeName),
                    _ProfileLine(
                      label: l10n.schoolOptionalLabel,
                      value: schoolName ?? l10n.noSchoolSelected,
                    ),
                    _ProfileLine(
                      label: l10n.learnerStatusLabel,
                      value: _learnerStatus(learner.status, l10n),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isActive
                              ? () => _recordPromotion(learner, catalog)
                              : null,
                          icon: const Icon(Icons.trending_up),
                          label: Text(l10n.recordPromotionAction),
                        ),
                        if (isActive)
                          TextButton(
                            onPressed: () => _setStatus(deletion: false),
                            child: Text(l10n.deactivateLearnerAction),
                          ),
                        if (isActive)
                          TextButton(
                            onPressed: () => _setStatus(deletion: true),
                            child: Text(l10n.requestLearnerDeletionAction),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _GuardianInvitationsSection(
                learnerId: learner.id,
                isActive: isActive,
                onInvite: () => _inviteGuardian(learner),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.learnerHistoryTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _LearnerHistory(learnerId: learner.id, catalog: catalog),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  ref.read(activeLearnerProvider.notifier).clear();
                  context.go(AppRoutes.account);
                },
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.switchLearnerAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionDialog extends StatefulWidget {
  const _PromotionDialog({required this.catalog, required this.currentGradeId});

  final EducationCatalog catalog;
  final String currentGradeId;

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  String? _gradeId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _gradeId = widget.currentGradeId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.recordPromotionAction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _gradeId,
            decoration: InputDecoration(labelText: l10n.gradeLabel),
            items: [
              for (final grade in widget.catalog.grades)
                DropdownMenuItem(
                  value: grade.id,
                  child: Text(_promotionGradeLabel(grade, widget.catalog)),
                ),
            ],
            onChanged: (value) => setState(() {
              _gradeId = value;
              _error = null;
            }),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () {
            if (_gradeId == null) {
              setState(() => _error = l10n.requiredField);
              return;
            }
            Navigator.pop(context, _gradeId);
          },
          child: Text(l10n.saveChangesAction),
        ),
      ],
    );
  }
}

class _LearnerHistory extends ConsumerWidget {
  const _LearnerHistory({required this.learnerId, required this.catalog});

  final String learnerId;
  final EducationCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statuses = ref.watch(learnerStatusHistoryProvider(learnerId));
    final promotions = ref.watch(learnerPromotionHistoryProvider(learnerId));
    final changes = ref.watch(learnerChangeHistoryProvider(learnerId));
    if (statuses.isLoading || promotions.isLoading || changes.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (statuses.hasError || promotions.hasError || changes.hasError) {
      return AuthInlineMessage(message: l10n.requestFailed, isError: true);
    }
    final statusEvents = statuses.requireValue;
    final promotionEvents = promotions.requireValue;
    final changeEvents = changes.requireValue;
    if (statusEvents.isEmpty &&
        promotionEvents.isEmpty &&
        changeEvents.isEmpty) {
      return AppCard(child: Text(l10n.noLearnerHistory));
    }
    final history = <(DateTime, Widget)>[
      for (final event in statusEvents)
        (
          event.createdAt,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(_learnerStatus(event.status, l10n)),
            subtitle: Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(event.createdAt),
            ),
          ),
        ),
      for (final event in changeEvents)
        (
          event.createdAt,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_note),
            title: Text(
              event.changedFields.containsKey('created')
                  ? l10n.profileRegistered
                  : l10n.profileUpdated,
            ),
            subtitle: Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(event.createdAt),
            ),
          ),
        ),
      for (final event in promotionEvents)
        (
          event.effectiveOn,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.trending_up),
            title: Text(
              l10n.promotionHistoryItem(
                catalog.grade(event.fromGradeId)?.name ?? '',
                catalog.grade(event.toGradeId)?.name ?? '',
              ),
            ),
            subtitle: Text(
              '${_promotionType(event.promotionType, l10n)} · '
              '${MaterialLocalizations.of(context).formatMediumDate(event.effectiveOn)}',
            ),
          ),
        ),
    ]..sort((first, second) => second.$1.compareTo(first.$1));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final entry in history) entry.$2],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String? _requiredText(String? value, AppLocalizations l10n) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return l10n.requiredField;
  return text.length > 80 ? l10n.learnerNameTooLong : null;
}

String _promotionGradeLabel(EducationGrade grade, EducationCatalog catalog) {
  final level = catalog.level(grade.educationLevelId);
  final curriculum = level == null
      ? null
      : catalog.curriculum(level.curriculumId);
  final system = curriculum == null
      ? null
      : catalog.system(curriculum.educationSystemId);
  final country = system == null ? null : catalog.country(system.countryCode);
  return [
    country?.name,
    system?.name,
    grade.name,
  ].whereType<String>().join(' · ');
}

String _learnerStatus(String value, AppLocalizations l10n) => switch (value) {
  'active' => l10n.learnerStatusActive,
  'inactive' => l10n.learnerStatusInactive,
  'deletion_requested' => l10n.learnerStatusDeletionRequested,
  _ => l10n.accountStatusUnknown,
};

String _genderLabel(String? value, AppLocalizations l10n) => switch (value) {
  'female' => l10n.genderFemale,
  'male' => l10n.genderMale,
  'other' => l10n.genderOther,
  'prefer_not_to_say' => l10n.preferNotToSayLabel,
  _ => l10n.notProvidedLabel,
};

String _promotionType(String value, AppLocalizations l10n) => switch (value) {
  'promoted' => l10n.promotionTypePromoted,
  'repeated' => l10n.promotionTypeRepeated,
  'system_changed' => l10n.promotionTypeSystemChanged,
  _ => value,
};

class _GuardianInvitationsSection extends ConsumerWidget {
  const _GuardianInvitationsSection({
    required this.learnerId,
    required this.isActive,
    required this.onInvite,
  });

  final String learnerId;
  final bool isActive;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final invitations = ref.watch(sentGuardianInvitationsProvider(learnerId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.guardiansSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isActive)
                OutlinedButton.icon(
                  onPressed: onInvite,
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(l10n.inviteGuardianAction),
                ),
            ],
          ),
          const SizedBox(height: 12),
          invitations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text(l10n.requestFailed),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  l10n.noPendingInvitations,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pendingInvitationsLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final inv in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(inv.inviteeEmail)),
                          TextButton(
                            onPressed: () async {
                              final repo = ref.read(learnerRepositoryProvider);
                              if (repo == null) return;
                              try {
                                await repo.revokeGuardianInvitation(inv.id);
                                ref.invalidate(
                                  sentGuardianInvitationsProvider(learnerId),
                                );
                              } on Exception catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.requestFailed)),
                                  );
                                }
                              }
                            },
                            child: Text(l10n.revokeInvitationAction),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InviteGuardianDialog extends StatefulWidget {
  const _InviteGuardianDialog();

  @override
  State<_InviteGuardianDialog> createState() => _InviteGuardianDialogState();
}

class _InviteGuardianDialogState extends State<_InviteGuardianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.inviteGuardianTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.inviteGuardianDescription),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return l10n.requiredField;
                  if (!text.contains('@') || !text.contains('.')) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _email.text.trim());
            }
          },
          child: Text(l10n.sendInvitationAction),
        ),
      ],
    );
  }
}
