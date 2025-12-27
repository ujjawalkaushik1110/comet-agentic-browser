#!/bin/bash

##############################################################################
# Comet Browser Android - Complete Build Script
# 
# This script builds both debug and release APKs for the Android app.
# Requires: Android SDK with build tools 34.0.0+
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build configuration
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$BUILD_DIR/build-outputs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="$OUTPUT_DIR/build_${TIMESTAMP}.log"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                  ║${NC}"
echo -e "${BLUE}║   📱 COMET BROWSER - ANDROID BUILD SCRIPT                       ║${NC}"
echo -e "${BLUE}║                                                                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
print_section "Checking Prerequisites"

# Check Java
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    print_success "Java found: $JAVA_VERSION"
else
    print_error "Java not found. Please install JDK 17 or later."
    exit 1
fi

# Check Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    print_warning "ANDROID_HOME not set. Checking common locations..."
    
    # Check common locations
    if [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
        print_success "Found Android SDK at: $ANDROID_HOME"
    elif [ -d "/usr/local/android-sdk" ]; then
        export ANDROID_HOME="/usr/local/android-sdk"
        print_success "Found Android SDK at: $ANDROID_HOME"
    else
        print_error "Android SDK not found. Please install Android SDK and set ANDROID_HOME."
        echo ""
        echo "Download from: https://developer.android.com/studio"
        echo "Or use Android Studio SDK Manager to install."
        exit 1
    fi
fi

print_success "Android SDK: $ANDROID_HOME"

# Check keystore
if [ ! -f "keystore.properties" ]; then
    print_warning "keystore.properties not found. Creating from template..."
    cp keystore.properties.template keystore.properties
    print_info "Please edit keystore.properties with your signing details."
fi

if [ ! -f "comet-browser-release.jks" ]; then
    print_warning "Release keystore not found. You'll need to generate one for release builds."
    print_info "Run: keytool -genkey -v -keystore comet-browser-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias comet-browser"
fi

# Check local.properties
if [ ! -f "local.properties" ]; then
    print_warning "local.properties not found. Creating from template..."
    cp local.properties.template local.properties
    
    if [ -n "$ANDROID_HOME" ]; then
        echo "sdk.dir=$ANDROID_HOME" >> local.properties
        print_success "Added SDK location to local.properties"
    fi
fi

# Clean previous builds
print_section "Cleaning Previous Builds"
./gradlew clean --no-daemon
print_success "Clean completed"

# Build Debug APK
print_section "Building Debug APK (Production Flavor)"
print_info "Building app-production-debug.apk..."

if ./gradlew assembleProductionDebug --no-daemon | tee -a "$BUILD_LOG"; then
    DEBUG_APK="app/build/outputs/apk/production/debug/app-production-debug.apk"
    
    if [ -f "$DEBUG_APK" ]; then
        # Copy to output directory
        cp "$DEBUG_APK" "$OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk"
        
        # Get APK info
        APK_SIZE=$(du -h "$DEBUG_APK" | cut -f1)
        print_success "Debug APK built successfully!"
        print_info "Location: $DEBUG_APK"
        print_info "Size: $APK_SIZE"
        print_info "Package: com.comet.browser.debug"
        print_info "Copied to: $OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk"
    else
        print_error "Debug APK not found at expected location"
        exit 1
    fi
else
    print_error "Debug build failed! Check log at: $BUILD_LOG"
    exit 1
fi

# Build Release APK
print_section "Building Release APK (Production Flavor)"
print_info "Building app-production-release.apk..."

if ./gradlew assembleProductionRelease --no-daemon | tee -a "$BUILD_LOG"; then
    RELEASE_APK="app/build/outputs/apk/production/release/app-production-release.apk"
    
    if [ -f "$RELEASE_APK" ]; then
        # Copy to output directory
        cp "$RELEASE_APK" "$OUTPUT_DIR/comet-browser-release-${TIMESTAMP}.apk"
        
        # Get APK info
        APK_SIZE=$(du -h "$RELEASE_APK" | cut -f1)
        print_success "Release APK built successfully!"
        print_info "Location: $RELEASE_APK"
        print_info "Size: $APK_SIZE"
        print_info "Package: com.comet.browser"
        print_info "Signed: $([ -f "keystore.properties" ] && echo "Yes" || echo "No")"
        print_info "Copied to: $OUTPUT_DIR/comet-browser-release-${TIMESTAMP}.apk"
        
        # Verify signature
        if command -v jarsigner &> /dev/null; then
            print_info "Verifying APK signature..."
            if jarsigner -verify -verbose -certs "$RELEASE_APK" &> /dev/null; then
                print_success "APK signature verified!"
            else
                print_warning "APK signature verification failed or APK is unsigned"
            fi
        fi
    else
        print_error "Release APK not found at expected location"
        exit 1
    fi
else
    print_error "Release build failed! Check log at: $BUILD_LOG"
    exit 1
fi

# Build App Bundle (for Google Play)
print_section "Building App Bundle (for Google Play)"
print_info "Building app-production-release.aab..."

if ./gradlew bundleProductionRelease --no-daemon | tee -a "$BUILD_LOG"; then
    BUNDLE_FILE="app/build/outputs/bundle/productionRelease/app-production-release.aab"
    
    if [ -f "$BUNDLE_FILE" ]; then
        # Copy to output directory
        cp "$BUNDLE_FILE" "$OUTPUT_DIR/comet-browser-bundle-${TIMESTAMP}.aab"
        
        # Get bundle info
        BUNDLE_SIZE=$(du -h "$BUNDLE_FILE" | cut -f1)
        print_success "App Bundle built successfully!"
        print_info "Location: $BUNDLE_FILE"
        print_info "Size: $BUNDLE_SIZE"
        print_info "Copied to: $OUTPUT_DIR/comet-browser-bundle-${TIMESTAMP}.aab"
    else
        print_warning "App Bundle not found at expected location"
    fi
else
    print_warning "App Bundle build failed"
fi

# Generate Build Report
print_section "Generating Build Report"

cat > "$OUTPUT_DIR/BUILD_REPORT_${TIMESTAMP}.md" << EOF
# Comet Browser - Android Build Report

**Build Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Build Environment:** $(uname -a)
**Java Version:** $JAVA_VERSION
**Gradle Version:** $(./gradlew --version | grep "Gradle" | head -n1)
**Android SDK:** $ANDROID_HOME

---

## Build Artifacts

### Debug APK
- **File:** comet-browser-debug-${TIMESTAMP}.apk
- **Package:** com.comet.browser.debug
- **Size:** $([ -f "$OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk" ] && du -h "$OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk" | cut -f1 || echo "N/A")
- **Debuggable:** Yes
- **ProGuard:** No

### Release APK
- **File:** comet-browser-release-${TIMESTAMP}.apk
- **Package:** com.comet.browser
- **Size:** $([ -f "$OUTPUT_DIR/comet-browser-release-${TIMESTAMP}.apk" ] && du -h "$OUTPUT_DIR/comet-browser-release-${TIMESTAMP}.apk" | cut -f1 || echo "N/A")
- **Debuggable:** No
- **ProGuard:** Yes
- **Signed:** $([ -f "keystore.properties" ] && echo "Yes" || echo "No")

### App Bundle (Google Play)
- **File:** comet-browser-bundle-${TIMESTAMP}.aab
- **Package:** com.comet.browser
- **Size:** $([ -f "$OUTPUT_DIR/comet-browser-bundle-${TIMESTAMP}.aab" ] && du -h "$OUTPUT_DIR/comet-browser-bundle-${TIMESTAMP}.aab" | cut -f1 || echo "N/A")
- **Format:** Android App Bundle

---

## Installation Instructions

### Debug APK
\`\`\`bash
adb install -r $OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk
\`\`\`

### Release APK
\`\`\`bash
adb install -r $OUTPUT_DIR/comet-browser-release-${TIMESTAMP}.apk
\`\`\`

---

## Testing Checklist

- [ ] Install debug APK on physical device
- [ ] Test authentication flow
- [ ] Test browse task creation
- [ ] Test offline mode
- [ ] Test background sync
- [ ] Verify ProGuard doesn't break release build
- [ ] Test on Android 8.0 (minSdk 26)
- [ ] Test on Android 14 (targetSdk 34)

---

## Google Play Submission

1. Upload \`comet-browser-bundle-${TIMESTAMP}.aab\` to Play Console
2. Fill in release notes
3. Submit for review
4. Monitor crash reports and ANRs

---

## Build Log

Full build log available at: \`$(basename "$BUILD_LOG")\`

EOF

print_success "Build report generated: $OUTPUT_DIR/BUILD_REPORT_${TIMESTAMP}.md"

# Summary
print_section "Build Summary"

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                  ║${NC}"
echo -e "${GREEN}║   ✅ BUILD COMPLETED SUCCESSFULLY!                              ║${NC}"
echo -e "${GREEN}║                                                                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${BLUE}📦 Build Artifacts:${NC}"
echo -e "   Debug APK:   $OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk"
echo -e "   Release APK: $OUTPUT_DIR/comet-browser-release-${TIMESTAMP}.apk"
echo -e "   App Bundle:  $OUTPUT_DIR/comet-browser-bundle-${TIMESTAMP}.aab"
echo ""
echo -e "${BLUE}📄 Build Report: $OUTPUT_DIR/BUILD_REPORT_${TIMESTAMP}.md${NC}"
echo -e "${BLUE}📝 Build Log:    $BUILD_LOG${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Test debug APK: adb install -r $OUTPUT_DIR/comet-browser-debug-${TIMESTAMP}.apk"
echo -e "  2. Test release APK on multiple devices"
echo -e "  3. Submit app bundle to Google Play Console"
echo ""
