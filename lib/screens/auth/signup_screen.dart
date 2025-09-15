// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import developer tools for logging
import 'dart:developer' as developer;
// Import video player package
import 'package:video_player/video_player.dart';
// Import signup successful screen
import 'package:studypals/screens/auth/signup_successful.dart';

/// Modern signup screen with video mascot design
/// Matches the beautiful UI provided in the design mockup
class SignupScreenNew extends StatefulWidget {
  // Defines a stateful widget for the signup screen
  const SignupScreenNew({super.key});

  @override
  State<SignupScreenNew> createState() => _SignupScreenNewState();
}

class _SignupScreenNewState extends State<SignupScreenNew> {
  // State class for SignupScreen to manage mutable data
  final _formKey = GlobalKey<FormState>();
  // Unique key for the form to validate input fields
  final _emailController = TextEditingController();
  // Controller for the email input field
  final _passwordController = TextEditingController();
  // Controller for the password input field
  final _confirmPasswordController = TextEditingController();
  // Controller for the confirm password input field
  bool _isLoading = false;
  // Tracks if a signup operation is in progress
  bool _obscurePassword = true;
  // Toggles visibility of the password field
  bool _obscureConfirmPassword = true;
  // Toggles visibility of the confirm password field

  // Add video controller variables
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  // Add hover state for back button
  bool _isBackButtonHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/LibraryCat.mp4',
      );
      
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Try to start autoplay with muted sound (works on most browsers)
        await _videoController!.setVolume(0.0);  // Start muted
        await _videoController!.setLooping(true);
        await _videoController!.play();
        
        // After a short delay, restore volume if playing
        await Future.delayed(const Duration(milliseconds: 100));
        if (_videoController!.value.isPlaying) {
          await _videoController!.setVolume(1.0);
          developer.log("Video is playing automatically with sound restored", name: 'SignupScreen');
        } else {
          developer.log("Video needs user interaction to play", name: 'SignupScreen');
        }
      }
    } catch (e) {
      developer.log('Error initializing video: $e', name: 'SignupScreen');
      if (mounted) {
        // Video initialization failed, user will need to tap to play
      }
    }
  }

  void _handleVideoTap() async {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.setVolume(1.0);
        await _videoController!.play();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate async operation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Navigate to signup successful screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SignupSuccessfulScreen(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Builds the UI for the signup screen
    return Scaffold(
      // Provides basic app structure with app bar and body
      body: Container(
        // Main container for the screen content
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Applies a gradient background
          gradient: LinearGradient(
            // Linear gradient from top to bottom
            begin: Alignment.topCenter,
            // Start point of the gradient
            end: Alignment.bottomCenter,
            // End point of the gradient
            colors: [
              Color(0xFF1a2332), // Very dark blue-gray
              Color(0xFF253142), // Dark blue-gray
              Color(0xFF2a3543), // Slightly lighter dark blue-gray
            ],
            // Gradient color stops
          ),
        ),
        child: SafeArea(
          // Ensures content is within safe screen boundaries
          child: Container(
            // Outer container for thick border - fills entire safe area
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              // Styling for the thick outer border
              color: Color(0xFF365069), // Thick border color from Figma
            ),
            child: Padding(
              // Adds padding for the thick border effect - MATCHES LOGIN SCREEN
              padding: const EdgeInsets.all(32.0), // Matches login screen padding
              child: Container(
                // Inner container for form and mascot
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  // Styling for the inner container
                  color: Colors.transparent, // Transparent to show gradient background
                  border: Border.all(
                    // Adds the original orange border
                    color: const Color(0xFFe67e22), // Orange border
                    width: 2,
                    // Border thickness
                  ),
                  borderRadius: BorderRadius.circular(12),
                  // Rounded corners for the container
                ),
                child: Container(
                  // Container to apply gradient background inside the borders
                  width: double.infinity,
                  height: double.infinity,
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
                    borderRadius: BorderRadius.all(Radius.circular(10)), // Slightly smaller radius to fit inside orange border
                  ),
                  child: Stack(
                    // Stack to overlay the back arrow on the content
                    children: [
                      // Main content - make entire screen scrollable
                      SingleChildScrollView(
                        // Allow entire screen to scroll
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 64, // Account for padding
                          ),
                          child: Padding(
                            // Adds padding inside the container
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Column(
                              // Arranges children vertically in a column
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height > 600 ? 20 : 10),
                                // Even more responsive top spacing
                                _buildMascotSection(),
                                // Builds the cat mascot and branding
                                SizedBox(height: MediaQuery.of(context).size.height > 600 ? 30 : 15),
                                // Even more responsive spacing between mascot and form
                                _buildSignupForm(),
                                // Builds the signup form directly without Expanded
                                SizedBox(height: MediaQuery.of(context).size.height > 600 ? 20 : 10),
                                // Responsive bottom spacing
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Back arrow positioned at top-left
                      Positioned(
                        top: 16,
                        left: 16,
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _isBackButtonHovered = true),
                          onExit: (_) => setState(() => _isBackButtonHovered = false),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isBackButtonHovered
                                    ? [
                                        const BoxShadow(
                                          color: Color(0xFFe67e22),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                          offset: Offset(0, 0),
                                        ),
                                        const BoxShadow(
                                          color: Color(0xFFe67e22),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: Offset(0, 0),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFFe67e22), // Orange color to match theme
                                    size: 28,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Back',
                                    style: TextStyle(
                                      color: Color(0xFFe67e22), // Orange color to match theme
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotSection() {
    // Builds the video mascot and app branding section
    return Column(
      // Column to stack mascot and text
      children: [
        // Cat mascot with video
        Container(
          // Container for the video with rounded corners
          width: MediaQuery.of(context).size.width > 600 ? 200 : 150,
          // Responsive width: larger on desktop, smaller on mobile
          height: MediaQuery.of(context).size.width > 600 ? 200 : 150,
          // Responsive height: larger on desktop, smaller on mobile
          decoration: BoxDecoration(
            // Styling for the video container
            color: const Color(0xFF2a3543),
            // Background color matching the design
            borderRadius: BorderRadius.circular(20),
            // Rounded corners for modern look
            border: Border.all(
              // Border around the video
              color: const Color(0xFFe67e22),
              // Orange border to match theme
              width: 3,
              // Border thickness
            ),
          ),
          child: ClipRRect(
            // Clips the video to rounded corners
            borderRadius: BorderRadius.circular(17),
            // Slightly smaller radius to fit inside border
            child: _videoController != null && _isVideoInitialized
                ? GestureDetector(
                    onTap: _handleVideoTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        // Show play button if video is not playing
                        if (!_videoController!.value.isPlaying)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFe67e22)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        // Adds space between mascot and text
        const Text(
          // App name text
          'StudyPals',
          style: TextStyle(
            fontSize: 32,
            // Large font size for app name
            fontWeight: FontWeight.bold,
            // Bold font weight
            color: Color.fromARGB(255, 255, 255, 255),
            // Orange color matching the design
            letterSpacing: 2,
            // Adds spacing between letters
          ),
        ),
        const SizedBox(height: 8),
        // Small space between app name and tagline
        const Text(
          // App tagline
          'Sign Up',
          style: TextStyle(
            fontSize: 16,
            // Medium font size for tagline
            color: Color.fromARGB(179, 255, 255, 255),
            // Light gray color for subtlety
            letterSpacing: 1,
            // Slight letter spacing
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    // Builds the signup form with input fields and button
    return Form(
      // Form widget to group and validate input fields
      key: _formKey,
      // Associates form with the global key for validation
      child: Column(
        // Arranges form elements vertically
        children: [
          _buildEmailField(),
          // Email input field
          const SizedBox(height: 20),
          // Space between fields
          _buildPasswordField(),
          // Password input field
          const SizedBox(height: 20),
          // Space between fields
          _buildConfirmPasswordField(),
          // Confirm password input field
          SizedBox(height: MediaQuery.of(context).size.height > 800 ? 60 : MediaQuery.of(context).size.height > 600 ? 30 : 15),
          // Very responsive spacing before signup button - scales with screen height
          _buildSignupButton(),
          // Signup button
          const SizedBox(height: 20),
          // Space after signup button
          _buildLoginLink(),
          // Link to login screen
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    // Builds the email input field with validation
    return TextFormField(
      // Text input field for email
      controller: _emailController,
      // Associates controller with the field
      keyboardType: TextInputType.emailAddress,
      // Sets keyboard type to email
      style: const TextStyle(color: Colors.white),
      // White text color
      decoration: InputDecoration(
        // Styling for the input field
        labelText: 'Email',
        // Label text for the field
        labelStyle: const TextStyle(color: Colors.white70),
        // Light gray label color
        prefixIcon: const Icon(Icons.email, color: Color(0xFFe67e22)),
        // Email icon with orange color
        filled: true,
        // Fills the background
        fillColor: const Color(0xFF1a2332).withValues(alpha: 0.5),
        // Semi-transparent background
        border: OutlineInputBorder(
          // Border around the field
          borderRadius: BorderRadius.circular(12),
          // Rounded corners
          borderSide: const BorderSide(color: Color(0xFF365069)),
          // Border color
        ),
        enabledBorder: OutlineInputBorder(
          // Border when not focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF365069)),
        ),
        focusedBorder: OutlineInputBorder(
          // Border when focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe67e22), width: 2),
          // Orange border when focused
        ),
      ),
      validator: (value) {
        // Validates the email input
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
        // Returns null if validation passes
      },
    );
  }

  Widget _buildPasswordField() {
    // Builds the password input field with visibility toggle
    return TextFormField(
      // Text input field for password
      controller: _passwordController,
      // Associates controller with the field
      obscureText: _obscurePassword,
      // Hides password text based on toggle
      style: const TextStyle(color: Colors.white),
      // White text color
      decoration: InputDecoration(
        // Styling for the input field
        labelText: 'Password',
        // Label text for the field
        labelStyle: const TextStyle(color: Colors.white70),
        // Light gray label color
        prefixIcon: const Icon(Icons.lock, color: Color(0xFFe67e22)),
        // Lock icon with orange color
        suffixIcon: IconButton(
          // Button to toggle password visibility
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () {
            // Toggles password visibility when pressed
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        // Fills the background
        fillColor: const Color(0xFF1a2332).withValues(alpha: 0.5),
        // Semi-transparent background
        border: OutlineInputBorder(
          // Border around the field
          borderRadius: BorderRadius.circular(12),
          // Rounded corners
          borderSide: const BorderSide(color: Color(0xFF365069)),
          // Border color
        ),
        enabledBorder: OutlineInputBorder(
          // Border when not focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF365069)),
        ),
        focusedBorder: OutlineInputBorder(
          // Border when focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe67e22), width: 2),
          // Orange border when focused
        ),
      ),
      validator: (value) {
        // Validates the password input
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
        // Returns null if validation passes
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    // Builds the confirm password input field with validation
    return TextFormField(
      // Text input field for confirm password
      controller: _confirmPasswordController,
      // Associates controller with the field
      obscureText: _obscureConfirmPassword,
      // Hides password text based on toggle
      style: const TextStyle(color: Colors.white),
      // White text color
      decoration: InputDecoration(
        // Styling for the input field
        labelText: 'Confirm Password',
        // Label text for the field
        labelStyle: const TextStyle(color: Colors.white70),
        // Light gray label color
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFe67e22)),
        // Lock outline icon with orange color
        suffixIcon: IconButton(
          // Button to toggle password visibility
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () {
            // Toggles password visibility when pressed
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        filled: true,
        // Fills the background
        fillColor: const Color(0xFF1a2332).withValues(alpha: 0.5),
        // Semi-transparent background
        border: OutlineInputBorder(
          // Border around the field
          borderRadius: BorderRadius.circular(12),
          // Rounded corners
          borderSide: const BorderSide(color: Color(0xFF365069)),
          // Border color
        ),
        enabledBorder: OutlineInputBorder(
          // Border when not focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF365069)),
        ),
        focusedBorder: OutlineInputBorder(
          // Border when focused
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe67e22), width: 2),
          // Orange border when focused
        ),
      ),
      validator: (value) {
        // Validates the confirm password input
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
        // Returns null if validation passes
      },
    );
  }

  Widget _buildSignupButton() {
    // Builds the signup button with loading state
    return SizedBox(
      // Container to set button width
      width: double.infinity,
      // Full width button
      height: 56,
      // Fixed button height
      child: ElevatedButton(
        // Elevated button for signup
        onPressed: _isLoading ? null : _handleSignup,
        // Calls signup handler when pressed, disabled when loading
        style: ElevatedButton.styleFrom(
          // Button styling
          backgroundColor: const Color(0xFF69ACBD),
          // Orange background color
          foregroundColor: const Color.fromARGB(255, 255, 140, 0),
          // White text color
          shape: RoundedRectangleBorder(
            // Rounded rectangle shape
            borderRadius: BorderRadius.circular(12),
            // Rounded corners
          ),
          elevation: 8,
          // Shadow elevation
        ),
        child: _isLoading
            ? const SizedBox(
                // Loading indicator when signing up
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                // Button text when not loading
                'Create Account',
                style: TextStyle(
                  // Text styling
                  color: const Color.fromARGB(255, 255, 140, 0),
                  // Orange text
                  fontSize: 15,
                  // Font size
                  fontWeight: FontWeight.bold,
                  // Bold text
                  letterSpacing: 1.5,
                  // Letter spacing
                  shadows: [
                    // Shadows for text
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4), // Drop shadow
                      blurRadius: 8,
                      // Blur radius
                      offset: const Offset(1.5, 1.5),
                      // Shadow offset
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3), // Inner shadow
                      blurRadius: 6,
                      // Blur radius
                      offset: const Offset(0, 0),
                      // No offset
                    ),
                    const Shadow(
                      color: Colors.black, // Thin black outline
                      offset: Offset(0.5, 0.5),
                      // Outline offset
                      blurRadius: 0.5,
                      // Minimal blur
                    ),
                    const Shadow(
                      color: Colors.black, // Thin black outline
                      offset: Offset(-0.5, -0.5),
                      // Outline offset
                      blurRadius: 0.5,
                      // Minimal blur
                    ),
                    const Shadow(
                      color: Colors.black, // Thin black outline
                      offset: Offset(0.5, -0.5),
                      // Outline offset
                      blurRadius: 0.5,
                      // Minimal blur
                    ),
                    const Shadow(
                      color: Colors.black, // Thin black outline
                      offset: Offset(-0.5, 0.5),
                      // Outline offset
                      blurRadius: 0.5,
                      // Minimal blur
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    // Builds the link to navigate to login screen
    return Row(
      // Row to center the text and link
      mainAxisAlignment: MainAxisAlignment.center,
      // Centers the content horizontally
      children: [
        const Text(
          // Static text
          'Already have an account? ',
          style: TextStyle(color: Colors.white70),
          // Light gray text color
        ),
        GestureDetector(
          // Gesture detector to handle tap
          onTap: () {
            // Navigates to login screen when tapped
            Navigator.of(context).pop();
            // Goes back to login screen
          },
          child: const Text(
            // Link text
            'Sign In',
            style: TextStyle(
              color: Color(0xFFe67e22),
              // Orange color for link
              fontWeight: FontWeight.bold,
              // Bold font weight
              decoration: TextDecoration.underline,
              // Underline decoration
            ),
          ),
        ),
      ],
    );
  }
}