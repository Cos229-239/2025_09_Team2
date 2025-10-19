# Firebase Project Recovery Guide

## Incident Report
- **Date**: October 16, 2025
- **Incident**: Firebase project completely removed by rogue engineer
- **Project ID (OLD)**: studypals-9f7e1
- **Status**: Complete project deletion - full recovery required

---

## ✅ What We Have Saved (Good News!)

All critical configurations are backed up in version control:
- ✅ Firestore security rules (`firestore.rules`)
- ✅ Storage security rules (`storage.rules`)
- ✅ Firestore indexes (`firestore.indexes.json`)
- ✅ Firebase configuration (`firebase.json`)
- ✅ Application code and structure

---

## 🔴 What Was Lost

- ❌ All Firestore data (user profiles, sessions, analytics, etc.)
- ❌ All Firebase Storage files (profile pictures, etc.)
- ❌ Authentication user accounts
- ❌ Firebase project configuration
- ❌ Analytics history
- ❌ Cloud Functions (if any were deployed)

---

## 📋 Step-by-Step Recovery Process

### Phase 1: Create New Firebase Project (10 minutes)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Sign in with your Google account

2. **Create New Project**
   - Click "Add project" or "Create a project"
   - **Project name**: `StudyPals` (or `StudyPals-Production`)
   - Optionally enable Google Analytics
   - Click "Create project"

3. **Note Your New Project ID**
   - Once created, note the new project ID (it will be different from the old one)
   - You'll see it in the URL and project settings

### Phase 2: Configure Firebase Services (15 minutes)

#### A. Enable Authentication

1. In Firebase Console, go to **Build → Authentication**
2. Click "Get started"
3. Enable the following sign-in methods:
   - ✅ Email/Password
   - ✅ Google Sign-In (if needed)
   - ✅ Any other providers you were using

#### B. Enable Firestore Database

