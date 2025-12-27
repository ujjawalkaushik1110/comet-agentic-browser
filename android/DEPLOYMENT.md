# Comet Browser Android - Build & Deployment Guide

## 📋 Prerequisites

### Required Software
- **Android Studio**: Hedgehog (2023.1.1) or later
- **JDK**: Version 17 (bundled with Android Studio)
- **Android SDK**: 
  - Minimum SDK: 26 (Android 8.0)
  - Target SDK: 34 (Android 14)
  - Compile SDK: 34

### Google Play Console Setup
1. Create a Google Play Developer account ($25 one-time fee)
2. Create a new application in Play Console
3. Fill in store listing information
4. Set up content rating
5. Configure pricing and distribution

## 🔑 Generate Signing Key

### Step 1: Create Keystore

```bash
keytool -genkey -v \
  -keystore comet-browser-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias comet-browser
```

**Answer the prompts:**
- Enter keystore password
- Re-enter password
- Enter your name, organization, etc.
- Enter key password (can be same as keystore password)

**⚠️ CRITICAL: Store this keystore and passwords securely!**
- Losing the keystore means you can't update the app
- Never commit to version control
- Back up to secure location

### Step 2: Configure keystore.properties

Create `android/keystore.properties`:

```properties
storeFile=/absolute/path/to/comet-browser-release.jks
storePassword=YourKeystorePassword
keyAlias=comet-browser
keyPassword=YourKeyPassword
```

## 🏗️ Build Process

### Development Build (Debug)

```bash
cd android
./gradlew assembleProductionDebug
```

Output: `app/build/outputs/apk/production/debug/`

### Staging Build

```bash
./gradlew assembleProductionStaging
```

### Production Release Build

#### Option 1: APK (for direct distribution)

```bash
./gradlew assembleProductionRelease
```

Output: `app/build/outputs/apk/production/release/app-production-release.apk`

#### Option 2: App Bundle (for Google Play)

```bash
./gradlew bundleProductionRelease
```

Output: `app/build/outputs/bundle/productionRelease/app-production-release.aab`

**Recommended: Use App Bundle for Google Play for smaller download sizes**

## 🧪 Pre-Release Checklist

### 1. Update Version

Edit `gradle.properties`:
```properties
VERSION_CODE=2
VERSION_NAME=1.0.1
```

**Rules:**
- `VERSION_CODE` must be incremented for each release
- `VERSION_NAME` is user-facing (semantic versioning)

### 2. Update API Endpoint

Ensure `local.properties` points to production:
```properties
API_BASE_URL=https://your-production-api.azurewebsites.net/
```

### 3. Run Tests

```bash
# Unit tests
./gradlew test

# Instrumented tests
./gradlew connectedAndroidTest

# Lint checks
./gradlew lint
```

### 4. ProGuard Verification

```bash
# Build release and verify no crashes
./gradlew assembleProductionRelease

# Check ProGuard mapping file
cat app/build/outputs/mapping/productionRelease/mapping.txt
```

### 5. Manual Testing

Test on multiple devices:
- [ ] Authentication flow
- [ ] Browse task creation
- [ ] Task synchronization
- [ ] Offline mode
- [ ] Background services
- [ ] Push to background and restore
- [ ] Rotation handling
- [ ] Network error handling

## 📦 Google Play Deployment

### Step 1: Prepare Store Listing

Required assets:
- App icon (512x512 PNG)
- Feature graphic (1024x500 PNG)
- Screenshots (at least 2, various sizes)
- Short description (80 chars)
- Full description (4000 chars)
- Privacy policy URL

### Step 2: Create Release in Play Console

1. Go to Play Console → Your App → Production
2. Click "Create new release"
3. Upload App Bundle (.aab file)
4. Fill in release notes
5. Review and roll out

### Step 3: Release Tracks

**Internal Testing**
- For team testing
- Up to 100 testers
- No review required

**Closed Testing (Alpha/Beta)**
- For larger test groups
- Up to 1000+ testers
- Faster review

**Open Testing**
- Public beta
- Anyone can join
- Same review as production

**Production**
- Live to all users
- Full review process (usually 1-3 days)

### Step 4: Staged Rollout

Recommended approach:
1. Start with 5% of users
2. Monitor crash reports for 24-48 hours
3. Increase to 20%
4. Monitor for another 24 hours
5. Increase to 50%
6. Monitor for 24 hours
7. Roll out to 100%

## 🔄 Update Process

### Patch Release (1.0.1 → 1.0.2)

