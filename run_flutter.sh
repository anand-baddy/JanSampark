#!/bin/bash
flutter clean
flutter pub get
flutter build apk --release
version=$(date '+%Y%m%d--%H%M')
mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/JanSamparkTab-v$version.apk
echo "APK renamed to JanSamparkTab-v$version.apk"
mv build/app/outputs/flutter-apk/JanSamparkTab-v$version.apk ~/op2lnx/janSampark_apk/
