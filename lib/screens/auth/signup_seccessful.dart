// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import developer tools for logging
import 'dart:developer' as developer;
// Import video player package
import 'package:video_player/video_player.dart';

/// Signup successful screen with video and return to login
/// Shows success message after account creation
class SignupSuccessfulScreen extends StatefulWidget {
  // Defines a stateful widget for the signup successful screen
  const SignupSuccessfulScreen({super.key});

  @override
  State<SignupSuccessfulScreen> createState() => _SignupSuccessfulScreenState();
}

class _SignupSuccessfulScreenState extends State<SignupSuccessfulScreen> {
  // State class for SignupScreen to manage mutable data
  // Add video controller variables
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/grok-video-864eb59b-ebfe-413f-8f5e-b5da134296c4.mp4',
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
          developer.log("Video is playing automatically with sound restored", name: 'SignupSuccessfulScreen');
        } else {
          developer.log("Video needs user interaction to play", name: 'SignupSuccessfulScreen');
        }
      }
    } catch (e) {
      developer.log('Error initializing video: $e', name: 'SignupSuccessfulScreen');
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
    super.dispose();
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
                      // Main content
                      Padding(
                        // Adds padding inside the container
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          // Arranges children vertically in a column
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            // Adds space at the top
                            _buildMascotSection(),
                            // Builds the video mascot section
                            const SizedBox(height: 32),
                            // Space between video and text
                            const Text(
                              'Your account has been created successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Space between text and button
                            _buildReturnToLoginButton(),
                            // Return to Login button
                            const SizedBox(height: 30),
                            // Space between button and smiley
                            const Icon(
                              Icons.sentiment_very_satisfied,
                              color: Color(0xFFe67e22),
                              size: 60,
                            ),
                            const SizedBox(height: 60),
                            // Space at bottom
                          ],
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
          width: 200,
          // Fixed width for consistency (increased from 150)
          height: 200,
          // Fixed height for consistency (increased from 150)
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
          'Congratulations!',
          style: TextStyle(
            fontSize: 16,
            // Medium font size for tagline
            color: Color.fromARGB(255, 255, 140, 0),
            // Light gray color for subtlety
            letterSpacing: 1,
            // Slight letter spacing
          ),
        ),
      ],
    );
  }

  Widget _buildReturnToLoginButton() {
    // Builds the return to login button
    return SizedBox(
      // Container to set button width
      width: double.infinity,
      // Full width button
      height: 56,
      // Fixed button height
      child: ElevatedButton(
        // Elevated button for return to login
        onPressed: () {
          // Navigate back to login screen
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          // Button styling
          backgroundColor: const Color(0xFF69ACBD),
          // Light blue background color (same as Create Account)
          foregroundColor: const Color.fromARGB(255, 255, 140, 0),
          // Orange text color (same as Create Account)
          shape: RoundedRectangleBorder(
            // Rounded rectangle shape
            borderRadius: BorderRadius.circular(12),
            // Rounded corners
          ),
          elevation: 8,
          // Shadow elevation
        ),
        child: Text(
          // Button text
          'Return To Login',
          style: TextStyle(
            // Text styling
            color: const Color.fromARGB(255, 255, 140, 0),
            // Orange text (same as Create Account)
            fontSize: 15,
            // Font size (same as Create Account)
            fontWeight: FontWeight.bold,
            // Bold text
            letterSpacing: 1.5,
            // Letter spacing (same as Create Account)
            shadows: [
              // Shadows for text (same as Create Account)
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
}