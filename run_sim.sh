#!/bin/zsh
SIM_ID="655A1E24-AA8F-4200-B59F-02BCAC38999D"
xcrun simctl boot $SIM_ID || true
xcrun simctl bootstatus $SIM_ID || true
APP_BUNDLE=$(find ~/Library/Developer/Xcode/DerivedData/Seizcare-*/Build/Products/Debug-iphonesimulator -name "Seizcare.app" | head -n 1)
echo "Installing $APP_BUNDLE"
xcrun simctl install $SIM_ID "$APP_BUNDLE"
echo "Launching app..."
xcrun simctl launch --console $SIM_ID com.chitkarauniversity.seizcare.2 > simulator_logs.txt 2>&1 &
PID=$!
sleep 10
kill $PID
cat simulator_logs.txt | grep -E "🧪|❌|🚨|✅"
