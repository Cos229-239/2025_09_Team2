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
              Color(0xFF1a2332), // Very dark blue-gray
              Color(0xFF253142), // Dark blue-gray  
              Color(0xFF2a3543), // Slightly lighter dark blue-gray
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Cat mascot and branding
                _buildMascotSection(),
                const Spacer(),
                // Login form
                _buildLoginForm(),
                const SizedBox(height: 40),
                _buildBottomLinks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotSection() {
    return Column(
      children: [
        // Cat mascot container - exactly like the image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF3d4a5c), // Medium blue-gray for container
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cat with headphones and glasses
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Headphones band (top)
                      Positioned(
                        top: 8,
                        child: Container(
                          width: 65,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5a6b7d),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      
                      // Left headphone cup
                      Positioned(
                        top: 14,
                        left: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5a6b7d),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      
                      // Right headphone cup
                      Positioned(
                        top: 14,
                        right: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5a6b7d),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      
                      // Cat head (main body)
                      Positioned(
                        top: 20,
                        child: Container(
                          width: 50,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a2332), // Dark cat color
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      
                      // Cat ears
                      Positioned(
                        top: 12,
                        left: 20,
                        child: Container(
                          width: 12,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1a2332),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 20,
                        child: Container(
                          width: 12,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1a2332),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      // Glasses frame
                      Positioned(
                        top: 32,
                        child: SizedBox(
                          width: 38,
                          height: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Left lens
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFe67e22), width: 2),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              // Bridge
                              Container(
                                width: 4,
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFe67e22),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              // Right lens
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFe67e22), width: 2),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Cat eyes (small dots inside glasses)
                      Positioned(
                        top: 37,
                        left: 30,
                        child: Container(
                          width: 2,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 37,
                        right: 30,
                        child: Container(
                          width: 2,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      
                      // Cat nose (small triangle)
                      Positioned(
                        top: 48,
                        child: Container(
                          width: 3,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ecdc4),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Book/study element (small teal rectangle at bottom)
                Container(
                  width: 18,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ecdc4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a2332),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // App name
        Text(
          'STUDYPALS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 32),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF3d4a5c), // Medium blue-gray like the container
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'EMAIL',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF3d4a5c), // Medium blue-gray like the container
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'PASSWORD',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF4ecdc4), // Teal color like in the image
              size: 18,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
        color: const Color(0xFF4ecdc4), // Teal color exactly like the image
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
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
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'SIGN UP',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'FORGOT PASSWORD?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Guest login option
        TextButton(
          onPressed: _handleGuestLogin,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Continue as Guest',
            style: TextStyle(
              color: Color(0xFF4ecdc4),
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
        backgroundColor: const Color(0xFF2a3543),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registration feature coming soon!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'For now, you can:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Continue as Guest\n• Use demo@studypals.com / password',
              style: TextStyle(color: Color(0xFF4ecdc4), fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF4ecdc4), fontWeight: FontWeight.w500),
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
        SnackBar(
          content: const Text('Please enter your email address first'),
          backgroundColor: const Color(0xFF4ecdc4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password reset feature coming soon!'),
        backgroundColor: const Color(0xFF4ecdc4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
