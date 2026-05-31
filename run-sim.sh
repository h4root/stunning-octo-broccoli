#!/bin/bash
# Сборка и запуск CalorieApp в симуляторе — без Xcode UI.
# Использование:  ./run-sim.sh            (по умолчанию iPhone 17)
#                 ./run-sim.sh "iPhone Air"
set -e

SIM="${1:-iPhone 17}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd "$(dirname "$0")"

echo "🔨 Сборка для «$SIM»…"
xcodebuild -project CalorieApp.xcodeproj -scheme CalorieApp \
  -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath build -configuration Debug build \
  -quiet

APP="build/Build/Products/Debug-iphonesimulator/CalorieApp.app"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist")

echo "📲 Запуск $BUNDLE_ID на «$SIM»…"
xcrun simctl boot "$SIM" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || true
xcrun simctl install booted "$APP"
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch booted "$BUNDLE_ID"
echo "✅ Готово."
