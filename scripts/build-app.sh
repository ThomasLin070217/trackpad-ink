#!/bin/zsh
set -euo pipefail

cd "${0:A:h:h}"
swift build --product TrackpadInkBridge
bin_dir="$(swift build --show-bin-path)"
app_path="${PWD}/dist/Trackpad Ink.app"
rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS"
ditto "$bin_dir/TrackpadInkBridge" "$app_path/Contents/MacOS/TrackpadInkBridge"
ditto "$bin_dir/OpenMultitouchSupportXCF.framework" "$app_path/Contents/MacOS/OpenMultitouchSupportXCF.framework"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>io.github.thomaslin.trackpadink.bridge</string>
<key>CFBundleName</key><string>Trackpad Ink</string>
<key>CFBundleDisplayName</key><string>Trackpad Ink</string>
<key>CFBundleExecutable</key><string>TrackpadInkBridge</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$app_path"
echo "$app_path"
