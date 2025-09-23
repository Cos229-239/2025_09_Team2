import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../dashboard_screen.dart';

/// Email verification screen shown after user signs up
/// Displays instructions and allows resending verification email
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String displayName;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.displayName,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  // Video controller for mascot
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  // Verification state
  bool _isCheckingVerification = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _cooldownTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/LibraryCat.mp4');
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        await _videoController!.setVolume(0.0);
        await _videoController!.setLooping(true);
        await _videoController!.play();

        await Future.delayed(const Duration(milliseconds: 100));
        if (_videoController!.value.isPlaying) {
          await _videoController!.setVolume(1.0);
        }
      }
    } catch (e) {
      developer.log('Error initializing video: $e', name: 'EmailVerificationScreen');
    }
  }

  void _startPeriodicCheck() {
    // Check email verification status every 3 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      
      final isVerified = await _authService.checkEmailVerified();
      if (isVerified) {
        timer.cancel();
        await _onEmailVerified();
      }
    });
  }

  Future<void> _onEmailVerified() async {
    if (!mounted) return;
    
    // Update Firestore to mark email as verified
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _firestoreService.markEmailAsVerified(currentUser.uid);
    }

    // Navigate to dashboard
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _isCheckingVerification = true;
    });

    final success = await _authService.sendEmailVerification();
    
    if (mounted) {
      setState(() {
        _isCheckingVerification = false;
      });

      if (success) {
        // Start cooldown
        setState(() {
          _canResendEmail = false;
          _resendCooldown = 60; // 60 seconds cooldown
        });

        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _resendCooldown--;
              if (_resendCooldown <= 0) {
                _canResendEmail = true;
                timer.cancel();
              }
            });
          } else {
            timer.cancel();
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent! Check your inbox.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification email. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha((0.8 * 255).round()),
              Theme.of(context).colorScheme.secondary.withAlpha((0.6 * 255).round()),
              Theme.of(context).colorScheme.tertiary.withAlpha((0.4 * 255).round()),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildMascotSection(),
                const SizedBox(height: 40),
                _buildVerificationMessage(),
                const SizedBox(height: 40),
                _buildActionButtons(),
                const SizedBox(height: 20),
                _buildBackToLoginButton(),
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
        // Cat mascot with video
        Container(
          width: MediaQuery.of(context).size.width > 600 ? 200 : 150,
          height: MediaQuery.of(context).size.width > 600 ? 200 : 150,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.9 * 255).round()),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: _isVideoInitialized && _videoController != null
                ? GestureDetector(
                    onTap: _handleVideoTap,
                    child: VideoPlayer(_videoController!),
                  )
                : const Center(
                    child: Icon(
                      Icons.pets,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'StudyPals',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your AI-powered study companion',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withAlpha((0.9 * 255).round()),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Check Your Email!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Hi ${widget.displayName}! 👋',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a verification link to:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Click the verification link in your email to activate your account and start your study journey!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.8 * 255).round()),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This page will automatically redirect you once your email is verified.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resend email button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _canResendEmail && !_isCheckingVerification
                ? _resendVerificationEmail
                : null,
            icon: _isCheckingVerification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              _isCheckingVerification
                  ? 'Sending...'
                  : _canResendEmail
                      ? 'Resend Verification Email'
                      : 'Resend in ${_resendCooldown}s',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Check verification button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isCheckingVerification ? null : () async {
              setState(() {
                _isCheckingVerification = true;
              });
              
              final isVerified = await _authService.checkEmailVerified();
              
              if (mounted) {
                setState(() {
                  _isCheckingVerification = false;
                });
                
                if (isVerified) {
                  await _onEmailVerified();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email not verified yet. Please check your inbox and click the verification link.'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: _isCheckingVerification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isCheckingVerification ? 'Checking...' : 'I\'ve Verified My Email'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () async {
        // Sign out and return to login
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Text(
        'Back to Login',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withAlpha((0.9 * 255).round()),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}