#!/bin/zsh
# ~/Applications/IMEシークレット.app をビルドして入れ直す
set -eu
cd "${0:A:h}"
APP=~/Applications/IMEシークレット.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O main.swift -o "$APP/Contents/MacOS/ime-secret"
cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>ime-secret</string>
	<key>CFBundleIdentifier</key><string>io.github.poporpepopo.ime-secret</string>
	<key>CFBundleName</key><string>IMEシークレット</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>LSUIElement</key><true/>
</dict>
</plist>
EOF
codesign --force -s - "$APP"
echo "built: $APP"
