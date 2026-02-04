# DeskModes Release Guide

## Prerequisites

1. **Install Sparkle tools** (one-time):
   ```bash
   # Clone Sparkle and build tools
   git clone https://github.com/sparkle-project/Sparkle.git /tmp/sparkle-tools
   cd /tmp/sparkle-tools && make

   # Or download pre-built from:
   # https://github.com/sparkle-project/Sparkle/releases
   # Extract and find generate_keys and sign_update in bin/
   ```

2. **Generate signing keys** (one-time):
   ```bash
   # Generate EdDSA key pair
   ./generate_keys

   # This outputs:
   # - Private key: save this securely (DO NOT COMMIT)
   # - Public key: add to Info.plist as SUPublicEDKey
   ```

## Creating a Release

### 1. Build the app
```bash
cd deskmodes-app
xcodebuild -project DeskModes.xcodeproj -scheme DeskModes -configuration Release archive -archivePath build/DeskModes.xcarchive
```

### 2. Export the app
```bash
xcodebuild -exportArchive -archivePath build/DeskModes.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions.plist
```

Or manually: Open .xcarchive > "Distribute App" > "Copy App"

### 3. Create DMG
```bash
# Create DMG with the app
hdiutil create -volname "DeskModes" -srcfolder build/DeskModes.app -ov -format UDZO DeskModes.dmg
```

### 4. Sign the DMG
```bash
# Sign with your private key
./sign_update DeskModes.dmg

# This outputs the edSignature - copy it
```

### 5. Get file size
```bash
ls -l DeskModes.dmg
# Note the size in bytes for the appcast
```

### 6. Update appcast.xml
Add a new `<item>` at the top with:
- New version number
- pubDate (RFC 2822 format)
- sparkle:version (build number)
- sparkle:shortVersionString (display version)
- description (release notes in HTML)
- enclosure url (GitHub release download URL)
- sparkle:edSignature (from step 4)
- length (file size from step 5)

### 7. Create GitHub Release
1. Go to https://github.com/arturogj92/DeskModes/releases
2. Click "Draft a new release"
3. Tag: v1.0.1 (or appropriate version)
4. Upload the DMG
5. Publish

### 8. Commit and push appcast.xml
```bash
git add appcast.xml
git commit -m "Release v1.0.1"
git push
```

## Quick Release Script

```bash
#!/bin/bash
VERSION=$1  # e.g., 1.0.1
BUILD=$2    # e.g., 2

# Build
xcodebuild -project deskmodes-app/DeskModes.xcodeproj \
  -scheme DeskModes \
  -configuration Release \
  MARKETING_VERSION=$VERSION \
  CURRENT_PROJECT_VERSION=$BUILD \
  clean build

# Create DMG
hdiutil create -volname "DeskModes" \
  -srcfolder ~/Library/Developer/Xcode/DerivedData/DeskModes-*/Build/Products/Release/DeskModes.app \
  -ov -format UDZO DeskModes-$VERSION.dmg

# Sign
./sign_update DeskModes-$VERSION.dmg

echo "Now upload DeskModes-$VERSION.dmg to GitHub releases and update appcast.xml"
```

## Version Numbers

- **MARKETING_VERSION** (CFBundleShortVersionString): User-facing version like "1.0.1"
- **CURRENT_PROJECT_VERSION** (CFBundleVersion): Build number, increment each release

## Testing Updates

1. Build an older version (e.g., 0.9.0)
2. Run it
3. It should find the newer version in appcast.xml and offer to update
