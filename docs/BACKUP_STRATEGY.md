# Firebase Backup Strategy - Never Lose Data Again!

## Overview

After the incident on October 16, 2025, where a rogue engineer deleted the entire Firebase project, we're implementing a comprehensive backup strategy to prevent data loss.

---

## 🎯 Backup Goals

1. **Automated daily backups** of all Firestore data
2. **Version-controlled security rules** (already doing this! ✅)
3. **Separate production and development environments**
4. **Quick recovery process** (< 1 hour to restore)
5. **Multiple backup locations** for redundancy

---

## ✅ What's Already Protected

### Version Control (Git) ✅
Already backing up:
- ✅ Firestore security rules (`firestore.rules`)
- ✅ Storage security rules (`storage.rules`)
- ✅ Firestore indexes (`firestore.indexes.json`)
- ✅ Firebase configuration (`firebase.json`)
- ✅ All application code

**Location**: GitHub repository `NOYA-COSC/StudyPals`

---

## 🔴 What's NOT Protected (Needs Backup)

### User Data
- ❌ Firestore database content (user profiles, tasks, notes, etc.)
- ❌ Firebase Storage files (profile pictures, uploads)
- ❌ Authentication user accounts
- ❌ Analytics data

---

## 📋 Backup Implementation Plan

### Phase 1: Manual Exports (Do This Now!)

#### 1. Export Firestore Data Manually

**Method 1: Using Firebase Console**
1. Go to https://console.firebase.google.com/project/studypals-c4f44/firestore
2. Click the three dots ⋮ menu → **"Export data"**
3. Choose destination: Cloud Storage bucket
4. Click "Export"

**Method 2: Using gcloud CLI** (Recommended)

Install Google Cloud SDK first:
```powershell
# Install gcloud CLI
# Download from: https://cloud.google.com/sdk/docs/install

# After installation, authenticate
gcloud auth login

# Set your project
gcloud config set project studypals-c4f44

# Export Firestore
gcloud firestore export gs://studypals-c4f44.appspot.com/backups/manual-$(Get-Date -Format 'yyyy-MM-dd')
```

#### 2. Download User Authentication Data

Unfortunately, Firebase doesn't provide an easy way to export auth users. But you can:

1. **Go to**: https://console.firebase.google.com/project/studypals-c4f44/authentication/users
2. **Use the Firebase Admin SDK** to export users programmatically

**Create a backup script**: `scripts/backup-auth-users.js`

```javascript
// scripts/backup-auth-users.js
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function backupUsers() {
  const users = [];
  let nextPageToken;

  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    users.push(...result.users.map(user => ({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      creationTime: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
    })));
    nextPageToken = result.pageToken;
  } while (nextPageToken);

  const timestamp = new Date().toISOString().replace(/:/g, '-');
  fs.writeFileSync(
    `backups/users-${timestamp}.json`,
    JSON.stringify(users, null, 2)
  );
  
  console.log(`✅ Backed up ${users.length} users`);
}

backupUsers().catch(console.error);
```

---

### Phase 2: Automated Daily Backups (Blaze Plan Required)

#### Option A: Cloud Scheduler + Cloud Functions

**1. Create a Cloud Function for Automated Backups**

Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const firestore = require('@google-cloud/firestore');
const client = new firestore.v1.FirestoreAdminClient();

exports.scheduledFirestoreExport = functions.pubsub
  .schedule('every day 02:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    const databaseName = client.databasePath(projectId, '(default)');
    const bucket = `gs://${projectId}.appspot.com/backups`;
    
    const timestamp = new Date().toISOString().split('T')[0];
    const outputUriPrefix = `${bucket}/${timestamp}`;

    try {
      const responses = await client.exportDocuments({
        name: databaseName,
        outputUriPrefix: outputUriPrefix,
        collectionIds: [], // Empty = export all collections
      });

      console.log(`✅ Backup started: ${responses[0].name}`);
      return { success: true, operation: responses[0].name };
    } catch (error) {
      console.error('❌ Backup failed:', error);
      throw error;
    }
  });
```

**2. Deploy the Function**

```powershell
# Install Firebase Functions
npm install -g firebase-functions

# Initialize functions
firebase init functions

# Deploy
firebase deploy --only functions
```

#### Option B: Google Cloud Scheduler (Simpler)

1. **Go to**: https://console.cloud.google.com/cloudscheduler
2. **Click "Create Job"**
3. **Configure**:
   - Name: `daily-firestore-backup`
   - Frequency: `0 2 * * *` (2 AM daily)
   - Timezone: Your timezone
   - Target: HTTP
   - URL: Your backup trigger URL
4. **Save**

---

### Phase 3: Separate Production and Development

**Current Setup**: 
- Production: `studypals-c4f44` (live users)

**Create Development Project**:

1. **Create a new Firebase project**: `studypals-dev`
2. **Use for all development and testing**
3. **Never give developers owner access to production**

**Update your workflow**:

```powershell
# For development
firebase use studypals-dev
flutter run

