import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/state/app_providers.dart';
import '../exam_models.dart';
import '../exam_providers.dart';

class MockUploadCentreScreen extends ConsumerStatefulWidget {
  const MockUploadCentreScreen({super.key});

  @override
  ConsumerState<MockUploadCentreScreen> createState() =>
      _MockUploadCentreScreenState();
}

class _MockUploadCentreScreenState extends ConsumerState<MockUploadCentreScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _countryCode;
  String _authorityId = 'NECTA';
  String _tier = 'regional';
  final _titleController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _countryCode = ref.read(selectedCountryProvider).countryCode;
    _authorityId = _countryCode == 'TZ'
        ? 'NECTA'
        : _countryCode == 'KE'
            ? 'KNEC'
            : 'UNEB';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _schoolNameController.dispose();
    _fileUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(examRepositoryProvider);
    if (repository == null) {
      setState(() => _errorMessage = 'Database client unavailable');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final year = int.tryParse(_yearController.text.trim()) ?? 2024;
      final request = PaperUploadRequest(
        countryCode: _countryCode,
        authorityId: _authorityId,
        title: _titleController.text.trim(),
        year: year,
        tier: _tier,
        region: _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
        district: _districtController.text.trim().isEmpty
            ? null
            : _districtController.text.trim(),
        schoolName: _schoolNameController.text.trim().isEmpty
            ? null
            : _schoolNameController.text.trim(),
        fileUrl: _fileUrlController.text.trim().isEmpty
            ? 'https://storage.learntz.test/mock_${DateTime.now().millisecondsSinceEpoch}.pdf'
            : _fileUrlController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final result = await repository.uploadPaper(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Mock Examination "${result.title}" uploaded successfully!'),
          backgroundColor: LearnTzColors.success,
        ),
      );
      ref.invalidate(filteredExaminationPapersProvider);
      ref.invalidate(examinationCentreCatalogProvider(_countryCode));
      context.go(AppRoutes.examCentre);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        title: const Text('Mock Upload Centre'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.examCentre),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-Tier Mock Examination Upload',
                    style: LearnTzTypography.h2.copyWith(
                      color: LearnTzColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Submit national, regional, district, or inter-school mock exam papers and marking rubrics for question extraction and student revision.',
                    style: LearnTzTypography.bodyRegular.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LearnTzColors.errorBg,
                        borderRadius: LearnTzRadii.borderMd,
                        border: Border.all(color: LearnTzColors.errorBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: LearnTzColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: LearnTzColors.errorText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Examination Classification',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _countryCode,
                                decoration:
                                    const InputDecoration(labelText: 'Country'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'TZ',
                                      child: Text('🇹🇿 Tanzania (TZ)')),
                                  DropdownMenuItem(
                                      value: 'KE', child: Text('🇰🇪 Kenya (KE)')),
                                  DropdownMenuItem(
                                      value: 'UG',
                                      child: Text('🇺🇬 Uganda (UG)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _countryCode = val;
                                      _authorityId = val == 'TZ'
                                          ? 'NECTA'
                                          : val == 'KE'
                                              ? 'KNEC'
                                              : 'UNEB';
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _authorityId,
                                decoration: const InputDecoration(
                                    labelText: 'Authority'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'NECTA',
                                      child: Text('NECTA (Tanzania)')),
                                  DropdownMenuItem(
                                      value: 'KNEC',
                                      child: Text('KNEC (Kenya)')),
                                  DropdownMenuItem(
                                      value: 'UNEB',
                                      child: Text('UNEB (Uganda)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _authorityId = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _tier,
                          decoration:
                              const InputDecoration(labelText: 'Examination Tier'),
                          items: const [
                            DropdownMenuItem(
                                value: 'regional',
                                child: Text('Regional Mock (Inter-District)')),
                            DropdownMenuItem(
                                value: 'district', child: Text('District Mock')),
                            DropdownMenuItem(
                                value: 'school',
                                child: Text('School / Inter-School Mock')),
                            DropdownMenuItem(
                                value: 'national', child: Text('National Paper')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _tier = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. Paper Details',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _titleController,
                          label: 'Examination Paper Title *',
                          hint:
                              'e.g. Arusha Regional Mock 2024 Physics Paper 1',
                          validator: (val) {
                            if (val == null || val.trim().length < 3) {
                              return 'Please enter a valid examination title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _yearController,
                                label: 'Year *',
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  final y = int.tryParse(val ?? '');
                                  if (y == null || y < 1990 || y > 2050) {
                                    return 'Valid year required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _regionController,
                                label: 'Region / County',
                                hint: 'e.g. Arusha, Nairobi, Kampala',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _districtController,
                                label: 'District / Sub-County',
                                hint: 'e.g. Ilala, Westlands, Makindye',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _schoolNameController,
                                label: 'School Name (Optional)',
                                hint: 'e.g. Mzumbe Secondary School',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3. Document & Instructions',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _fileUrlController,
                          label: 'PDF Storage URL or Document Link',
                          hint: 'https://...',
                          prefixIcon: Icons.link_outlined,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _notesController,
                          label: 'Special Notes / Marking Rubric Notes',
                          hint:
                              'Add instructions, special sections, or syllabus remarks...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => context.go(AppRoutes.examCentre),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        key: const Key('submit-mock-paper-btn'),
                        label: 'Submit Mock Paper',
                        icon: Icons.check,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ],
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
