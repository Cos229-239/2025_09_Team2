import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../services/social_learning_service.dart';
import '../../screens/dashboard_screen.dart'; // Import for SettingsGearPainter
import '../../providers/app_state.dart';

/// Extension to add display names to PrivacyLevel enum
extension PrivacyLevelExtension on PrivacyLevel {
  String get displayName {
    switch (this) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.friends:
        return 'Friends Only';
      case PrivacyLevel.private:
        return 'Private';
    }
  }
}

/// Profile panel widget with similar structure to notification panel
/// Displays user profile information and settings in a modern layout
class ProfilePanel extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isBottomSheet;

  const ProfilePanel({
    super.key,
    this.onClose,
    this.isBottomSheet = false,
  });

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _interests = [];
  bool _isLoading = false;
  String? _avatarUrl;

  // Badge system
  final List<String> _availableBadges = [
    'Study Streak',
    'Early Bird',
    'Night Owl',
    'Flash Master',
    'Goal Crusher',
    'Team Player',
    'Quick Learner',
    'Persistent',
    'Creative Thinker',
    'Helper',
    'Focus Master',
    'Time Manager',
    'Knowledge Seeker',
    'Problem Solver',
    'Achiever'
  ];
  List<String> _selectedBadges = [];

  // Settings view state
  bool _isShowingSettings = false;

  // Additional privacy settings for settings view
  bool _profileVisibility = true;
  bool _onlineStatus = true;
  bool _studyProgress = true;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _displayNameController.text = data['displayName'] ?? '';
            _usernameController.text = data['username'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _avatarUrl = data['avatarUrl'];
            _interests = List<String>.from(data['interests'] ?? []);
            _selectedBadges = List<String>.from(data['featuredBadges'] ?? []);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isBottomSheet
          ? MediaQuery.of(context).size.height * 0.8
          : null,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : null,
        boxShadow: widget.isBottomSheet
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // If height is very small during animation, show minimal content
            if (constraints.maxHeight < 100) {
              return Container(
                height: constraints.maxHeight,
                width: double.infinity,
                color: Colors.transparent,
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with user name and controls
                _buildHeader(context),

                // Profile content - takes remaining space
                Expanded(
                  child: _buildProfileContent(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build the header section with user name and action buttons
  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _displayNameController.text.isNotEmpty
        ? _displayNameController.text
        : user?.displayName ?? 'User Profile';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242628),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Show back button when in settings view
          if (_isShowingSettings) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _isShowingSettings = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (Theme.of(context).iconTheme.color ?? Colors.black)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color ?? Colors.black,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Title - changes based on view
          Expanded(
            child: Text(
              _isShowingSettings ? 'Settings' : userName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isShowingSettings
                        ? (Theme.of(context).iconTheme.color ?? Colors.black)
                        : null,
                  ),
            ),
          ),

          // Action buttons - only show in profile view
          if (!_isShowingSettings) ...[
            Row(
              children: [
                // Settings button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isShowingSettings = !_isShowingSettings;
                    });
                  },
                  child: CustomPaint(
                    size: const Size(24, 24),
                    painter: SettingsGearPainter(
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Logout button
                GestureDetector(
                  onTap: _handleLogout,
                  child: Icon(
                    Icons.logout,
                    color: const Color(0xFF6FB8E9),
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build the main profile content
  Widget _buildProfileContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show settings content or profile content based on current view
    return _isShowingSettings
        ? _buildSettingsContent()
        : _buildMainProfileContent();
  }

  Widget _buildMainProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            _buildProfilePictureSection(),
            const SizedBox(height: 24),

            // Basic Information Section
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Bio Section
            _buildBioSection(),
            const SizedBox(height: 24),

            // Interests Section
            _buildInterestsSection(),
            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(),
            const SizedBox(
                height:
                    247), // Extended space at bottom (original spacing restored)
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy Settings Section
          _buildPrivacySection(),
          const SizedBox(height: 24),

          // Account Settings Section
          _buildAccountSection(),
          const SizedBox(height: 247), // Same bottom spacing as profile content
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      elevation: 1,
      color: const Color(0xFF242628),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Profile Visibility'),
              subtitle: const Text('Allow others to see your profile'),
              value: _profileVisibility,
              onChanged: (value) {
                setState(() {
                  _profileVisibility = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Online Status'),
              subtitle: const Text('Show when you\'re online'),
              value: _onlineStatus,
              onChanged: (value) {
                setState(() {
                  _onlineStatus = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Study Progress'),
              subtitle: const Text('Share your study progress with friends'),
              value: _studyProgress,
              onChanged: (value) {
                setState(() {
                  _studyProgress = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      elevation: 1,
      color: const Color(0xFF242628),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.security,
                color: Theme.of(context).iconTheme.color,
              ),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implement password change functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password change coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.email,
                color: Theme.of(context).iconTheme.color,
              ),
              title: const Text('Change Email'),
              subtitle: const Text('Update your email address'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implement email change functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email change coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implement account deletion functionality
                _showDeleteAccountDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Profile Picture',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6FB8E9),
                  width: 3,
                ),
              ),
              child: _avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Picture'),
          ),
          const SizedBox(height: 16),

          // Featured Badges Section
          _buildFeaturedBadges(),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadges() {
    return Column(
      children: [
        Text(
          'Featured Badges',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6FB8E9),
              ),
        ),
        const SizedBox(height: 12),

        // Display selected badges (all clickable)
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => GestureDetector(
                onTap: () => _showBadgeSelectionDialog(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index < _selectedBadges.length ? null : 60,
                  height: 30,
                  child: index < _selectedBadges.length
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                            border: Border.all(
                                color: const Color(0xFF6FB8E9)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _selectedBadges[index],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6FB8E9),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey[300]!, width: 1.5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBadgeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Featured Badges'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'Choose up to 3 badges to display on your profile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: _availableBadges.map((badge) {
                    final isSelected = _selectedBadges.contains(badge);
                    return CheckboxListTile(
                      title: Text(badge),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (_selectedBadges.length < 3) {
                              _selectedBadges.add(badge);
                            }
                          } else {
                            _selectedBadges.remove(badge);
                          }
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                      enabled: isSelected || _selectedBadges.length < 3,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selected: ${_selectedBadges.length}/3',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _selectedBadges.length == 3
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Auto-save badges when dialog closes
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          style: const TextStyle(color: Color(0xFFD9D9D9)),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: const TextStyle(color: Color(0xFF888888)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF242628),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Display name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          style: const TextStyle(color: Color(0xFFD9D9D9)),
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: const TextStyle(color: Color(0xFF888888)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF242628),
            prefixText: '@',
            prefixStyle: const TextStyle(color: Color(0xFF6FB8E9)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Username can only contain letters, numbers, and underscores';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          style: const TextStyle(color: Color(0xFFD9D9D9)),
          decoration: InputDecoration(
            labelText: 'Tell us about yourself',
            labelStyle: const TextStyle(color: Color(0xFF888888)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF242628),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          maxLength: 160,
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._interests.map((interest) => Chip(
                  label: Text(
                    interest,
                    style: const TextStyle(color: Color(0xFFD9D9D9)),
                  ),
                  backgroundColor: const Color(0xFF242628),
                  side: BorderSide(
                    color: const Color(0xFF6FB8E9).withValues(alpha: 0.5),
                  ),
                  deleteIconColor: const Color(0xFF6FB8E9),
                  onDeleted: () => _removeInterest(interest),
                )),
            ActionChip(
              label: const Text(
                '+ Add Interest',
                style: TextStyle(color: Color(0xFF6FB8E9)),
              ),
              backgroundColor: const Color(0xFF242628),
              side: const BorderSide(color: Color(0xFF6FB8E9)),
              onPressed: _showAddInterestDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6FB8E9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Read and process the image
        final bytes = await image.readAsBytes();
        final processedBytes = await _processImage(bytes);
        final base64String = base64Encode(processedBytes);

        // Update avatar URL (in a real app, you'd upload to storage)
        setState(() {
          _avatarUrl = 'data:image/jpeg;base64,$base64String';
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _processImage(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Resize and compress
    final resized = img.copyResize(image, width: 256, height: 256);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  void _showAddInterestDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interest'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Interest',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final interest = controller.text.trim();
              if (interest.isNotEmpty && !_interests.contains(interest)) {
                setState(() {
                  _interests.add(interest);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _displayNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
          'avatarUrl': _avatarUrl,
          'interests': _interests,
          'featuredBadges': _selectedBadges,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _handleLogout() async {
    // Capture the AppState provider reference before any async operations
    final appState = Provider.of<AppState>(context, listen: false);
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        // Sign out the user through AppState (same as settings screen)
        await appState.logout();
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
