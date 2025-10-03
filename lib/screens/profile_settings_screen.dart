import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../services/social_learning_service.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

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
  String? _avatarUrl;
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> _loadCurrentProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, try to load from SocialLearningService
      final service = context.read<SocialLearningService>();
      final profile = service.currentUserProfile;

      if (profile != null) {
        setState(() {
          _displayNameController.text = profile.displayName;
          _usernameController.text = profile.username;
          _bioController.text = profile.bio ?? '';
          _interests = List<String>.from(profile.interests);
          _profilePrivacy = profile.profilePrivacy;
          _progressPrivacy = profile.progressPrivacy;
          _friendsPrivacy = profile.friendsPrivacy;
          _avatarUrl = profile.avatar;
        });
      } else {
        // If not in service, load directly from Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data()!;
            setState(() {
              _displayNameController.text = data['displayName'] ?? '';
              _usernameController.text = data['username'] ?? '';
              _bioController.text = data['bio'] ?? '';
              _avatarUrl = data['profilePicture'];
              
              // Load interests
              if (data['interests'] != null) {
                _interests = List<String>.from(data['interests']);
              }
              
              // Load privacy settings
              final privacy = data['privacySettings'] as Map<String, dynamic>?;
              if (privacy != null) {
                _profilePrivacy = _parsePrivacyLevel(privacy['profileVisibility']);
                _progressPrivacy = _parsePrivacyLevel(privacy['progressVisibility']);
                _friendsPrivacy = _parsePrivacyLevel(privacy['friendsVisibility']);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PrivacyLevel _parsePrivacyLevel(String? value) {
    if (value == null) return PrivacyLevel.public;
    return PrivacyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrivacyLevel.public,
    );
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
              _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: CachedNetworkImageProvider(_avatarUrl!),
                      backgroundColor: Colors.grey.shade200,
                    )
                  : CircleAvatar(
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

  Future<void> _changeProfilePicture() async {
    try {
      debugPrint('📸 Starting profile picture change...');
      
      setState(() {
        _isLoading = true;
      });

      // Get current user ID from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        throw Exception('User not authenticated');
      }
      
      debugPrint('✅ User authenticated: ${user.uid}');

      // Pick image with minimal compression first
      debugPrint('📸 Picking image...');
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ No image selected');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      debugPrint('✅ Image selected: ${pickedFile.name}');
      
      // Read image as bytes
      Uint8List bytes = Uint8List.fromList(await pickedFile.readAsBytes());
      debugPrint('📦 Initial image size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
      
      // If image is too large, compress it further using the image package
      if (bytes.length > 300 * 1024) {
        debugPrint('🔄 Image too large, applying additional compression...');
        
        // Decode the image
        img.Image? image = img.decodeImage(bytes);
        if (image == null) {
          throw Exception('Failed to decode image');
        }
        
        // Resize to max 400x400 to ensure it fits
        img.Image resized = img.copyResize(image, width: 400, height: 400);
        
        // Encode with quality adjustment to hit target size
        int quality = 75;
        do {
          bytes = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
          debugPrint('🔄 Compressed to ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB) at quality $quality%');
          quality -= 10;
        } while (bytes.length > 300 * 1024 && quality > 20);
        
        if (bytes.length > 300 * 1024) {
          throw Exception('Could not compress image to under 300 KB. Please select a smaller image.');
        }
        
        debugPrint('✅ Successfully compressed to ${(bytes.length / 1024).toStringAsFixed(1)} KB');
      }
      
      // Convert to Base64
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';
      
      debugPrint('✅ Converted to Base64 (${dataUrl.length} characters)');

      // Save directly to Firestore
      debugPrint('📝 Updating Firestore with Base64 image...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profilePicture': dataUrl,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Firestore updated successfully');

      // Update avatar URL in state
      setState(() {
        _avatarUrl = dataUrl;
        _isLoading = false;
      });
      
      debugPrint('✅ UI state updated');

      // Update SocialLearningService if it has a profile
      try {
        final service = context.read<SocialLearningService>();
        if (service.currentUserProfile != null) {
          await service.updateUserProfile(avatar: dataUrl);
          debugPrint('✅ SocialLearningService updated');
        } else {
          debugPrint('⚠️ SocialLearningService has no profile, skipping');
        }
      } catch (e) {
        debugPrint('⚠️ Could not update SocialLearningService: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating profile picture: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

    debugPrint('📝 Starting profile save...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      debugPrint('✅ User authenticated: ${user.uid}');

      // Prepare the data to save
      final updateData = {
        'displayName': _displayNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'interests': _interests, // Add interests to Firestore save
        'privacySettings': {
          'profileVisibility': _profilePrivacy.name,
          'progressVisibility': _progressPrivacy.name,
          'friendsVisibility': _friendsPrivacy.name,
        },
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

      // Only add avatar if it's been set
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        updateData['profilePicture'] = _avatarUrl;
      }

      debugPrint('📦 Saving data: $updateData');

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);
      
      debugPrint('✅ Firestore update successful');

      // Log activity
      try {
        final activityService = ActivityService();
        await activityService.logActivity(
          type: ActivityType.profileUpdated,
          description: 'Updated profile information',
          metadata: {
            'displayName': _displayNameController.text.trim(),
            'username': _usernameController.text.trim(),
          },
        );
      } catch (e) {
        debugPrint('Failed to log profile update activity: $e');
      }

      // Also update the SocialLearningService if it has a profile
      final service = context.read<SocialLearningService>();
      if (service.currentUserProfile != null) {
        await service.updateUserProfile(
          displayName: _displayNameController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          avatar: _avatarUrl,
          interests: _interests,
          profilePrivacy: _profilePrivacy,
          progressPrivacy: _progressPrivacy,
          friendsPrivacy: _friendsPrivacy,
        );
        debugPrint('✅ SocialLearningService update successful');
      } else {
        debugPrint('⚠️ SocialLearningService has no profile, skipping');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
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