# For production (releases only)
firebase use studypals-c4f44
firebase deploy
```

---

## 🔒 Access Control & Security

### Firebase Project Roles

**Production Project (`studypals-c4f44`)**:
- **Owner**: Only 1-2 trusted people (you + backup)
- **Editor**: Senior developers who need deploy access
- **Viewer**: Everyone else

**Development Project (`studypals-dev`)**:
- **Editor**: All developers
- **Owner**: You

### Implement These Rules:

1. ✅ **Remove the rogue engineer immediately** from all projects
2. ✅ **Require MFA** for all team members with Firebase access
3. ✅ **Enable audit logging** in Google Cloud Console
4. ✅ **Set up alerts** for project configuration changes
5. ✅ **Review access quarterly** and remove inactive members

---

## 📂 Backup Storage Locations

### Primary Backup: Google Cloud Storage
- Automated exports go here
- 30-day retention policy
- Cross-region replication

### Secondary Backup: External Storage
- Download monthly snapshots to local/external drive
- Store in separate cloud provider (AWS S3, Dropbox, etc.)
- Keep for 1 year

### Tertiary Backup: Git
- Security rules (already doing this ✅)
- Application code (already doing this ✅)

---

## 🔄 Recovery Process

### If Firebase Project is Deleted:

**Time to Recover**: ~2-4 hours

1. **Create new Firebase project** (15 min)
2. **Deploy security rules** from git (5 min)
3. **Import latest Firestore backup** (30-60 min)
4. **Update app configuration** (15 min)
5. **Test critical features** (30-60 min)
6. **Deploy to production** (15 min)

### Recovery Commands:

```powershell
# 1. Create new project in Firebase Console

# 2. Configure Flutter app
flutterfire configure --project=new-project-id

# 3. Deploy rules
firebase use new-project-id
firebase deploy --only firestore:rules,firestore:indexes,storage

# 4. Import Firestore data
gcloud firestore import gs://studypals-c4f44.appspot.com/backups/2025-10-15

# 5. Rebuild and test
flutter clean
flutter pub get
flutter run
```

---

## 📊 Backup Monitoring

### Set Up Alerts:

1. **Daily backup success notification**
   - Email when backup completes
   - Alert if backup fails

2. **Storage usage monitoring**
   - Alert if backup storage is filling up
   - Clean up old backups automatically

3. **Access log monitoring**
   - Alert on suspicious project access
   - Alert on configuration changes

### Monitor These Metrics:

- ✅ Last successful backup time
- ✅ Backup file size (should be consistent)
- ✅ Number of documents backed up
- ✅ Backup storage costs

---

## 💰 Cost Estimates

### Blaze Plan Costs (Pay-as-you-go):

**Daily Firestore Exports**:
- Small app (< 1GB): ~$0.50/month
- Medium app (1-10GB): ~$5/month
- Large app (> 10GB): ~$20+/month

**Cloud Storage for Backups**:
- ~$0.02/GB/month
- Example: 5GB of backups = $0.10/month

**Total Estimated Cost**: $1-10/month for peace of mind

---

## ✅ Implementation Checklist

### Immediate Actions (Do Today):
- [ ] Remove rogue engineer's access from all projects
- [ ] Change all admin passwords
- [ ] Enable MFA for all team members
- [ ] Create manual Firestore export
- [ ] Download current user list
- [ ] Document what was lost in the incident

### This Week:
- [ ] Create development Firebase project
- [ ] Set up automated daily backups
- [ ] Configure Cloud Scheduler
- [ ] Test backup and restore process
- [ ] Set up monitoring alerts
- [ ] Review and update team access permissions

### This Month:
- [ ] Implement proper CI/CD with separate environments
- [ ] Set up automated testing before production deploys
- [ ] Create runbook for emergency recovery
- [ ] Train team on backup procedures
- [ ] Set up quarterly access reviews

---

## 📝 Backup Schedule

| Frequency | What | How | Retention |
|-----------|------|-----|-----------|
| Daily | Firestore data | Automated export | 30 days |
| Weekly | Storage files | Manual/scripted | 60 days |
| Monthly | Full snapshot | Download locally | 1 year |
| On deploy | Security rules | Git commit | Forever |
| Quarterly | User audit | Manual review | 1 year |

---

## 🆘 Emergency Contacts

**If disaster strikes again**:

1. **Firebase Support** (Blaze plan): https://firebase.google.com/support/contact
2. **Google Cloud Support**: https://cloud.google.com/support
3. **Your Team Lead**: [Add contact info]
4. **Backup Administrator**: [Add contact info]

---

## 📖 Additional Resources

- [Firebase Backup Best Practices](https://firebase.google.com/docs/firestore/manage-data/export-import)
- [Firestore Export/Import](https://cloud.google.com/firestore/docs/manage-data/export-import)
- [Firebase Security Checklist](https://firebase.google.com/support/guides/security-checklist)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)

---

## 🎯 Success Metrics

You'll know your backup strategy is working when:

- ✅ Automated backups run daily without failures
- ✅ You can restore a backup in < 1 hour
- ✅ Team has limited access based on role
- ✅ You sleep better at night knowing your data is safe

---

**Remember**: The best backup is the one you never need, but always have! 🛡️

**Last Updated**: October 16, 2025
**Next Review**: November 16, 2025
