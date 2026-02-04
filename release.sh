#!/bin/bash

# DeskModes Release Script
# Usage: ./release.sh 1.0.1 2 "Release notes here"

VERSION=$1
BUILD=$2
NOTES=${3:-"Bug fixes and improvements"}

if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "Usage: ./release.sh <version> <build> [release_notes]"
    echo "Example: ./release.sh 1.0.1 2 \"Fixed crash on startup\""
    exit 1
fi

TEAM_ID="ZC8MCRVRBP"
SIGNING_IDENTITY="Developer ID Application: Arturo García Jurado ($TEAM_ID)"
REPO="arturogj92/DeskModes"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Building DeskModes v$VERSION (build $BUILD)..."

# Build
cd "$SCRIPT_DIR/deskmodes-app"
xcodebuild -project DeskModes.xcodeproj \
    -scheme DeskModes \
    -configuration Release \
    MARKETING_VERSION=$VERSION \
    CURRENT_PROJECT_VERSION=$BUILD \
    DEVELOPMENT_TEAM=$TEAM_ID \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    clean build 2>&1 | tail -20

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/DeskModes-*/Build/Products/Release/DeskModes.app -maxdepth 0 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app"
    exit 1
fi

echo "✅ Build successful"

# Create DMG
cd "$SCRIPT_DIR"
DMG_NAME="DeskModes-$VERSION.dmg"
rm -f "$DMG_NAME"

echo "📦 Creating $DMG_NAME..."
hdiutil create -volname "DeskModes" \
    -srcfolder "$APP_PATH" \
    -ov -format UDZO "$DMG_NAME" 2>&1 | tail -5

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ DMG creation failed"
    exit 1
fi

echo "✅ DMG created"

# Sign the DMG
echo "🔐 Signing DMG..."
codesign --force --sign "$SIGNING_IDENTITY" "$DMG_NAME"

# Notarize
echo "📤 Notarizing (this takes 2-5 minutes)..."
xcrun notarytool submit "$DMG_NAME" \
    --keychain-profile "notarization" \
    --wait 2>&1 | tail -10

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Notarization failed"
    exit 1
fi

echo "✅ Notarized"

# Staple
xcrun stapler staple "$DMG_NAME" 2>/dev/null

# Sparkle signature
echo "🔐 Signing for Sparkle..."
SPARKLE_SIG=$(~/bin/sign_update "$DMG_NAME" 2>&1)
ED_SIGNATURE=$(echo "$SPARKLE_SIG" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="//;s/"$//')
if [ -z "$ED_SIGNATURE" ]; then
    ED_SIGNATURE=$(echo "$SPARKLE_SIG" | tail -1)
fi

DMG_SIZE=$(stat -f%z "$DMG_NAME")
PUB_DATE=$(date -R)

echo "✅ Sparkle signed"

# Update appcast.xml automatically
echo "📝 Updating appcast.xml..."

APPCAST_FILE="$SCRIPT_DIR/appcast.xml"

# Create the new item
NEW_ITEM="        <item>
            <title>Version $VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$BUILD</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <description>
                <![CDATA[
                    <h2>What's New</h2>
                    <ul>
                        <li>$NOTES</li>
                    </ul>
                ]]>
            </description>
            <enclosure
                url=\"https://github.com/$REPO/releases/download/v$VERSION/$DMG_NAME\"
                sparkle:edSignature=\"$ED_SIGNATURE\"
                length=\"$DMG_SIZE\"
                type=\"application/octet-stream\"/>
        </item>"

# Insert after <language>en</language>
if grep -q "<language>en</language>" "$APPCAST_FILE"; then
    # Create temp file with new item inserted
    awk -v new_item="$NEW_ITEM" '
    /<language>en<\/language>/ {
        print
        print ""
        print new_item
        next
    }
    { print }
    ' "$APPCAST_FILE" > "${APPCAST_FILE}.tmp"
    mv "${APPCAST_FILE}.tmp" "$APPCAST_FILE"
    echo "✅ appcast.xml updated"
else
    echo "⚠️  Could not find insertion point in appcast.xml"
    echo "    Please add manually"
fi

# Create GitHub release
echo ""
echo "📤 Creating GitHub release..."
gh release create "v$VERSION" "$DMG_NAME" \
    --repo "$REPO" \
    --title "DeskModes v$VERSION" \
    --notes "$NOTES"

if [ $? -eq 0 ]; then
    echo "✅ GitHub release created"

    # Commit and push appcast
    echo "📤 Pushing appcast.xml..."
    cd "$SCRIPT_DIR"
    git add appcast.xml
    git commit -m "Release v$VERSION"
    git push

    echo ""
    echo "=========================================="
    echo "🎉 RELEASE v$VERSION COMPLETE!"
    echo "=========================================="
    echo ""
    echo "✅ App built and signed"
    echo "✅ DMG notarized"
    echo "✅ GitHub release: https://github.com/$REPO/releases/tag/v$VERSION"
    echo "✅ appcast.xml updated and pushed"
    echo ""
    echo "Users will now see the update!"
else
    echo "❌ GitHub release failed"
    echo ""
    echo "Create manually at: https://github.com/$REPO/releases/new"
    echo "Tag: v$VERSION"
    echo "Upload: $DMG_NAME"
fi
