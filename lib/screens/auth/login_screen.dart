// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing global app state
import 'package:provider/provider.dart';
// Import app state provider to manage authentication status
import 'package:studypals/providers/app_state.dart';
// Import User model for demo login
import 'package:studypals/models/user.dart';
// Import Firebase services
import 'package:studypals/screens/auth/email_verification_screen.dart';
import 'package:studypals/screens/auth/signup_screen.dart';
// Import Lottie for animated icons
import 'package:lottie/lottie.dart';
// Import Secure Storage Service for Remember Me functionality
import 'package:studypals/services/secure_storage_service.dart';

/// Modern login screen that matches the app's Material 3 design system
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = SecureStorageService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoadingCredentials = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Load saved credentials on screen init
    _loadSavedCredentials();
  }

  /// Load saved credentials from secure storage
  Future<void> _loadSavedCredentials() async {
    try {
      setState(() {
        _isLoadingCredentials = true;
      });

      final savedCredentials = await _secureStorage.getSavedCredentials();

      if (savedCredentials != null && mounted) {
        // Validate credentials are not expired
        final isValid = await _secureStorage.areCredentialsValid();

        if (isValid) {
          setState(() {
            _emailController.text = savedCredentials.email;
            _passwordController.text = savedCredentials.password;
            _rememberMe = true;
          });

          debugPrint(
              '✅ Auto-filled credentials for: ${savedCredentials.email}');

          // Optional: Show a snackbar to inform user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back! Auto-filled your credentials.'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          debugPrint('⚠️ Saved credentials expired, cleared');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading saved credentials: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF16181A), // Solid background color from Figma
      body: SafeArea(
        child: _isLoadingCredentials
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // App branding section
                    _buildBrandingSection(context),

                    const SizedBox(height: 40),

                    // Login form card
                    _buildLoginCard(context),

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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.school,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // App title
        Text(
          'StudyPals',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Your AI-powered study companion',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
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
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(
                          0xFFD9D9D9), // Match learning screen text color
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your learning journey',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD9D9D9).withValues(
                          alpha: 0.7), // Match learning screen text color
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                style: const TextStyle(
                    color: Color(0xFFD9D9D9)), // Match learning screen text
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(
                      color: Color(0xFFB0B0B0)), // Lighter gray for label
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                      color: const Color(0xFFD9D9D9).withValues(alpha: 0.5)),
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    color:
                        Color(0xFF6FB8E9), // Match learning screen accent color
                  ),
                  suffixIcon: IconButton(
                    icon: SizedBox(
                      width: 24,
                      height: 24,
                      child: Lottie.asset(
                        'assets/animations/visibility-V3.json',
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        addRepaintBoundary: false,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to standard icon if Lottie fails
                          return const Icon(
                            Icons.visibility_outlined,
                            size: 20,
                            color: Color(
                                0xFF6FB8E9), // Match learning screen accent color
                          );
                        },
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });

                      // Control animation based on password visibility
                      if (_obscurePassword) {
                        // Password is hidden, show closed eye (animate to 0)
                        _animationController.animateTo(0.0);
                      } else {
                        // Password is visible, show open eye (animate to 1)
                        _animationController.animateTo(1.0);
                      }
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
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Remember Me checkbox
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (bool? value) async {
                      setState(() {
                        _rememberMe = value ?? false;
                      });

                      // If unchecked, clear saved credentials immediately
                      if (!_rememberMe) {
                        await _secureStorage.clearCredentials();
                        debugPrint(
                            '🗑️ Remember Me disabled - credentials cleared');
                      }
                    },
                    activeColor: const Color(
                        0xFF6FB8E9), // Match learning screen accent color
                    checkColor: Colors.white,
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(
                      color:
                          Color(0xFFD9D9D9), // Match learning screen text color
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Tooltip(
                    message: 'Save your credentials securely for next time',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFB0B0B0), // Lighter gray
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Forgot password feature coming soon!')),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(
                            0xFF6FB8E9), // Match learning screen accent color
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                              Icons.login,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Demo login button
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleDemoLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(
                        0xFF6FB8E9), // Match learning screen accent color
                    side: const BorderSide(
                      color: Color(
                          0xFF6FB8E9), // Match learning screen accent color
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Try Demo',
                        style: TextStyle(
                          fontSize: 14,
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Color(0xFFD9D9D9), // Match learning screen text color
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SignupScreenNew()),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color:
                      Color(0xFF6FB8E9), // Match learning screen accent color
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Sign in using AppState's built-in method for proper state management
      final user = await appState.signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (user != null) {
          // Capture theme values before async operation
          final primaryColor = Theme.of(context).colorScheme.primary;
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          // Login successful - save credentials if Remember Me is checked
          if (_rememberMe) {
            await _secureStorage.saveCredentials(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: true,
            );
            debugPrint(
                '✅ Credentials saved securely for ${_emailController.text.trim()}');
          }

          // Show success message - check mounted after async operation
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user.name}!'),
              backgroundColor: primaryColor,
            ),
          );
          // AuthWrapper will automatically navigate to dashboard since user is now authenticated
        } else {
          // Check for specific error message
          final error = appState.error;
          if (error != null) {
            if (error.contains('verify your email')) {
              // Navigate to email verification screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationScreen(
                    email: _emailController.text.trim(),
                    displayName:
                        'User', // We don't have display name from failed login
                  ),
                ),
              );
            } else {
              // Show other errors
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
            appState.clearError();
          } else {
            // Generic error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Login failed. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
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

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final demoUser = User(
        id: 'demo_user',
        email: 'demo@studypals.com',
        name: 'Demo User',
      );

      appState.login(demoUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Welcome to StudyPals Demo!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo login failed: ${e.toString()}'),
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