1. Go to **Build → Firestore Database**
2. Click "Create database"
3. **Select production mode** (we'll deploy our rules)
4. Choose your region (prefer: `us-central1` or closest to your users)
5. Click "Enable"

#### C. Enable Storage

1. Go to **Build → Storage**
2. Click "Get started"
3. **Start in production mode** (we'll deploy our rules)
4. Use the same region as Firestore
5. Click "Done"

#### D. Enable Firebase Hosting (if needed)

1. Go to **Build → Hosting**
2. Click "Get started"
3. Follow the setup wizard

### Phase 3: Add Your Apps (20 minutes)

#### Android App Setup

1. In Firebase Console, click the Android icon to add an Android app
2. **Android package name**: `com.example.studypals`
3. **App nickname**: StudyPals Android
4. Click "Register app"
5. **Download `google-services.json`**
6. Replace the file at: `android/app/google-services.json`
7. Complete the setup wizard

#### iOS App Setup (if applicable)

1. Click the iOS icon to add an iOS app
2. **iOS bundle ID**: (check your iOS project)
3. **App nickname**: StudyPals iOS
4. Click "Register app"
5. **Download `GoogleService-Info.plist`**
6. Add it to your iOS project
7. Complete the setup wizard

#### Web App Setup (if applicable)

1. Click the Web icon to add a web app
2. **App nickname**: StudyPals Web
3. Register the app
4. Copy the Firebase config object
5. Update your web initialization code

### Phase 4: Deploy Security Rules and Indexes (5 minutes)

After creating the new project, run these commands in PowerShell:

```powershell
# Make sure you're in the project directory
cd c:\Users\nolen\studypalsv2\StudyPals

# Login to Firebase (if not already)
firebase login

# Select your new project
firebase use --add

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Storage rules
firebase deploy --only storage

# (Optional) Deploy all at once
firebase deploy
```

### Phase 5: Update Local Configuration Files

#### Update `firebase.json` (if needed)

The current `firebase.json` should work, but verify the hosting site name:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "hosting": {
    "site": "studypals",  // Update if needed
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Phase 6: Test the Application (30 minutes)

1. **Build and run the Flutter app**:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test critical features**:
   - ✅ User registration/login
   - ✅ Data persistence (Firestore writes)
   - ✅ File uploads (Storage)
   - ✅ All main app features

3. **Monitor Firebase Console**:
   - Check Firestore for new documents
   - Check Storage for new files
   - Check Authentication for new users

---

## 🔒 Security Measures to Prevent Future Incidents

### Immediate Actions

1. **Review Team Access**
   - Go to Project Settings → Users and permissions
   - Remove the rogue engineer immediately
   - Review all other team members' access levels

2. **Implement Access Controls**
   - Use **Editor** role only for trusted developers
   - Use **Viewer** role for others who need read access
   - Reserve **Owner** role for only 1-2 trusted people

3. **Enable Multi-Factor Authentication**
   - Require MFA for all team members with Firebase access
   - Go to Google Account settings → Security → 2-Step Verification

### Long-Term Protections

1. **Separate Production and Development Projects**
   - Create: `StudyPals-Production` (live users)
   - Create: `StudyPals-Development` (testing)
   - Never give developers owner access to production

2. **Set Up Automated Backups**
   
   Create a Cloud Function or scheduled job to export Firestore data:
   ```javascript
   // Example: Daily Firestore backup
   // This requires Blaze plan
   ```

3. **Enable Audit Logging**
   - In Google Cloud Console (not Firebase Console)
   - Go to IAM & Admin → Audit Logs
   - Enable audit logs for all Firebase services

4. **Version Control Everything**
   - ✅ Already doing this! Keep it up.
   - Always commit security rules before deploying
   - Use PR reviews for production deployments

5. **Set Up Monitoring and Alerts**
   - Use Firebase Alerts for unusual activity
   - Set up Cloud Monitoring for configuration changes
   - Create Slack/email alerts for critical events

---

## 📊 Data Recovery Options

### If You Have Backups

1. **Check Google Cloud Storage** for any automated exports
2. **Check local databases** - any team members with offline data?
3. **Check staging/development** environments for sample data
4. **Contact Firebase Support** (if on Blaze plan) - they may have point-in-time recovery

### If No Backups Available

Unfortunately, if the project was completely deleted and you have no backups:
- User data is **unrecoverable**
- You'll need to start fresh with new user registrations
- Consider this a hard lesson on the importance of backups

**Recommendation**: 
- Communicate honestly with users about the data loss
- Offer incentives for re-registration
- Implement the backup strategy immediately

---

## 📝 Checklist for Recovery

- [ ] Create new Firebase project
- [ ] Enable Authentication
- [ ] Enable Firestore Database
- [ ] Enable Storage
- [ ] Add Android app and download `google-services.json`
- [ ] Add iOS app and download `GoogleService-Info.plist` (if applicable)
- [ ] Add Web app and update config (if applicable)
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login to Firebase: `firebase login`
- [ ] Initialize project: `firebase use --add`
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Firestore indexes: `firebase deploy --only firestore:indexes`
- [ ] Deploy Storage rules: `firebase deploy --only storage`
- [ ] Update app configuration files
- [ ] Test authentication
- [ ] Test Firestore read/write
- [ ] Test Storage upload/download
- [ ] Remove rogue engineer's access
- [ ] Enable MFA for all team members
- [ ] Set up separate dev/prod projects
- [ ] Implement automated backups
- [ ] Enable audit logging
- [ ] Document incident for future reference

---

## 🆘 Need Help?

If you encounter issues during recovery:

1. **Firebase Documentation**: https://firebase.google.com/docs
2. **Firebase Support**: https://firebase.google.com/support (Blaze plan required)
3. **Stack Overflow**: Tag questions with `firebase` and `flutter`
4. **Flutter Discord**: https://discord.gg/flutter

---

## 📞 Contact Firebase Support

If you're on the Blaze (paid) plan:
- Go to: https://firebase.google.com/support/contact
- Select "Technical Support"
- Explain the incident and ask if any recovery is possible
- Provide the old project ID: `studypals-9f7e1`
- Reference the incident date: October 16, 2025

**Act quickly** - the sooner you contact them, the better chance of any recovery.

---

## Legal Considerations

Document everything about this incident:
- Screenshots of what's missing
- Timeline of events
- Communication with the rogue engineer
- Financial impact assessment

Consider:
- Reporting to law enforcement if data was maliciously destroyed
- Consulting with a lawyer about potential damages
- Reviewing employment contracts and NDAs
- Implementing employee off-boarding procedures

---

**Remember**: While this is a setback, your app's code and architecture are intact. You can rebuild the database structure, and with proper security measures, prevent this from happening again.

Good luck with the recovery! 🚀
