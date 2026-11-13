import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../learners/learner_providers.dart';
import '../social_models.dart';
import '../social_providers.dart';

class LearnerSocialProfileScreen extends ConsumerStatefulWidget {
  final String? learnerId;

  const LearnerSocialProfileScreen({super.key, this.learnerId});

  @override
  ConsumerState<LearnerSocialProfileScreen> createState() =>
      _LearnerSocialProfileScreenState();
}

class _LearnerSocialProfileScreenState
    extends ConsumerState<LearnerSocialProfileScreen> {
  static const List<String> _availableInterests = [
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Kiswahili',
    'History',
    'Geography',
    'Civics',
    'Coding',
    'Art & Design',
  ];

  @override
  Widget build(BuildContext context) {
    final activeLearnerId =
        widget.learnerId ?? ref.watch(activeLearnerProvider)?.id;

    if (activeLearnerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Academic Profile')),
        body: const Center(
          child: Text('Please select an active learner to view their profile.'),
        ),
      );
    }

    final profileAsync =
        ref.watch(learnerSocialProfileProvider(activeLearnerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Identity & Social'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
              learnerSocialProfileProvider(activeLearnerId),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading profile: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    learnerSocialProfileProvider(activeLearnerId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => _buildProfileContent(context, profile),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    LearnerSocialProfile profile,
  ) {
    final theme = Theme.of(context);
    final avatar = getAvatarPreset(profile.avatarPreset);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Child Safety Notice Card
          Card(
            color: LearnTzColors.primary50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: LearnTzRadii.borderMd,
              side: const BorderSide(color: LearnTzColors.primary200),
            ),
            child: Padding(
              padding: LearnTzSpacing.allMd,
              child: Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: LearnTzColors.primary600,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Child-Safe Academic Identity',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LearnTzColors.primary700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personal details (real full names, phone numbers, exact birth dates, and locations) are strictly protected and never shown publicly.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LearnTzColors.primary800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Main Academic Identity Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: avatar.primaryColor,
                    child: Icon(
                      avatar.icon,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avatar.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: avatar.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        icon: Icons.star_rounded,
                        color: Colors.amber.shade700,
                        value: '${profile.points}',
                        label: 'Points',
                      ),
                      _buildStatItem(
                        context,
                        icon: Icons.military_tech_rounded,
                        color: Colors.indigo,
                        value: '${profile.badgesCount}',
                        label: 'Badges',
                      ),
                      _buildStatItem(
                        context,
                        icon: _getVisibilityIcon(profile.profileVisibility),
                        color: Colors.teal,
                        value: _formatVisibility(profile.profileVisibility),
                        label: 'Privacy',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Academic Interests
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        'Academic Interests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (profile.academicInterests.isEmpty)
                    Text(
                      'No interests added yet. Customize below!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.academicInterests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Edit Profile Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.edit),
            label: const Text(
              'Edit Profile & Privacy Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showEditDialog(context, profile),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'public':
        return Icons.public;
      case 'school_only':
        return Icons.school;
      case 'private':
        return Icons.lock;
      default:
        return Icons.visibility;
    }
  }

  String _formatVisibility(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'school_only':
        return 'School Only';
      case 'private':
        return 'Private';
      default:
        return visibility;
    }
  }

  void _showEditDialog(
    BuildContext context,
    LearnerSocialProfile profile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditProfileSheet(
        profile: profile,
        availableInterests: _availableInterests,
        onSaved: () {
          ref.invalidate(learnerSocialProfileProvider(profile.learnerId));
        },
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final LearnerSocialProfile profile;
  final List<String> availableInterests;
  final VoidCallback onSaved;

  const _EditProfileSheet({
    required this.profile,
    required this.availableInterests,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late String _selectedAvatar;
  late String _visibility;
  late List<String> _selectedInterests;
  late bool _allowFollowers;
  late bool _showAchievements;
  late bool _showCommunities;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _selectedAvatar = widget.profile.avatarPreset;
    _visibility = widget.profile.profileVisibility;
    _selectedInterests = List.from(widget.profile.academicInterests);
    _allowFollowers = widget.profile.allowFollowerRequests;
    _showAchievements = widget.profile.showAchievements;
    _showCommunities = widget.profile.showCommunities;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool _containsProhibitedInfo(String text) {
    // Check for phone number patterns, @ emails, or http links
    final phoneRegex = RegExp(r'([0-9]{3,}.*[0-9]{4,})');
    final emailRegex = RegExp(r'@');
    final linkRegex = RegExp(r'https?://');
    return phoneRegex.hasMatch(text) ||
        emailRegex.hasMatch(text) ||
        linkRegex.hasMatch(text);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.updateProfile(
        learnerId: widget.profile.learnerId,
        displayName: _nameController.text.trim(),
        avatarPreset: _selectedAvatar,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        academicInterests: _selectedInterests,
        profileVisibility: _visibility,
        allowFollowerRequests: _allowFollowers,
        showAchievements: _showAchievements,
        showCommunities: _showCommunities,
      );

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Academic profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Academic Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Avatar preset selector
              Text(
                'Choose Safe Educational Avatar',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kAvatarPresets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final preset = kAvatarPresets[index];
                    final isSelected = _selectedAvatar == preset.key;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = preset.key),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? preset.primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: preset.primaryColor,
                              child: Icon(
                                preset.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset.name.split(' ').first,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Display Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Learner Display Name',
                  hintText: 'e.g. StarReader or initials',
                  helperText:
                      'Child safety rule: Never use full names, phone numbers, or emails.',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (val.trim().length > 50) {
                    return 'Name cannot exceed 50 characters';
                  }
                  if (_containsProhibitedInfo(val)) {
                    return 'Phone numbers, emails, or links are strictly prohibited.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLength: 160,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Bio / Motto',
                  hintText: 'Share a favourite subject or study motto',
                  helperText: 'External links and contact info are blocked.',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != null && _containsProhibitedInfo(val)) {
                    return 'External links, emails, and phone numbers are prohibited.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Academic Interests
              Text(
                'Academic Interests',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Privacy Controls
              Text(
                'Privacy & Community Visibility',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Profile Visibility',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'school_only',
                    child: Text('School Only (Recommended)'),
                  ),
                  DropdownMenuItem(
                    value: 'public',
                    child: Text('All LearnTZ Learners (Public)'),
                  ),
                  DropdownMenuItem(
                    value: 'private',
                    child: Text('Private (Guardians & Staff only)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _visibility = val);
                },
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Allow Follower Requests'),
                subtitle: const Text(
                  'Peers can request to follow your academic updates',
                ),
                value: _allowFollowers,
                onChanged: (val) => setState(() => _allowFollowers = val),
              ),
              SwitchListTile(
                title: const Text('Show Achievements'),
                subtitle: const Text(
                  'Display study points and badges on profile',
                ),
                value: _showAchievements,
                onChanged: (val) => setState(() => _showAchievements = val),
              ),
              SwitchListTile(
                title: const Text('Show Communities'),
                subtitle: const Text(
                  'Display school and subject community groups',
                ),
                value: _showCommunities,
                onChanged: (val) => setState(() => _showCommunities = val),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save Academic Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
