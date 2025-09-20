// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing global app state
import 'package:provider/provider.dart';
// Import app state provider to manage authentication status
import 'package:studypals/providers/app_state.dart';
// Import User model for creating user objects
import 'package:studypals/models/user.dart';
import 'package:studypals/screens/auth/signup_screen.dart';

/// Modern login screen with cat mascot design
/// Matches the beautiful UI provided in the design mockup
class LoginScreen extends StatefulWidget {
  // Defines a stateless widget for the login screen
  const LoginScreen({super.key});
  // Constructor with optional key for widget identification

  @override
  State<LoginScreen> createState() => _LoginScreenState();
  // Creates the mutable state for this widget
}

class _LoginScreenState extends State<LoginScreen> {
  // State class for LoginScreen to manage mutable data
  final _formKey = GlobalKey<FormState>();
  // Unique key for the form to validate input fields
  final _emailController = TextEditingController();
  // Controller for the email input field
  final _passwordController = TextEditingController();
  // Controller for the password input field
  bool _isLoading = false;
  // Tracks if a login operation is in progress
  bool _obscurePassword = true;
  // Toggles visibility of the password field

  @override
  Widget build(BuildContext context) {
    // Builds the UI for the login screen
    return Scaffold(
      // Provides basic app structure with app bar and body
      body: Container(
        // Main container for the screen content
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
            decoration: const BoxDecoration(
              // Styling for the thick outer border
              color: Color(0xFF365069), // Thick border color from Figma
            ),
            child: Padding(
              // Adds padding for the thick border effect - INCREASED
              padding: const EdgeInsets.all(
                  32.0), // Increased padding for thicker space between border and edge
              child: Container(
                // Inner container for form and mascot
                decoration: BoxDecoration(
                  // Styling for the inner container
                  color: Colors
                      .transparent, // Transparent to show gradient background
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
                    borderRadius: BorderRadius.all(Radius.circular(
                        10)), // Slightly smaller radius to fit inside orange border
                  ),
                  child: SingleChildScrollView(
                    // Make entire login screen scrollable
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            64, // Account for padding
                      ),
                      child: Padding(
                        // Adds padding inside the container
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        // Horizontal padding for content
                        child: Column(
                          // Column to stack UI elements vertically
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.height > 600
                                    ? 60
                                    : 20), // Responsive top spacing
                            // Cat mascot and branding
                            _buildMascotSection(),
                            // Builds the cat mascot section
                            SizedBox(
                                height: MediaQuery.of(context).size.height > 600
                                    ? 40
                                    : 20),
                            // Responsive spacing
                            // Login form
                            _buildLoginForm(),
                            // Builds the login form section
                            SizedBox(
                                height: MediaQuery.of(context).size.height > 600
                                    ? 40
                                    : 20),
                            // Responsive spacer between form and links
                            _buildBottomLinks(),
                            // Builds the bottom navigation links
                            SizedBox(
                                height: MediaQuery.of(context).size.height > 600
                                    ? 40
                                    : 20),
                            // Responsive spacer at the bottom
                          ],
                        ),
                      ),
                    ),
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
    // Builds the cat mascot and app branding section
    return Column(
      // Column to stack mascot and text
      children: [
        // Cat mascot container with the provided image
        Container(
          // Container for the mascot graphic
          width: MediaQuery.of(context).size.width > 600
              ? 200
              : 150, // Responsive size for different screen sizes
          height: MediaQuery.of(context).size.width > 600
              ? 200
              : 150, // Responsive size for different screen sizes
          decoration: BoxDecoration(
            // Styling for the mascot container
            color: const Color(
                0xFF3d4a5c), // Medium blue-gray for container background
            borderRadius: BorderRadius.circular(20),
            // Rounded corners
            border: Border.all(
              color: const Color.fromARGB(255, 202, 199, 199)
                  .withValues(alpha: 0.9), // Slightly grayish white
              width: 12.0, // Border thickness
            ),
            boxShadow: [
              // Shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                // Shadow color with transparency
                blurRadius: 10,
                // Blur radius for shadow
                offset: const Offset(0, 5),
                // Shadow offset
              ),
            ],
          ),
          child: ClipRRect(
            // Clips the image to the container's rounded corners
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              // Add padding around the image
              padding: const EdgeInsets.all(11.0),
              child: Image.asset(
                // Display the cat mascot image
                'FirstStudyPal.png', // Path to your cat image asset
                fit: BoxFit
                    .contain, // Maintain aspect ratio while fitting in container
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return const Icon(
                    Icons.pets,
                    size: 80,
                    color: Color(0xFF4ecdc4),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Spacer below mascot
        // App name
        Text(
          // Text widget for app name
          'STUDYPALS',
          // App name text
          style: TextStyle(
            // Styling for text
            color: Colors.white.withValues(alpha: 0.85),
            // Text color with transparency
            fontSize: 40, // Increased font size to 40
            // Font size
            fontWeight: FontWeight.bold,
            // Bold text
            letterSpacing: 2.5,
            // Letter spacing
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    // Builds the login form with email, password, and login button
    return Form(
      // Form widget for input validation
      key: _formKey,
      // Associates form with global key
      child: Column(
        // Column to stack form fields
        children: [
          _buildEmailField(),
          // Email input field
          const SizedBox(height: 16),
          // Spacer between fields
          _buildPasswordField(),
          // Password input field
          const SizedBox(height: 32),
          // Spacer before button
          _buildLoginButton(),
          // Login button
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    // Builds the email input field
    final FocusNode emailFocusNode = FocusNode();
    // Focus node to track email field focus
    return Container(
      // Container for email field styling
      height: 50,
      // Fixed height
      decoration: BoxDecoration(
        // Styling for container
        color: const Color(0xFF3d4a5c), // Medium blue-gray
        borderRadius: BorderRadius.circular(8),
        // Rounded corners
        border: Border.all(color: Colors.white, width: 1), // White border
        boxShadow: [
          // Shadows for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3), // Black drop shadow
            blurRadius: 10,
            // Blur radius
            spreadRadius: 1,
            // Spread radius
            offset: const Offset(2, 2),
            // Shadow offset
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // Black inner shadow
            blurRadius: 8,
            // Blur radius
            spreadRadius: -2,
            // Negative spread for inner shadow
            offset: const Offset(0, 0),
            // No offset
          ),
        ],
      ),
      child: TextFormField(
        // Text input field for email
        controller: _emailController,
        // Associates with email controller
        focusNode: emailFocusNode,
        // Associates with focus node
        style: const TextStyle(color: Colors.white, fontSize: 14),
        // Text style
        textAlign: emailFocusNode.hasFocus ? TextAlign.right : TextAlign.center,
        // Aligns text based on focus
        decoration: InputDecoration(
          // Input field styling
          hintText: 'EMAIL',
          // Placeholder text
          hintStyle: TextStyle(
            // Styling for hint text
            color: Colors.white, // Bright white
            fontSize: 12,
            // Font size
            fontWeight: FontWeight.bold,
            // Bold text
            letterSpacing: 1.2,
            // Letter spacing
            shadows: [
              // Shadows for hint text
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
          border: InputBorder.none,
          // No default border
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // Padding inside field
        ),
        keyboardType: TextInputType.emailAddress,
        // Optimizes keyboard for email input
        validator: (value) {
          // Validates email input
          if (value == null || value.isEmpty) {
            // Checks if field is empty
            return 'Please enter your email';
            // Error message for empty field
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            // Validates email format
            return 'Please enter a valid email address';
            // Error message for invalid email
          }
          return null;
          // No error if valid
        },
        onTap: () => setState(() {}),
        // Updates UI on tap
        onEditingComplete: () => setState(() {}),
        // Updates UI on editing complete
      ),
    );
  }

  Widget _buildPasswordField() {
    // Builds the password input field
    final FocusNode passwordFocusNode = FocusNode();
    // Focus node to track password field focus
    return Container(
      // Container for password field styling
      height: 50,
      // Fixed height
      decoration: BoxDecoration(
        // Styling for container
        color: const Color(0xFF3d4a5c), // Medium blue-gray
        borderRadius: BorderRadius.circular(8),
        // Rounded corners
        border: Border.all(color: Colors.white, width: 1), // White border
        boxShadow: [
          // Shadows for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3), // Black drop shadow
            blurRadius: 10,
            // Blur radius
            spreadRadius: 1,
            // Spread radius
            offset: const Offset(2, 2),
            // Shadow offset
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // Black inner shadow
            blurRadius: 8,
            // Blur radius
            spreadRadius: -2,
            // Negative spread for inner shadow
            offset: const Offset(0, 0),
            // No offset
          ),
        ],
      ),
      child: TextFormField(
        // Text input field for password
        controller: _passwordController,
        // Associates with password controller
        focusNode: passwordFocusNode,
        // Associates with focus node
        obscureText: _obscurePassword,
        // Hides password text
        style: const TextStyle(color: Colors.white, fontSize: 14),
        // Text style
        textAlign:
            passwordFocusNode.hasFocus ? TextAlign.right : TextAlign.center,
        // Aligns text based on focus
        decoration: InputDecoration(
          // Input field styling
          hintText: 'PASSWORD',
          // Placeholder text
          hintStyle: TextStyle(
            // Styling for hint text
            color: Colors.white, // Bright white
            fontSize: 12,
            // Font size
            fontWeight: FontWeight.bold,
            // Bold text
            letterSpacing: 1.2,
            // Letter spacing
            shadows: [
              // Shadows for hint text
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
          border: InputBorder.none,
          // No default border
          contentPadding: const EdgeInsets.only(
              left: 40,
              right: 16,
              top: 16,
              bottom: 16), // Slightly increased left offset
          suffixIcon: IconButton(
            // Button to toggle password visibility
            icon: Icon(
              // Icon for visibility toggle
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              // Switches icon based on visibility
              color: const Color(0xFF4ecdc4), // Teal color
              size: 18,
              // Icon size
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            // Toggles password visibility
          ),
        ),
        validator: (value) {
          // Validates password input
          if (value == null || value.isEmpty) {
            // Checks if field is empty
            return 'Please enter your password';
            // Error message for empty field
          }
          return null;
          // No error if valid
        },
        onTap: () => setState(() {}),
        // Updates UI on tap
        onEditingComplete: () => setState(() {}),
        // Updates UI on editing complete
      ),
    );
  }

  Widget _buildLoginButton() {
    // Builds the login button
    return Container(
      // Container for button styling
      width: double.infinity,
      // Full width
      height: 50,
      // Fixed height
      decoration: BoxDecoration(
        // Styling for container
        color: const Color(0xFF69ACBD),
        // Button color
        borderRadius: BorderRadius.circular(8),
        // Rounded corners
        border: Border.all(color: Colors.white, width: 1), // White border
        boxShadow: [
          // Shadows for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3), // Black drop shadow
            blurRadius: 10,
            // Blur radius
            spreadRadius: 1,
            // Spread radius
            offset: const Offset(2, 2),
            // Shadow offset
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // Black inner shadow
            blurRadius: 8,
            // Blur radius
            spreadRadius: -2,
            // Negative spread for inner shadow
            offset: const Offset(0, 0),
            // No offset
          ),
        ],
      ),
      child: ElevatedButton(
        // Button widget for login
        onPressed: _isLoading ? null : _handleLogin,
        // Disables button during loading
        style: ElevatedButton.styleFrom(
          // Custom button styling
          backgroundColor: Colors.transparent,
          // Transparent background
          shadowColor: Colors.transparent,
          // No shadow
          elevation: 0,
          // No elevation
          shape: RoundedRectangleBorder(
            // Button shape
            borderRadius: BorderRadius.circular(8),
            // Rounded corners
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                // Loading indicator
                height: 20,
                // Indicator height
                width: 20,
                // Indicator width
                child: CircularProgressIndicator(
                  // Circular loading animation
                  strokeWidth: 2,
                  // Line thickness
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  // White color
                ),
              )
            : Text(
                // Button text
                'LOGIN',
                // Text content
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
                      color:
                          Colors.black.withValues(alpha: 0.3), // Inner shadow
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

  Widget _buildBottomLinks() {
    // Builds the bottom navigation links
    return Column(
      // Column to stack links
      children: [
        Row(
          // Row to arrange links side by side
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Spaces links evenly
          children: [
            TextButton(
              // Button for sign-up
              onPressed: _handleSignUp,
              // Handles sign-up action
              style: TextButton.styleFrom(
                // Custom button styling
                padding: EdgeInsets.zero,
                // No padding
                minimumSize: Size.zero,
                // Minimal size
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                // Shrinks tap target
              ),
              child: Text(
                // Sign-up text
                'SIGN UP',
                // Text content
                style: TextStyle(
                  // Text styling
                  color: Colors.white.withValues(alpha: 0.7),
                  // White text with transparency
                  fontSize: 13,
                  // Font size
                  fontWeight: FontWeight.bold,
                  // Bold text
                  letterSpacing: 1.2,
                  // Letter spacing
                ),
              ),
            ),
            TextButton(
              // Button for forgot password
              onPressed: _handleForgotPassword,
              // Handles forgot password action
              style: TextButton.styleFrom(
                // Custom button styling
                padding: EdgeInsets.zero,
                // No padding
                minimumSize: Size.zero,
                // Minimal size
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                // Shrinks tap target
              ),
              child: Text(
                // Forgot password text
                'FORGOT PASSWORD?',
                // Text content
                style: TextStyle(
                  // Text styling
                  color: Colors.white.withValues(alpha: 0.7),
                  // White text with transparency
                  fontSize: 13,
                  // Font size
                  fontWeight: FontWeight.bold,
                  // Bold text
                  letterSpacing: 1.2,
                  // Letter spacing
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Spacer between rows
        // Guest login option
        TextButton(
          // Button for guest login
          onPressed: _handleGuestLogin,
          // Handles guest login action
          style: TextButton.styleFrom(
            // Custom button styling
            padding: EdgeInsets.zero,
            // No padding
            minimumSize: Size.zero,
            // Minimal size
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            // Shrinks tap target
          ),
          child: const Text(
            // Guest login text
            'Continue as Guest',
            // Text content
            style: TextStyle(
              // Text styling
              color: Color(0xFF4ecdc4),
              // Teal color
              fontSize: 14,
              // Font size
              fontWeight: FontWeight.w400,
              // Regular weight
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    // Handles the login process
    if (_formKey.currentState!.validate()) {
      // Validates form inputs
      setState(() => _isLoading = true);
      // Sets loading state to true
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        // Accesses app state without listening
        final user = await appState.signInUser(
          // Attempts to sign in user
          email: _emailController.text.trim(),
          // Email input
          password: _passwordController.text,
          // Password input
        );
        if (!mounted) return;
        // Checks if widget is still mounted
        if (user != null) {
          // If login successful
          ScaffoldMessenger.of(context).showSnackBar(
            // Shows success message
            SnackBar(content: Text('Welcome back, ${user.name}!')),
          );
        } else {
          // If login fails
          final error = appState.error;
          // Gets error from app state
          if (error != null) {
            // If error exists
            ScaffoldMessenger.of(context).showSnackBar(
              // Shows error message
              SnackBar(
                content: Text(error),
                // Error text
                backgroundColor: Colors.red,
                // Red background
              ),
            );
            appState.clearError();
            // Clears error from app state
          }
        }
      } catch (e) {
        // Handles any errors
        if (!mounted) return;
        // Checks if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          // Shows error message
          SnackBar(
            content: Text(e.toString()),
            // Error text
            backgroundColor: Colors.red,
            // Red background
          ),
        );
      } finally {
        // Ensures loading state is reset
        if (mounted) {
          // Checks if widget is still mounted
          setState(() => _isLoading = false);
          // Resets loading state
        }
      }
    }
  }

  void _handleSignUp() {
    // Handles the sign-up action
    // Navigate to the signup screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SignupScreenNew(), //added const for debugging
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    // Handles the forgot password action
    final email = _emailController.text.trim();
    // Gets trimmed email input
    if (email.isEmpty) {
      // Checks if email is empty
      ScaffoldMessenger.of(context).showSnackBar(
        // Shows error message
        SnackBar(
          content: const Text('Please enter your email address first'),
          // Error text
          backgroundColor: const Color(0xFF4ecdc4),
          // Teal background
          behavior: SnackBarBehavior.floating,
          // Floating snackbar
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // Rounded corners
        ),
      );
      return;
      // Exits if email is empty
    }
    ScaffoldMessenger.of(context).showSnackBar(
      // Shows info message
      SnackBar(
        content: const Text('Password reset feature coming soon!'),
        // Info text
        backgroundColor: const Color(0xFF4ecdc4),
        // Teal background
        behavior: SnackBarBehavior.floating,
        // Floating snackbar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // Rounded corners
      ),
    );
  }

  void _handleGuestLogin() {
    // Handles the guest login action
    final guestUser = User(
      // Creates a guest user object
      id: 'guest',
      // User ID
      email: 'guest@studypals.com',
      // Guest email
      name: 'Guest User',
      // Guest name
      isEmailVerified: false,
      // Email verification status
    );
    Provider.of<AppState>(context, listen: false).login(guestUser);
    // Logs in the guest user
  }

  @override
  void dispose() {
    // Cleans up resources
    _emailController.dispose();
    // Disposes email controller
    _passwordController.dispose();
    // Disposes password controller
    super.dispose();
    // Calls parent dispose
  }
}
