// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing global app state
import 'package:provider/provider.dart';
// Import app state provider to manage authentication status
import 'package:studypals/providers/app_state.dart';
// Import User model for creating user objects
import 'package:studypals/models/user.dart';

/// Modern login screen with cat mascot design
/// Matches the beautiful UI provided in the design mockup
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50), // Dark blue-gray
              Color(0xFF34495E), // Slightly lighter blue-gray
              Color(0xFF3A5166), // Medium blue-gray
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Cat mascot and branding
                  _buildMascotSection(),
                  const SizedBox(height: 60),
                  // Login form
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildEmailField(),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 30),
                            _buildLoginButton(),
                            const SizedBox(height: 30),
                            _buildBottomLinks(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotSection() {
    return Column(
      children: [
        // Cat mascot container
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF4A6B7C).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF5A7A8B).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cat illustration (using emojis and icons to simulate the design)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cat head with headphones
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Headphones
                      const Icon(
                        Icons.headset,
                        size: 50,
                        color: Color(0xFF7FA8B8),
                      ),
                      // Cat face
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            // Cat ears
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C3E50),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 8,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C3E50),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Cat face
                            Container(
                              width: 30,
                              height: 25,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Glasses
                                  Container(
                                    width: 24,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE67E22),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFE67E22),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFE67E22),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Book/study element
                  Container(
                    width: 20,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A085),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // App name
        Text(
          'STUDYPALS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A6B7C).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF5A7A8B).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'EMAIL',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A6B7C).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF5A7A8B).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'PASSWORD',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF16A085),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
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
                'LOGIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _handleSignUp,
              child: Text(
                'SIGN UP',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            TextButton(
              onPressed: _handleForgotPassword,
              child: Text(
                'FORGOT PASSWORD?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Guest login option
        TextButton(
          onPressed: _handleGuestLogin,
          child: const Text(
            'Continue as Guest',
            style: TextStyle(
              color: Color(0xFF16A085),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final appState = Provider.of<AppState>(context, listen: false);
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
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _handleSignUp() {
    // For now, show a simple dialog for registration
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registration feature coming soon!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            Text(
              'For now, you can:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Continue as Guest\n• Use demo@studypals.com / password',
              style: TextStyle(color: Color(0xFF16A085), fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF16A085)),
            ),
          ),
        ],
      ),
    );
  }

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset feature coming soon!'),
        backgroundColor: Color(0xFF16A085),
      ),
    );
  }

  void _handleGuestLogin() {
    final guestUser = User(
      id: 'guest',
      email: 'guest@studypals.com',
      name: 'Guest User',
      isEmailVerified: false,
    );

    Provider.of<AppState>(context, listen: false).login(guestUser);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
