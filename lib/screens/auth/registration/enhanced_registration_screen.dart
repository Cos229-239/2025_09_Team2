import 'package:flutter/material.dart';
import '../../../services/optimized_registration_service.dart';
import '../../../utils/registration_validator.dart';
import '../../../widgets/common/animated_particle_background.dart';
import '../email_verification_screen.dart';

/// Enhanced multi-step registration screen with comprehensive validation
/// Provides a smooth user experience with step-by-step account creation
class EnhancedRegistrationScreen extends StatefulWidget {
  const EnhancedRegistrationScreen({super.key});

  @override
  State<EnhancedRegistrationScreen> createState() =>
      _EnhancedRegistrationScreenState();
}

class _EnhancedRegistrationScreenState extends State<EnhancedRegistrationScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OptimizedRegistrationService _registrationService = OptimizedRegistrationService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form keys for each step
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Controllers for all form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();

  // Form state
  int _currentStep = 0;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  DateTime? _selectedDateOfBirth;
  int? _graduationYear;
  PasswordStrength? _passwordStrength;

  // Validation state
  String? _generalError;

  // Focus nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _fullNameFocus = FocusNode();
  final _usernameFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    // Add password strength listener
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _schoolController.dispose();
    _majorController.dispose();

    // Dispose focus nodes
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fullNameFocus.dispose();
    _usernameFocus.dispose();

    super.dispose();
  }

  void _updatePasswordStrength() {
    if (mounted) {
      setState(() {
        _passwordStrength = RegistrationValidator.calculatePasswordStrength(
            _passwordController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedParticleBackground(
        gradientColors: [
          Theme.of(context).primaryColor.withValues(alpha: 0.1),
          Theme.of(context).primaryColor.withValues(alpha: 0.05),
        ],
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildProgressIndicator(),
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1(), // Account Details
                            _buildStep2(), // Personal Information
                            _buildStep3(), // Terms & Confirmation
                          ],
                        ),
                      ),
                    ),
                    _buildBottomNavigation(),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStepDescription(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Set up your login credentials';
      case 1:
        return 'Tell us a bit about yourself';
      case 2:
        return 'Review and confirm your account';
      default:
        return '';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Full Name Field
            _buildTextField(
              controller: _fullNameController,
              focusNode: _fullNameFocus,
              label: 'Full Name',
              hint: 'Enter your first and last name',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  RegistrationValidator.validateFullName(value ?? ''),
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Email Field
            _buildTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: 'Email Address',
              hint: 'Enter your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  RegistrationValidator.validateEmail(value ?? ''),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              hint: 'Create a strong password',
              icon: Icons.lock_outline,
              obscureText: !_passwordVisible,
              validator: (value) =>
                  RegistrationValidator.validatePassword(value ?? ''),
              onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off),
              ),
            ),

            // Password Strength Indicator
            if (_passwordStrength != null &&
                _passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordStrengthIndicator(),
            ],

            const SizedBox(height: 20),

            // Confirm Password Field
            _buildTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: !_confirmPasswordVisible,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              suffixIcon: IconButton(
                onPressed: () => setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible),
                icon: Icon(_confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
              ),
            ),

            const SizedBox(height: 20),

            // Username Field (Optional)
            _buildTextField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              label: 'Username (Optional)',
              hint: 'Choose a unique username',
              icon: Icons.alternate_email,
              validator: (value) =>
                  RegistrationValidator.validateUsername(value ?? ''),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Phone Number (Optional)
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number (Optional)',
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  RegistrationValidator.validatePhoneNumber(value),
            ),

            const SizedBox(height: 20),

            // Date of Birth (Optional)
            _buildDatePicker(),

            const SizedBox(height: 20),

            // Location (Optional)
            _buildTextField(
              controller: _locationController,
              label: 'Location (Optional)',
              hint: 'City, State/Country',
              icon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 20),

            // School (Optional)
            _buildTextField(
              controller: _schoolController,
              label: 'School/University (Optional)',
              hint: 'Your educational institution',
              icon: Icons.school_outlined,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 20),

            // Major (Optional)
            _buildTextField(
              controller: _majorController,
              label: 'Major/Field of Study (Optional)',
              hint: 'Your field of study',
              icon: Icons.menu_book_outlined,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 20),

            // Graduation Year (Optional)
            _buildGraduationYearPicker(),

            const SizedBox(height: 20),

            // Bio (Optional)
            _buildTextField(
              controller: _bioController,
              label: 'Bio (Optional)',
              hint: 'Tell others about yourself (max 500 characters)',
              icon: Icons.info_outline,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Account Summary
            _buildAccountSummary(),

            const SizedBox(height: 32),

            // Terms and Conditions
            _buildCheckboxTile(
              value: _acceptedTerms,
              onChanged: (value) =>
                  setState(() => _acceptedTerms = value ?? false),
              title: 'I accept the Terms and Conditions',
              subtitle:
                  'By creating an account, you agree to our terms of service.',
              onTap: () => _showTermsDialog(),
            ),

            const SizedBox(height: 16),

            // Privacy Policy
            _buildCheckboxTile(
              value: _acceptedPrivacy,
              onChanged: (value) =>
                  setState(() => _acceptedPrivacy = value ?? false),
              title: 'I accept the Privacy Policy',
              subtitle:
                  'Learn how we protect and use your personal information.',
              onTap: () => _showPrivacyDialog(),
            ),

            const SizedBox(height: 32),

            // Error message
            if (_generalError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _generalError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // Helper Methods

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordStrength == null) return const SizedBox.shrink();

    final strength = _passwordStrength!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: strength.score / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(
                          int.parse(strength.color.substring(1), radix: 16) +
                              0xFF000000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strength.level,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(int.parse(strength.color.substring(1), radix: 16) +
                    0xFF000000),
              ),
            ),
          ],
        ),
        if (strength.feedback.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            strength.feedback.join(', '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDateOfBirth(),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth (Optional)',
          hintText: 'Select your date of birth',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        child: Text(
          _selectedDateOfBirth != null
              ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
              : 'Select date',
          style: _selectedDateOfBirth != null
              ? Theme.of(context).textTheme.bodyLarge
              : Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
        ),
      ),
    );
  }

  Widget _buildGraduationYearPicker() {
    return InkWell(
      onTap: () => _selectGraduationYear(),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expected Graduation Year (Optional)',
          hintText: 'Select graduation year',
          prefixIcon: const Icon(Icons.school_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        child: Text(
          _graduationYear != null ? _graduationYear.toString() : 'Select year',
          style: _graduationYear != null
              ? Theme.of(context).textTheme.bodyLarge
              : Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
        ),
      ),
    );
  }

  Widget _buildAccountSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem('Name', _fullNameController.text),
          _buildSummaryItem('Email', _emailController.text),
          if (_usernameController.text.isNotEmpty)
            _buildSummaryItem('Username', _usernameController.text),
          if (_phoneController.text.isNotEmpty)
            _buildSummaryItem('Phone', _phoneController.text),
          if (_selectedDateOfBirth != null)
            _buildSummaryItem('Date of Birth',
                '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'),
          if (_locationController.text.isNotEmpty)
            _buildSummaryItem('Location', _locationController.text),
          if (_schoolController.text.isNotEmpty)
            _buildSummaryItem('School', _schoolController.text),
          if (_majorController.text.isNotEmpty)
            _buildSummaryItem('Major', _majorController.text),
          if (_graduationYear != null)
            _buildSummaryItem('Graduation Year', _graduationYear.toString()),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _currentStep > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 2 ? 'Create Account' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _generalError = null;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() async {
    if (_currentStep < 2) {
      // Validate current step
      bool isValid = false;

      switch (_currentStep) {
        case 0:
          isValid = _step1FormKey.currentState?.validate() ?? false;
          if (isValid) {
            // Check password strength
            final strength = RegistrationValidator.calculatePasswordStrength(
                _passwordController.text);
            if (!strength.isAcceptable) {
              setState(() {
                _generalError =
                    'Please choose a stronger password before continuing.';
              });
              return;
            }
            // Check password confirmation
            if (_passwordController.text != _confirmPasswordController.text) {
              setState(() {
                _generalError = 'Passwords do not match.';
              });
              return;
            }
          }
          break;
        case 1:
          isValid = _step2FormKey.currentState?.validate() ?? false;
          break;
      }

      if (isValid) {
        setState(() {
          _currentStep++;
          _generalError = null;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Final step - create account
      await _createAccount();
    }
  }

  Future<void> _createAccount() async {
    // Validate terms acceptance
    if (!_acceptedTerms || !_acceptedPrivacy) {
      setState(() {
        _generalError =
            'Please accept the Terms and Conditions and Privacy Policy to continue.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final result = await _registrationService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        school: _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
        major: _majorController.text.trim().isEmpty
            ? null
            : _majorController.text.trim(),
        graduationYear: _graduationYear,
      );

      if (result.success && result.user != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );

          if (result.requiresEmailVerification) {
            // Production mode: Navigate to email verification screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: result.user!.email ?? '',
                  displayName: result.user!.displayName ?? 'User',
                ),
              ),
            );
          } else {
            // Debug mode: Email is already verified, user will be authenticated automatically
            // Show a brief message and let AuthWrapper handle navigation to dashboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Debug mode: Redirecting to dashboard...'),
                duration: Duration(seconds: 1),
              ),
            );
            // Navigate back to auth wrapper which will detect the authenticated user
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      } else {
        // Show error
        setState(() {
          _generalError = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _generalError = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13), // COPPA compliance
      helpText: 'Select your date of birth',
    );

    if (date != null) {
      setState(() {
        _selectedDateOfBirth = date;
      });
    }
  }

  Future<void> _selectGraduationYear() async {
    final now = DateTime.now();
    final years = List.generate(20, (index) => now.year + index);

    final year = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Graduation Year'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              return ListTile(
                title: Text(year.toString()),
                onTap: () => Navigator.pop(context, year),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (year != null) {
      setState(() {
        _graduationYear = year;
      });
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By using StudyPals, you agree to the following terms:\n\n'
            '1. You will use the app for educational purposes only.\n'
            '2. You will not share inappropriate content.\n'
            '3. You will respect other users and maintain a positive learning environment.\n'
            '4. You understand that we collect and process data as described in our Privacy Policy.\n'
            '5. You are responsible for keeping your account secure.\n\n'
            'These terms may be updated from time to time. Continued use of the app constitutes acceptance of any changes.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'StudyPals Privacy Policy:\n\n'
            'We collect and process personal information to provide our study services:\n\n'
            '• Account Information: Name, email, username for account management\n'
            '• Profile Information: Bio, school, major for personalization\n'
            '• Study Data: Progress, scores, achievements for tracking improvement\n'
            '• Usage Data: App interactions for improving our services\n\n'
            'We do not sell personal information to third parties.\n'
            'We use industry-standard security measures to protect your data.\n'
            'You can request data deletion by contacting support.\n\n'
            'For questions, email privacy@studypals.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