1. Update `VERSION_CODE` and `VERSION_NAME`
2. Make bug fixes
3. Test thoroughly
4. Build release
5. Upload to Play Console
6. Create release notes
7. Submit for review

### Minor Release (1.0.x → 1.1.0)

Same as patch, plus:
- Update marketing materials
- Announce new features
- Update screenshots if UI changed

### Major Release (1.x.x → 2.0.0)

Same as minor, plus:
- Update privacy policy if needed
- Review all permissions
- Update content rating if needed
- Major marketing push

## 🐛 Troubleshooting

### Build Failures

**Issue: Keystore not found**
```
Solution: Check keystore.properties path is absolute
```

**Issue: Duplicate class errors**
```
Solution: Clean build
./gradlew clean
./gradlew assembleProductionRelease
```

**Issue: Out of memory**
```
Solution: Increase Gradle memory in gradle.properties:
org.gradle.jvmargs=-Xmx4096m
```

### ProGuard Issues

**Issue: Crash in release but not debug**
```
Solution: Check ProGuard rules in proguard-rules.pro
Add keep rules for affected classes
```

**Issue: Missing classes after obfuscation**
```
Solution: Check mapping file and add:
-keep class com.your.package.** { *; }
```

### Upload Failures

**Issue: Version code already exists**
```
Solution: Increment VERSION_CODE
```

**Issue: Package name conflict**
```
Solution: Ensure package name matches Play Console
```

## 📊 Post-Release Monitoring

### Play Console Metrics

Monitor:
- Crash rate (keep < 1%)
- ANR rate (keep < 0.5%)
- Install/uninstall rate
- User ratings
- Review sentiment

### Crash Reporting

Configure Firebase Crashlytics or similar:

1. Add dependency to `build.gradle`
2. Add Firebase configuration
3. Monitor crash reports
4. Fix critical crashes ASAP

### Performance Monitoring

Use Android Vitals:
- App startup time
- Frame rendering
- Battery usage
- Network usage

## 🔐 Security Best Practices

### Before Release

- [ ] Remove all debug logging
- [ ] Disable debug features
- [ ] Use HTTPS only
- [ ] Validate all inputs
- [ ] Encrypt sensitive data
- [ ] Use latest library versions
- [ ] Enable R8/ProGuard
- [ ] Review permissions

### API Keys

- [ ] Never hardcode API keys
- [ ] Use BuildConfig for configuration
- [ ] Rotate keys after public releases
- [ ] Monitor API usage

## 📱 Device Testing

### Minimum Test Matrix

Test on:
- Low-end device (Android 8.0, 2GB RAM)
- Mid-range device (Android 11, 4GB RAM)
- High-end device (Android 14, 8GB+ RAM)
- Tablet (10" screen)

### Form Factors

- [ ] Phone (5-7 inches)
- [ ] Large phone (6.5+ inches)
- [ ] Tablet (7-10 inches)
- [ ] Foldable (if possible)

## 📋 Release Checklist

- [ ] Version code incremented
- [ ] Version name updated
- [ ] API endpoint set to production
- [ ] Keystore configured
- [ ] All tests pass
- [ ] Lint checks pass
- [ ] ProGuard mapping saved
- [ ] Release notes written
- [ ] Screenshots updated
- [ ] Privacy policy current
- [ ] Team notified
- [ ] Monitoring configured
- [ ] Rollback plan ready

## 🚀 CI/CD with GitHub Actions

Create `.github/workflows/android-release.yml`:

```yaml
name: Android Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Decode Keystore
      env:
        ENCODED_STRING: ${{ secrets.KEYSTORE_BASE64 }}
      run: |
        echo $ENCODED_STRING | base64 -d > android/keystore.jks
    
    - name: Build Release AAB
      env:
        SIGNING_KEY_ALIAS: ${{ secrets.SIGNING_KEY_ALIAS }}
        SIGNING_KEY_PASSWORD: ${{ secrets.SIGNING_KEY_PASSWORD }}
        SIGNING_STORE_PASSWORD: ${{ secrets.SIGNING_STORE_PASSWORD }}
      run: |
        cd android
        ./gradlew bundleProductionRelease
    
    - name: Upload to Play Console
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT }}
        packageName: com.comet.browser
        releaseFiles: android/app/build/outputs/bundle/productionRelease/app-production-release.aab
        track: production
        status: draft
```

## 📞 Support

For deployment issues:
- Check [Android Developer Documentation](https://developer.android.com)
- Visit [Play Console Help](https://support.google.com/googleplay/android-developer)
- Contact: android-support@cometbrowser.com

---

**Remember:** Always test thoroughly before releasing to production!
