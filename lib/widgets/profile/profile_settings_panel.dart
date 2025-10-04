import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/social_learning_service.dart';

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

/// Profile settings panel widget with similar structure to profile panel
/// Displays privacy settings and preferences in a modern layout
class ProfileSettingsPanel extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final bool isBottomSheet;

  const ProfileSettingsPanel({
    super.key,
    this.onClose,
    this.onBack,
    this.isBottomSheet = false,
  });

  @override
  State<ProfileSettingsPanel> createState() => _ProfileSettingsPanelState();
}

class _ProfileSettingsPanelState extends State<ProfileSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  
  // Privacy settings state
  PrivacyLevel _profilePrivacy = PrivacyLevel.public;
  PrivacyLevel _progressPrivacy = PrivacyLevel.friends;
  PrivacyLevel _friendsPrivacy = PrivacyLevel.friends;
  
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        
        setState(() {
          _profilePrivacy = _parsePrivacyLevel(data?['profilePrivacy']);
          _progressPrivacy = _parsePrivacyLevel(data?['progressPrivacy']);
          _friendsPrivacy = _parsePrivacyLevel(data?['friendsPrivacy']);
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  PrivacyLevel _parsePrivacyLevel(String? value) {
    switch (value) {
      case 'public':
        return PrivacyLevel.public;
      case 'friends':
        return PrivacyLevel.friends;
      case 'private':
        return PrivacyLevel.private;
      default:
        return PrivacyLevel.public;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'profilePrivacy': _profilePrivacy.name,
        'progressPrivacy': _progressPrivacy.name,
        'friendsPrivacy': _friendsPrivacy.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Back/Close button
          GestureDetector(
            onTap: widget.onBack ?? widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (Theme.of(context).iconTheme.color ?? Colors.black).withOpacity(0.2),
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
          
          // Title
          Expanded(
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).iconTheme.color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy Settings Section
              _buildPrivacySection(),
              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
              const SizedBox(height: 20), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Control who can see your information and activity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 20),
        _buildPrivacyDropdown(
          'Profile Visibility',
          'Who can see your profile information',
          _profilePrivacy,
          (value) => setState(() => _profilePrivacy = value!),
        ),
        const SizedBox(height: 16),
        _buildPrivacyDropdown(
          'Progress Visibility',
          'Who can see your study progress and achievements',
          _progressPrivacy,
          (value) => setState(() => _progressPrivacy = value!),
        ),
        const SizedBox(height: 16),
        _buildPrivacyDropdown(
          'Friends List Visibility',
          'Who can see your friends and connections',
          _friendsPrivacy,
          (value) => setState(() => _friendsPrivacy = value!),
        ),
      ],
    );
  }

  Widget _buildPrivacyDropdown(
    String label,
    String description,
    PrivacyLevel currentValue,
    void Function(PrivacyLevel?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PrivacyLevel>(
          value: currentValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          items: PrivacyLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Row(
                children: [
                  Icon(
                    _getPrivacyIcon(level),
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(level.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  IconData _getPrivacyIcon(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.friends:
        return Icons.group;
      case PrivacyLevel.private:
        return Icons.lock;
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}