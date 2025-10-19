// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Firebase services
import 'package:studypals/services/firebase_auth_service.dart';
import 'package:studypals/services/firestore_service.dart';
import 'package:studypals/screens/auth/email_verification_screen.dart';

/// Modern signup screen that matches the app's Material 3 design system
class SignupScreenNew extends StatefulWidget {
  const SignupScreenNew({super.key});

  @override
  State<SignupScreenNew> createState() => _SignupScreenNewState();
}

class _SignupScreenNewState extends State<SignupScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF16181A), // Dark background matching login screen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF6FB8E9), // Match learning screen accent color
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // App branding section
              _buildBrandingSection(context),

              const SizedBox(height: 40),

              // Signup form card
              _buildSignupCard(context),

              const SizedBox(height: 24),

              // Bottom links
              _buildBottomLinks(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection(BuildContext context) {
    return Column(
      children: [
        // App logo/icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6FB8E9), // Match learning screen accent color
                const Color(0xFF6FB8E9).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.school,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Join StudyPals',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(
                    0xFF6FB8E9), // Match learning screen accent color
              ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Start your AI-powered learning journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFD9D9D9)
                    .withValues(alpha: 0.7), // Match learning screen text
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignupCard(BuildContext context) {
    return Card(
      elevation: 1,
      color:
          const Color(0xFF242628), // Match learning screen task card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF6FB8E9)
              .withValues(alpha: 0.3), // Match learning screen border
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(
                          0xFFD9D9D9), // Match learning screen text color
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in your details to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD9D9D9)
                          .withValues(alpha: 0.7), // Match learning screen text
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                    color: Color(0xFFD9D9D9)), // Match learning screen text
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(
                      color: Color(0xFFB0B0B0)), // Lighter gray for label
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(
                      color: const Color(0xFFD9D9D9).withValues(alpha: 0.5)),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color:
                        Color(0xFF6FB8E9), // Match learning screen accent color
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A), // Darker fill color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(
                          0xFF6FB8E9), // Match learning screen accent color
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    color: Color(0xFFD9D9D9)), // Match learning screen text
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(
                      color: Color(0xFFB0B0B0)), // Lighter gray for label
                  hintText: 'Enter your email address',
                  hintStyle: TextStyle(
                      color: const Color(0xFFD9D9D9).withValues(alpha: 0.5)),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color:
                        Color(0xFF6FB8E9), // Match learning screen accent color
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A), // Darker fill color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(
                          0xFF6FB8E9), // Match learning screen accent color
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                    color: Color(0xFFD9D9D9)), // Match learning screen text
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(
                      color: Color(0xFFB0B0B0)), // Lighter gray for label
                  hintText: 'Create a strong password',
                  hintStyle: TextStyle(
                      color: const Color(0xFFD9D9D9).withValues(alpha: 0.5)),
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    color:
                        Color(0xFF6FB8E9), // Match learning screen accent color
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(
                          0xFF6FB8E9), // Match learning screen accent color
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A), // Darker fill color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(
                          0xFF6FB8E9), // Match learning screen accent color
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                      .hasMatch(value)) {
                    return 'Password must contain uppercase, lowercase, and number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(
                    color: Color(0xFFD9D9D9)), // Match learning screen text
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(
                      color: Color(0xFFB0B0B0)), // Lighter gray for label
                  hintText: 'Re-enter your password',
                  hintStyle: TextStyle(
                      color: const Color(0xFFD9D9D9).withValues(alpha: 0.5)),
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    color:
                        Color(0xFF6FB8E9), // Match learning screen accent color
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(
                          0xFF6FB8E9), // Match learning screen accent color
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A), // Darker fill color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(
                          0xFF6FB8E9), // Match learning screen accent color
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Terms and conditions checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(
                        0xFF6FB8E9), // Match learning screen accent color
                    checkColor: Colors.white,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreeToTerms = !_agreeToTerms;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Color(
                                  0xFFD9D9D9), // Match learning screen text
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Color(
                                      0xFF6FB8E9), // Match learning screen accent color
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(
                                      0xFF6FB8E9), // Match learning screen accent color
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Signup button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || !_agreeToTerms) ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFF6FB8E9), // Match learning screen accent color
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF6FB8E9).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildBottomLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: Color(0xFFD9D9D9), // Match learning screen text
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF6FB8E9), // Match learning screen accent color
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseAuthService = FirebaseAuthService();
      final firestoreService = FirestoreService();

      // Sign up with Firebase
      final result = await firebaseAuthService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (result.success && result.user != null) {
        // Create user profile in Firestore
        await firestoreService.createUserProfile(
          uid: result.user!.uid,
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please verify your email.'),
              backgroundColor: null,
            ),
          );

          // Navigate to email verification screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text.trim(),
                displayName: _nameController.text.trim(),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
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
