import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../organization_models.dart';
import '../organization_providers.dart';

class OrganizationRegistrationScreen extends ConsumerStatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  ConsumerState<OrganizationRegistrationScreen> createState() =>
      _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState
    extends ConsumerState<OrganizationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _countryCode = 'TZ';
  OrganizationType _type = OrganizationType.schoolNetwork;
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _regNumController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _regNumController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (_slugController.text.isEmpty ||
        _slugController.text == _slugify(val.substring(0, val.length > 1 ? val.length - 1 : 0))) {
      _slugController.text = _slugify(val);
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.registerEnterpriseOrganization(
        countryCode: _countryCode,
        name: _nameController.text.trim(),
        slug: _slugController.text.trim().toLowerCase(),
        type: _type,
        registrationNumber: _regNumController.text.trim().isNotEmpty
            ? _regNumController.text.trim()
            : null,
        websiteUrl: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        contactEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        contactPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      // Invalidate list provider so new entry displays
      ref.invalidate(organizationsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization registered successfully!'),
            backgroundColor: LearnTzColors.success,
          ),
        );
        context.go('/enterprise/directory');
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = err.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Nav
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/enterprise/directory'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institutional Onboarding',
                            style: LearnTzTypography.h2.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LearnTzColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Register a School Network, Educational Office, Research Institution, or Ministry workspace.',
                            style: LearnTzTypography.bodyRegular.copyWith(
                              color: LearnTzColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  AppCard(
                    backgroundColor: LearnTzColors.error.withValues(alpha: 0.1),
                    borderColor: LearnTzColors.error,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: LearnTzColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: LearnTzColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Registration Form
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Jurisdiction & Entity Type',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Country Picker
                        Text(
                          'Operating Country',
                          style: LearnTzTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('🇹🇿 Tanzania'),
                              selected: _countryCode == 'TZ',
                              onSelected: (selected) {
                                if (selected) setState(() => _countryCode = 'TZ');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('🇰🇪 Kenya'),
                              selected: _countryCode == 'KE',
                              onSelected: (selected) {
                                if (selected) setState(() => _countryCode = 'KE');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('🇺🇬 Uganda'),
                              selected: _countryCode == 'UG',
                              onSelected: (selected) {
                                if (selected) setState(() => _countryCode = 'UG');
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Organization Type
                        Text(
                          'Organization Classification',
                          style: LearnTzTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<OrganizationType>(
                          initialValue: _type,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          items: OrganizationType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _type = val);
                          },
                        ),

                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 20),

                        Text(
                          '2. Identity & Official Profile',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          key: const Key('org-name-field'),
                          label: 'Full Organization Name',
                          hint: 'e.g. Aga Khan Education Service Tanzania',
                          controller: _nameController,
                          onChanged: _onNameChanged,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          key: const Key('org-slug-field'),
                          label: 'Workspace Slug (Unique identifier)',
                          hint: 'e.g. aga-khan-tz',
                          controller: _slugController,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          key: const Key('org-reg-field'),
                          label: 'Official Registration / License Number',
                          hint: 'e.g. MOE-TZ-REG-2024-098',
                          controller: _regNumController,
                        ),

                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 20),

                        Text(
                          '3. Contact & Digital Channels',
                          style: LearnTzTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          key: const Key('org-email-field'),
                          label: 'Official Administrative Email',
                          hint: 'admin@organization.org',
                          controller: _emailController,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          key: const Key('org-website-field'),
                          label: 'Website URL',
                          hint: 'https://organization.org',
                          controller: _websiteController,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          key: const Key('org-phone-field'),
                          label: 'Official Contact Phone',
                          hint: '+255 22 211 0000',
                          controller: _phoneController,
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            key: const Key('submit-org-registration-btn'),
                            label: 'Submit Organization Onboarding',
                            icon: Icons.check_circle_outline,
                            isLoading: _isLoading,
                            size: AppButtonSize.lg,
                            onPressed: _isLoading ? null : _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
