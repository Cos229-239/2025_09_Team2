# StudyPals Authentication Setup Guide

## Overview
StudyPals now includes a comprehensive authentication system with user registration, email verification, and login functionality. The system is designed to integrate with Firebase for production use, but can also run in demo mode for development.

## Features Implemented

### 📧 Enhanced Login/Registration Screen
- **Dual Mode Interface**: Toggle between login and registration modes
- **Form Validation**: Comprehensive client-side validation for all fields
- **Password Visibility**: Toggle password visibility for better UX
- **Responsive Design**: Works on mobile and desktop with scroll support

### 🔐 Firebase Authentication Integration
- **User Registration**: Create new accounts with email/password
- **Email Verification**: Automatic email verification with custom welcome emails
- **Secure Login**: Firebase Auth integration with session persistence
- **Password Reset**: Forgot password functionality with email links
- **Profile Management**: User profile data stored in Firestore

### 📱 User Experience Improvements
- **Auto-Login**: Persistent authentication across app restarts
- **Guest Mode**: Continue using the app without registration
- **Logout Confirmation**: Safe logout with confirmation dialog
- **Loading States**: Visual feedback during authentication operations
- **Error Handling**: User-friendly error messages for all scenarios

## Setup Instructions

### 1. Firebase Project Setup (Required for Production)

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Enable Authentication and Firestore Database

2. **Configure Authentication**:
   - In Firebase Console, go to Authentication > Sign-in method
   - Enable "Email/Password" provider
   - Configure authorized domains for your app

3. **Get Configuration Values**:
   - Go to Project Settings > General tab
   - Add a Web app if you haven't already
   - Copy the Firebase config object

4. **Update Firebase Configuration**:
   ```dart
   // lib/firebase_options.dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'your-actual-api-key',              // Replace with your API key
     appId: 'your-actual-app-id',                // Replace with your app ID
     messagingSenderId: 'your-actual-sender-id', // Replace with your sender ID
     projectId: 'your-actual-project-id',        // Replace with your project ID
     authDomain: 'your-project.firebaseapp.com', // Replace with your auth domain
     storageBucket: 'your-project.appspot.com',  // Replace with your storage bucket
   );
   ```

### 2. Email Configuration (Optional)

If you want custom welcome emails, configure SMTP settings:

```dart
// lib/services/auth_service.dart
static const String _senderEmail = 'your-email@gmail.com';
static const String _senderPassword = 'your-app-password'; // Use Gmail App Password
```

**Note**: For production, use environment variables or secure configuration management.

### 3. Development Mode (No Firebase Required)

For development without Firebase setup:

1. **Comment out Firebase initialization** in `main.dart`:
   ```dart
   // await Firebase.initializeApp(
   //   options: DefaultFirebaseOptions.currentPlatform,
   // );
   ```

2. **Use Guest Mode**: Click "Continue as Guest" to use the app without authentication

## Authentication Flow

### Registration Process
1. User fills out registration form (name, email, password, confirm password)
2. Client-side validation ensures all fields are valid
3. Firebase creates user account with email/password
4. User profile data is stored in Firestore
5. Email verification is sent automatically
6. Custom welcome email with app information is sent
7. User is redirected to login mode to sign in with verified email

### Login Process
1. User enters email and password
2. Firebase authenticates the credentials
3. System checks if email is verified
4. If verified, user profile is loaded from Firestore
5. User is logged into the app with persistent session
6. If not verified, new verification email is sent

### Password Reset
1. User clicks "Forgot Password?" on login screen
2. Enters email address
3. Firebase sends password reset email
4. User follows link in email to create new password

### Session Management
- **Persistent Login**: Users stay logged in across app restarts
- **Auto-refresh**: User data is refreshed to get latest verification status
- **Secure Logout**: Properly signs out from Firebase and clears local state

## File Structure Changes

### New Files Added
- `lib/services/auth_service.dart` - Firebase authentication service
- `lib/firebase_options.dart` - Firebase configuration (needs your values)

### Modified Files
- `lib/screens/auth/login_screen.dart` - Enhanced with registration mode
- `lib/providers/app_state.dart` - Firebase integration and persistent auth
- `lib/models/user.dart` - Added email verification field
- `lib/screens/dashboard_screen.dart` - Added logout functionality
- `lib/main.dart` - Firebase initialization
- `pubspec.yaml` - Added Firebase and email dependencies

## Security Considerations

### Production Deployment
1. **Environment Variables**: Store Firebase config and email credentials securely
2. **Firestore Rules**: Configure proper security rules for user data
3. **API Keys**: Restrict Firebase API keys to specific domains/apps
4. **Email Security**: Use app-specific passwords for Gmail SMTP

### Privacy Compliance
- Email addresses are stored securely in Firebase Auth
- User profile data is stored in Firestore with proper access controls
- Users can delete their accounts (implement user.delete() if needed)

## Testing the Authentication

### Manual Testing Steps
1. **Registration**: 
   - Try registering with invalid emails/passwords (should show errors)
   - Register with valid data (should show success message)
   - Check email for verification link

2. **Login**:
   - Try logging in before email verification (should prompt to verify)
   - Try with wrong password (should show error)
   - Login after email verification (should succeed)

3. **Password Reset**:
   - Click "Forgot Password" and enter email
   - Check email for reset link
   - Reset password and try logging in

4. **Guest Mode**:
   - Click "Continue as Guest" (should work without Firebase)

### Common Issues
1. **Firebase Web Build Errors**: Current Firebase packages have compatibility issues with Flutter web builds
2. **Email Delivery**: Gmail SMTP may require app-specific passwords
3. **CORS Issues**: Add your domain to Firebase authorized domains

## Future Enhancements

### Planned Features
- **Social Authentication**: Google, Apple, Facebook login
- **Phone Authentication**: SMS verification for phone numbers  
- **Multi-Factor Authentication**: Additional security layer
- **Profile Management**: Edit profile, change password, delete account
- **Email Templates**: Custom HTML email templates
- **Admin Panel**: User management and analytics

### Integration Points
- **Study Data Sync**: Sync flashcards, tasks, and progress to user accounts
- **Cross-Device**: Access study materials across multiple devices
- **Backup/Restore**: Cloud backup of user data
- **Social Features**: Share study materials with other users

## Support

If you encounter issues with the authentication system:

1. Check the Flutter console for error messages
2. Verify Firebase configuration is correct
3. Ensure email verification is working
4. Test with different email providers
5. Check Firebase Console for authentication logs

For Firebase-specific issues, refer to the [Firebase Documentation](https://firebase.google.com/docs/auth).
