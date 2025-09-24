import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/social_learning_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _interests = [];
  PrivacyLevel _profilePrivacy = PrivacyLevel.public;
  PrivacyLevel _progressPrivacy = PrivacyLevel.friends;
  PrivacyLevel _friendsPrivacy = PrivacyLevel.friends;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final service = context.read<SocialLearningService>();
    final profile = service.currentUserProfile;

    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _usernameController.text = profile.username;
      _bioController.text = profile.bio ?? '';
      _interests = List<String>.from(profile.interests);
      _profilePrivacy = profile.profilePrivacy;
      _progressPrivacy = profile.progressPrivacy;
      _friendsPrivacy = profile.friendsPrivacy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Profile Picture Section
            _buildProfilePictureSection(),

            const SizedBox(height: 24),

            // Basic Information
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name is required';
                }
                if (value.trim().length < 2) {
                  return 'Display name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Bio cannot exceed 500 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Interests Section
            _buildInterestsSection(),

            const SizedBox(height: 24),

            // Privacy Settings
            _buildSectionTitle('Privacy Settings'),
            const SizedBox(height: 16),

            _buildPrivacyOption(
              'Profile Visibility',
              'Who can see your profile information',
              _profilePrivacy,
              (value) => setState(() => _profilePrivacy = value),
            ),

            const SizedBox(height: 16),

            _buildPrivacyOption(
              'Progress Visibility',
              'Who can see your study progress and stats',
              _progressPrivacy,
              (value) => setState(() => _progressPrivacy = value),
            ),

            const SizedBox(height: 16),

            _buildPrivacyOption(
              'Friends List Visibility',
              'Who can see your friends list',
              _friendsPrivacy,
              (value) => setState(() => _friendsPrivacy = value),
            ),

            const SizedBox(height: 32),

            // Account Actions
            _buildSectionTitle('Account'),
            const SizedBox(height: 16),

            _buildAccountAction(
              'Change Password',
              'Update your account password',
              Icons.lock,
              _changePassword,
            ),

            const SizedBox(height: 8),

            _buildAccountAction(
              'Export Data',
              'Download your study data',
              Icons.download,
              _exportData,
            ),

            const SizedBox(height: 8),

            _buildAccountAction(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever,
              _deleteAccount,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                    onPressed: _changeProfilePicture,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _changeProfilePicture,
            child: const Text('Change Profile Picture'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Interests'),
        const SizedBox(height: 8),
        Text(
          'Add topics you\'re interested in to help others find you',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._interests.map((interest) => Chip(
                  label: Text(interest),
                  onDeleted: () => _removeInterest(interest),
                  deleteIcon: const Icon(Icons.close, size: 18),
                )),
            ActionChip(
              label: const Text('Add Interest'),
              onPressed: _addInterest,
              avatar: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyOption(
    String title,
    String description,
    PrivacyLevel currentValue,
    ValueChanged<PrivacyLevel> onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PrivacyLevel>(
              segments: const [
                ButtonSegment(
                  value: PrivacyLevel.public,
                  label: Text('Public'),
                  icon: Icon(Icons.public),
                ),
                ButtonSegment(
                  value: PrivacyLevel.friends,
                  label: Text('Friends'),
                  icon: Icon(Icons.people),
                ),
                ButtonSegment(
                  value: PrivacyLevel.private,
                  label: Text('Private'),
                  icon: Icon(Icons.lock),
                ),
              ],
              selected: {currentValue},
              onSelectionChanged: (Set<PrivacyLevel> newSelection) {
                onChanged(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountAction(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Theme.of(context).colorScheme.error : null;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _addInterest() {
    showDialog<String>(
      context: context,
      builder: (context) => _AddInterestDialog(),
    ).then((interest) {
      if (interest != null && interest.trim().isNotEmpty) {
        final trimmedInterest = interest.trim();
        if (!_interests.contains(trimmedInterest) && _interests.length < 10) {
          setState(() {
            _interests.add(trimmedInterest);
          });
        }
      }
    });
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  void _changeProfilePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture change - Coming soon!'),
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password change - Coming soon!'),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export - Coming soon!'),
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion - Coming soon!'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = context.read<SocialLearningService>();
      final currentProfile = service.currentUserProfile;

      if (currentProfile != null) {
        // Update profile with new data
        await service.updateUserProfile(
          displayName: _displayNameController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          interests: _interests,
          profilePrivacy: _profilePrivacy,
          progressPrivacy: _progressPrivacy,
          friendsPrivacy: _friendsPrivacy,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _AddInterestDialog extends StatefulWidget {
  @override
  State<_AddInterestDialog> createState() => _AddInterestDialogState();
}

class _AddInterestDialogState extends State<_AddInterestDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Interest'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Interest',
            hintText: 'e.g., Mathematics, History, Programming',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an interest';
            }
            if (value.trim().length > 20) {
              return 'Interest must be 20 characters or less';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }
}
