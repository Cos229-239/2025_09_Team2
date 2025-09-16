// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing global app state
import 'package:provider/provider.dart';
// Import app state provider to manage authentication status
import 'package:studypals/providers/app_state.dart';
// Import User model for creating user objects
import 'package:studypals/models/user.dart';

/// Enhanced login/registration screen with email verification support
/// Supports both user registration and login with proper validation
class LoginScreen extends StatefulWidget {
  // Constructor with optional key for widget identification
  const LoginScreen({super.key});

  /// Creates the mutable state object for this widget
  /// @return State object that manages the login screen's dynamic behavior
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Private state class managing login/registration form data and user interactions
/// Handles form validation, authentication logic, loading states, and mode switching
class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation - uniquely identifies the form for validation methods
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form input fields
  final _emailController = TextEditingController(); // Email input management
  final _passwordController =
      TextEditingController(); // Password input management
  final _nameController =
      TextEditingController(); // Name input for registration
  final _confirmPasswordController =
      TextEditingController(); // Password confirmation

  // UI state management
  bool _isLoading = false; // Loading state during auth operations
  bool _isLoginMode =
      true; // Toggle between login (true) and register (false) modes
  bool _obscurePassword = true; // Toggle password visibility
  bool _obscureConfirmPassword = true; // Toggle confirm password visibility

  /// Builds the enhanced login/registration screen with mode switching
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the authentication screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // Allow scrolling for smaller screens
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App branding section
                const SizedBox(height: 40),
                _buildAppBranding(),
                const SizedBox(height: 48),

                // Mode toggle tabs (Login/Register)
                _buildModeToggle(),
                const SizedBox(height: 32),

                // Form fields based on current mode
                _buildFormFields(),
                const SizedBox(height: 24),

                // Primary action button (Login/Register)
                _buildPrimaryButton(),
                const SizedBox(height: 16),

                // Secondary actions
                _buildSecondaryActions(),
                const SizedBox(height: 24),

                // Guest login option
                _buildGuestLogin(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the app logo and branding section
  Widget _buildAppBranding() {
    return Column(
      children: [
        Icon(
          Icons.school,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'StudyPals',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          'Your AI-powered study companion',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the login/register mode toggle
  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLoginMode
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isLoginMode ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLoginMode
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Register',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isLoginMode ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds form fields based on current mode (login vs register)
  Widget _buildFormFields() {
    return Column(
      children: [
        // Name field (only for registration)
        if (!_isLoginMode) ...[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        // Email field
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password field
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (!_isLoginMode && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),

        // Confirm password field (only for registration)
        if (!_isLoginMode) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (!_isLoginMode) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  /// Builds the primary action button (Login/Register)
  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePrimaryAction,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_isLoginMode ? 'Login' : 'Create Account'),
    );
  }

  /// Builds secondary action links (forgot password, etc.)
  Widget _buildSecondaryActions() {
    return Column(
      children: [
        if (_isLoginMode) ...[
          TextButton(
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: const Text('Forgot Password?'),
          ),
        ] else ...[
          Text(
            'By creating an account, you agree to our Terms of Service and Privacy Policy.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Builds the guest login option
  Widget _buildGuestLogin() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _handleGuestLogin,
          child: const Text('Continue as Guest'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            final appState = Provider.of<AppState>(context, listen: false);
            await appState.resetAllUserData();

            // Clear form fields too
            setState(() {
              _emailController.clear();
              _passwordController.clear();
              _nameController.clear();
              _confirmPasswordController.clear();
              _isLoginMode = true;
            });

            // Check if the widget is still mounted before using context
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✅ All user data cleared! You can now register fresh accounts.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: Text(
            'Clear All User Data',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Handles the primary action (login or registration) based on current mode
  Future<void> _handlePrimaryAction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final appState = Provider.of<AppState>(context, listen: false);

        if (_isLoginMode) {
          // Handle login
          final user = await appState.signInUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (!mounted) return;

          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Welcome back, ${user.name}!')),
            );
          } else {
            // Show error from AppState if login failed
            final error = appState.error;
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
              appState.clearError();
            }
          }
        } else {
          // Handle registration
          final user = await appState.registerUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          );

          if (!mounted) return;

          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Registration successful! You can now log in immediately. (In production, you would need to verify your email first.)'),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.green,
              ),
            );

            // Switch to login mode after successful registration
            setState(() {
              _isLoginMode = true;
              _passwordController.clear();
              _confirmPasswordController.clear();
            });
          } else {
            // Show error from AppState if registration failed
            final error = appState.error;
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
              appState.clearError();
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Handles forgot password functionality
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.resetPassword(email: email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset instructions sent to your email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles guest login for users who want to try the app without creating an account
  void _handleGuestLogin() {
    // Import User model for guest creation
    final guestUser = User(
      id: 'guest',
      email: 'guest@studypals.com',
      name: 'Guest User',
      isEmailVerified: false,
    );

    Provider.of<AppState>(context, listen: false).login(guestUser);
  }

  /// Cleanup method called when widget is disposed
  /// Properly disposes all text controllers to prevent memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
