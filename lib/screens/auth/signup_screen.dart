// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing global app state
import 'package:provider/provider.dart';
// Import app state provider to manage authentication status
import 'package:studypals/providers/app_state.dart';
// Import User model for creating user objects

/// Modern login screen with cat mascot design
/// Matches the beautiful UI provided in the design mockup
class SignupScreenNew extends StatefulWidget {
  // Defines a stateful widget for the signup screen
  const SignupScreenNew({super.key});

  @override
  State<SignupScreenNew> createState() => _SignupScreenNewState();
}

class _SignupScreenNewState extends State<SignupScreenNew> {
  void _handleSignup() {
    // TODO: Implement signup logic here
    // For now, just print to console
    print('Signup button pressed');
  }
  // State class for LoginScreen to manage mutable data
  final _formKey = GlobalKey<FormState>();
  // Unique key for the form to validate input fields
  final _emailController = TextEditingController();
  // Controller for the email input field
  final _passwordController = TextEditingController();
  // Controller for the password input field
  final bool _isLoading = false;
  // Tracks if a login operation is in progress
  bool _obscurePassword = true;
  // Toggles visibility of the password field

  @override
  Widget build(BuildContext context) {
    // Builds the UI for the login screen
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a2332),
              Color(0xFF253142),
              Color(0xFF2a3543),
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF365069),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Stack(
                children: [
                  // Main content with orange border and form
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFFe67e22),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1a2332),
                            Color(0xFF253142),
                            Color(0xFF2a3543),
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 60),
                            Expanded(
                              flex: 2,
                              child: _buildMascotSection(),
                            ),
                            const Spacer(),
                            _buildLoginForm(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Return to Login button at top left of orange border
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFe67e22), size: 32),
                      tooltip: 'Return to Login',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
    // Builds the cat mascot and app branding section
    return Column(
      // Column to stack mascot and text
      children: [
        // Cat mascot container with the provided image
        Container(
          // Container for the mascot graphic
          width: 200,  // Reduced size to fit better on screen
          height: 200, // Reduced size to fit better on screen
          decoration: BoxDecoration(
            // Styling for the mascot container
            color: const Color(0xFF3d4a5c), // Medium blue-gray for container background
            borderRadius: BorderRadius.circular(20),
            // Rounded corners
            border: Border.all(
              color: const Color.fromARGB(255, 202, 199, 199).withOpacity(0.9),  // Slightly grayish white
              width: 12.0,                           // Border thickness
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
                fit: BoxFit.contain, // Maintain aspect ratio while fitting in container
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
        const SizedBox(height: 8), // Optional: add spacing
        Text(
          'Sign Up',
          style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
  ),
),
        // Removed 'Sign Up' text below 'STUDYPALS'
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
          _buildSignupButton(),
          // Signup button
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
            color: Colors.black.withOpacity(0.3), // Black drop shadow
            blurRadius: 10,
            // Blur radius
            spreadRadius: 1,
            // Spread radius
            offset: const Offset(2, 2),
            // Shadow offset
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Black inner shadow
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
          hintText: 'Enter Your Email',
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
                color: Colors.black.withOpacity(0.4), // Drop shadow
                blurRadius: 8,
                // Blur radius
                offset: const Offset(1.5, 1.5),
                // Shadow offset
              ),
              Shadow(
                color: Colors.black.withOpacity(0.3), // Inner shadow
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            color: Colors.black.withOpacity(0.3), // Black drop shadow
            blurRadius: 10,
            // Blur radius
            spreadRadius: 1,
            // Spread radius
            offset: const Offset(2, 2),
            // Shadow offset
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Black inner shadow
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
        textAlign: passwordFocusNode.hasFocus ? TextAlign.right : TextAlign.center,
        // Aligns text based on focus
        decoration: InputDecoration(
          // Input field styling
          hintText: 'Create Your password',
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
                color: Colors.black.withOpacity(0.4), // Drop shadow
                blurRadius: 8,
                // Blur radius
                offset: const Offset(1.5, 1.5),
                // Shadow offset
              ),
              Shadow(
                color: Colors.black.withOpacity(0.3), // Inner shadow
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
          contentPadding: const EdgeInsets.only(left: 40, right: 16, top: 16, bottom: 16), // Slightly increased left offset
          suffixIcon: IconButton(
            // Button to toggle password visibility
            icon: Icon(
              // Icon for visibility toggle
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              // Switches icon based on visibility
              color: const Color(0xFF4ecdc4), // Teal color
              size: 18,
              // Icon size
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

  Widget _buildSignupButton() {
    // Builds the signup button
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
            color: Colors.black.withOpacity(0.3), // Black drop shadow
            blurRadius: 10,
            // Blur radius
            spreadRadius: 1,
            // Spread radius
            offset: const Offset(2, 2),
            // Shadow offset
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Black inner shadow
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
        // Button widget for signup
        onPressed: _isLoading ? null : _handleSignup,
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
                'Create Account',
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
                      color: Colors.black.withOpacity(0.4), // Drop shadow
                      blurRadius: 8,
                      // Blur radius
                      offset: const Offset(1.5, 1.5),
                      // Shadow offset
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(0.3), // Inner shadow
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
}