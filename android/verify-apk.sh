#!/bin/bash

##############################################################################
# APK Verification and Information Tool
# 
# This script provides detailed information about built APKs
##############################################################################

APK_FILE="$1"

if [ -z "$APK_FILE" ]; then
    echo "Usage: $0 <path-to-apk>"
    echo ""
    echo "Example: $0 app/build/outputs/apk/production/release/app-production-release.apk"
    exit 1
fi

if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                                                                  ║"
echo "║   📱 APK INFORMATION & VERIFICATION                             ║"
echo "║                                                                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# File info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FILE INFORMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "File: $(basename "$APK_FILE")"
echo "Path: $APK_FILE"
echo "Size: $(du -h "$APK_FILE" | cut -f1)"
echo "Modified: $(date -r "$APK_FILE" '+%Y-%m-%d %H:%M:%S')"
echo ""

# APK details (if aapt is available)
if command -v aapt &> /dev/null; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  APK DETAILS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Extract package info
    PACKAGE=$(aapt dump badging "$APK_FILE" | grep "package:" | sed "s/.*name='\([^']*\)'.*/\1/")
    VERSION_CODE=$(aapt dump badging "$APK_FILE" | grep "versionCode=" | sed "s/.*versionCode='\([^']*\)'.*/\1/")
    VERSION_NAME=$(aapt dump badging "$APK_FILE" | grep "versionName=" | sed "s/.*versionName='\([^']*\)'.*/\1/")
    MIN_SDK=$(aapt dump badging "$APK_FILE" | grep "sdkVersion:" | sed "s/.*'\([^']*\)'.*/\1/")
    TARGET_SDK=$(aapt dump badging "$APK_FILE" | grep "targetSdkVersion:" | sed "s/.*'\([^']*\)'.*/\1/")
    
    echo "Package:        $PACKAGE"
    echo "Version Code:   $VERSION_CODE"
    echo "Version Name:   $VERSION_NAME"
    echo "Min SDK:        $MIN_SDK (Android $([ "$MIN_SDK" = "26" ] && echo "8.0" || echo "$MIN_SDK"))"
    echo "Target SDK:     $TARGET_SDK (Android $([ "$TARGET_SDK" = "34" ] && echo "14" || echo "$TARGET_SDK"))"
    echo ""
    
    # Permissions
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PERMISSIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    aapt dump permissions "$APK_FILE"
    echo ""
else
    echo "⚠️  aapt not found. Install Android SDK build tools for detailed APK analysis."
    echo ""
fi

# Signature verification (if jarsigner is available)
if command -v jarsigner &> /dev/null; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SIGNATURE VERIFICATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if jarsigner -verify -verbose -certs "$APK_FILE" 2>&1 | grep -q "jar verified"; then
        echo "✅ APK is properly signed"
        echo ""
        echo "Certificate details:"
        jarsigner -verify -verbose -certs "$APK_FILE" 2>&1 | grep -A 10 "X.509"
    else
        echo "⚠️  APK signature verification failed or APK is unsigned"
    fi
    echo ""
else
    echo "⚠️  jarsigner not found. Install JDK for signature verification."
    echo ""
fi

# APK structure (using unzip)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  APK STRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
unzip -l "$APK_FILE" | head -20
echo "..."
echo "Total files: $(unzip -l "$APK_FILE" | tail -1 | awk '{print $2}')"
echo ""

# Installation command
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  INSTALLATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To install this APK on a connected device:"
echo ""
echo "  adb install -r \"$APK_FILE\""
echo ""
echo "To uninstall (if needed):"
echo ""
if command -v aapt &> /dev/null; then
    echo "  adb uninstall $PACKAGE"
else
    echo "  adb uninstall <package-name>"
fi
echo ""
