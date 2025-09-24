import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase connection...';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _testFirebase();
  }

  Future<void> _testFirebase() async {
    try {
      setState(() {
        _status = 'Testing Firebase Auth connection...';
      });

      // Test 1: Check if Firebase Auth is initialized
      final app = _auth.app;
      if (kDebugMode) {
        print('✅ Firebase app name: ${app.name}');
        print('✅ Firebase project ID: ${app.options.projectId}');
        print('✅ Firebase API key: ${app.options.apiKey}');
      }

      setState(() {
        _status = 'Firebase Auth initialized ✅\nProject: ${app.options.projectId}';
      });

      // Test 2: Try to create a test user
      await _testUserCreation();

    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase test error: $e');
      }
      setState(() {
        _status = 'Firebase Error ❌\n$e';
      });
    }
  }

  Future<void> _testUserCreation() async {
    try {
      setState(() {
        _status += '\n\nTesting user creation...';
      });

      // Try to create a test user
      final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';

      if (kDebugMode) {
        print('🔄 Attempting to create test user: $testEmail');
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      if (result.user != null) {
        if (kDebugMode) {
          print('✅ Test user created successfully: ${result.user!.uid}');
        }
        setState(() {
          _status += '\n✅ Test user created successfully!';
          _status += '\nUID: ${result.user!.uid}';
        });

        // Clean up - delete the test user
        await result.user!.delete();
        if (kDebugMode) {
          print('✅ Test user deleted');
        }
        setState(() {
          _status += '\n✅ Test cleanup completed';
        });
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ User creation test failed: $e');
      }
      setState(() {
        _status += '\n❌ User creation failed:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Connection Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testFirebase,
                child: const Text('Run Test Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}