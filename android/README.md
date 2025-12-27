# Comet Browser - Android App

<div align="center">
  <img src="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="Comet Browser Logo" width="120"/>
  
  <h3>Native Android App for Agentic Browser Automation</h3>
  
  [![Android](https://img.shields.io/badge/Android-26%2B-green.svg)](https://android.com)
  [![Kotlin](https://img.shields.io/badge/Kotlin-1.9.21-blue.svg)](https://kotlinlang.org)
  [![Material Design 3](https://img.shields.io/badge/Material%20Design-3-blue.svg)](https://m3.material.io)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
</div>

## 📱 Features

### Core Functionality
- ✅ **Browser Automation** - Execute web browsing tasks with custom actions
- ✅ **Real-time Monitoring** - Track task progress and status in real-time
- ✅ **Offline Support** - Full offline functionality with local caching
- ✅ **Background Sync** - Automatic synchronization with background services
- ✅ **WebView Integration** - View results directly in-app

### Technical Features
- 🏗️ **Clean Architecture** - MVVM pattern with Repository layer
- 💉 **Dependency Injection** - Hilt for dependency management
- 🗄️ **Local Database** - Room database for offline persistence
- 🔄 **REST API Integration** - Retrofit with OkHttp
- 🎨 **Material Design 3** - Modern UI following Material guidelines
- 🔐 **Secure Authentication** - Encrypted DataStore for credentials
- 🔁 **Retry Logic** - Exponential backoff for network failures
- 📊 **WorkManager** - Reliable background task execution

## 🏗️ Architecture

```
app/
├── data/
│   ├── local/           # Room database, DAOs, Converters
│   ├── remote/          # Retrofit services
│   ├── repository/      # Repository pattern implementations
│   ├── model/           # Data models and entities
│   ├── service/         # Foreground services
│   └── worker/          # WorkManager workers
├── domain/
│   └── model/           # Domain models (Resource, etc.)
├── presentation/
│   ├── auth/            # Authentication UI
│   ├── main/            # Main task list UI
│   ├── task/            # Task detail UI
│   ├── webview/         # WebView UI
│   └── splash/          # Splash screen
├── di/                  # Dependency injection modules
└── utils/               # Utility classes
```

### Architecture Diagram

```
┌─────────────────┐
│  Presentation   │  Activities, ViewModels, Adapters
└────────┬────────┘
         │
┌────────▼────────┐
│    Domain       │  Use Cases, Models
└────────┬────────┘
         │
┌────────▼────────┐
│     Data        │  Repositories, Data Sources
└─────┬───┬───┬───┘
      │   │   │
┌─────▼┐ ┌▼──┐│
│ Room │ │API││
└──────┘ └───┘│
              │
         ┌────▼────┐
         │ Network │
         └─────────┘
```

## 🚀 Getting Started

### Prerequisites

- Android Studio Hedgehog (2023.1.1) or later
- JDK 17
- Android SDK 26+ (minimum)
- Android SDK 34 (target)

### Installation

1. **Clone the repository**
   ```bash
   cd android
   ```

2. **Configure API endpoint**
   ```bash
   cp local.properties.template local.properties
   # Edit local.properties and set your API URL:
   # API_BASE_URL=https://your-app.azurewebsites.net/
   ```

3. **Open in Android Studio**
   - Open Android Studio
   - Select "Open an Existing Project"
   - Navigate to the `android` directory
   - Click "OK"

4. **Sync Gradle**
   - Android Studio will automatically sync Gradle
   - If not, click "File" → "Sync Project with Gradle Files"

5. **Run the app**
   - Select a device or emulator
   - Click the "Run" button (▶️)

### Build Variants

The app has 3 build types and 2 flavors:

**Build Types:**
- `debug` - Debug build with logging enabled
- `staging` - Staging build for testing
- `release` - Production release build

**Flavors:**
- `production` - Production environment
- `development` - Development environment

**Examples:**
- `productionDebug` - Production API with debug features
- `productionRelease` - Production API, release build
- `developmentDebug` - Development API with debug features

## 📦 Building for Release

### 1. Generate Keystore

```bash
keytool -genkey -v -keystore comet-browser.jks -keyalg RSA -keysize 2048 -validity 10000 -alias comet-browser
```

### 2. Configure Signing

Create `keystore.properties` in the project root:

```properties
storeFile=/path/to/comet-browser.jks
storePassword=your_keystore_password
keyAlias=comet-browser
keyPassword=your_key_password
```

**⚠️ IMPORTANT:** Never commit `keystore.properties` or your keystore file to version control!

### 3. Build Release APK

```bash
./gradlew assembleProductionRelease
```

Output: `app/build/outputs/apk/production/release/app-production-release.apk`

### 4. Build App Bundle (for Google Play)

```bash
./gradlew bundleProductionRelease
```

Output: `app/build/outputs/bundle/productionRelease/app-production-release.aab`

## 🧪 Testing

### Run Unit Tests

```bash
./gradlew test
```

### Run Instrumented Tests

```bash
./gradlew connectedAndroidTest
```

### Test Coverage

```bash
./gradlew jacocoTestReport
```

View coverage report: `app/build/reports/jacoco/test/html/index.html`

## 📚 Dependencies

### Core
- **AndroidX Core** - Core Android libraries
- **Material 3** - Material Design components
- **Kotlin Coroutines** - Asynchronous programming

### Architecture
- **Hilt** - Dependency injection
- **Lifecycle** - ViewModel, LiveData
- **Navigation** - Fragment navigation
- **DataStore** - Encrypted preferences

### Database
- **Room** - Local SQLite database
- **Room KTX** - Kotlin extensions for Room

### Networking
- **Retrofit** - REST API client
- **OkHttp** - HTTP client
- **Gson** - JSON parsing

### Background Tasks
- **WorkManager** - Background job scheduler
- **Hilt WorkManager** - DI integration

### UI
- **RecyclerView** - List display
- **SwipeRefreshLayout** - Pull-to-refresh
- **WebView** - In-app browser
- **SplashScreen** - Splash screen API

### Utilities
- **Timber** - Logging
- **Coil** - Image loading

### Testing
- **JUnit** - Unit testing framework
- **Mockito** - Mocking framework
- **Espresso** - UI testing

## 🔐 Security

### Authentication
- JWT token-based authentication
- Secure storage using EncryptedDataStore
- Automatic token refresh

### Network Security
- HTTPS only (cleartext disabled in production)
- Certificate pinning (can be enabled)
- Network Security Config for fine-grained control

### Data Protection
- Room database encryption (can be enabled)
- ProGuard/R8 obfuscation for release builds
- No sensitive data in logs (production)

## 🎨 UI/UX

### Material Design 3
- Dynamic color theming
- Adaptive layouts
- Responsive design

### Screens
1. **Splash Screen** - App branding and loading
2. **Auth Screen** - Login/Register
3. **Main Screen** - Task list with SwipeRefreshLayout
4. **Task Detail** - Detailed task information
5. **WebView Screen** - View browsing results

### Navigation
```
SplashActivity → AuthActivity (if not logged in)
              → MainActivity (if logged in)
                 ├→ TaskDetailActivity
                 └→ WebViewActivity
```

## 🔄 Background Services

### Foreground Service
- **BrowserTaskService** - Continuous task synchronization
- Runs in foreground with persistent notification
- Updates tasks every 60 seconds

### WorkManager
- **TaskSyncWorker** - Periodic sync (every 15 min)
- **CleanupWorker** - Delete old tasks (daily)
- Survives app kills and reboots

## 🐛 Error Handling

### Retry Policy
- Exponential backoff for network errors
- Maximum 3 retry attempts
- Configurable delays and factors

### Offline Support
- All data cached locally in Room database
- Automatic sync when connection restored
- Optimistic UI updates

### User Feedback
- Material Snackbar for errors
- Progress indicators for loading states
- Empty states for no data

## 📊 Performance

### Optimization
- RecyclerView with DiffUtil for efficient updates
- Coil for optimized image loading
- R8 shrinking and obfuscation
- ProGuard rules for library optimization

### Monitoring
- Timber logging (debug builds only)
- Crash reporting integration ready
- Performance monitoring ready

## 🌍 Localization

Currently supports:
- English (default)

To add new languages:
1. Create `values-{lang}/strings.xml`
2. Translate all strings
3. Test with language setting

## 🔧 Configuration

### Build Configuration

Edit `gradle.properties`:
```properties
VERSION_CODE=1
VERSION_NAME=1.0.0
```

### API Configuration

Edit `local.properties`:
```properties
API_BASE_URL=https://your-api.com/
```

### ProGuard Rules

Custom rules in `app/proguard-rules.pro`:
- Retrofit rules
- Room rules
- Model class preservation

## 📝 Code Style

### Kotlin Style Guide
- Official Kotlin coding conventions
- 4-space indentation
- Maximum line length: 120 characters

### Architecture Guidelines
- Single Responsibility Principle
- Dependency Injection
- Repository pattern
- MVVM architecture

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Email: support@cometbrowser.com

## 🗺️ Roadmap

### v1.1
- [ ] Dark theme support
- [ ] Biometric authentication
- [ ] Push notifications
- [ ] Export task history

### v1.2
- [ ] Custom actions builder
- [ ] Scheduled tasks
- [ ] Task templates
- [ ] Analytics dashboard

### v2.0
- [ ] Jetpack Compose migration
- [ ] Multi-account support
- [ ] Cloud backup
- [ ] Widget support

## 📸 Screenshots

<div align="center">
  <img src="screenshots/auth.png" width="250" alt="Auth Screen"/>
  <img src="screenshots/main.png" width="250" alt="Main Screen"/>
  <img src="screenshots/detail.png" width="250" alt="Detail Screen"/>
</div>

## 🏆 Acknowledgments

- Material Design team for the amazing design system
- Android team for excellent development tools
- Open source community for invaluable libraries

---

<div align="center">
  Made with ❤️ for the Comet Browser community
</div>
