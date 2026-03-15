# Hyundai Bluelink AU — Flutter App

A Flutter app to view your Hyundai Bluelink vehicle data (Australia / NZ).
Styled with official Hyundai brand colours (navy + sky blue).

---

## Features

- **Login** with your Bluelink email, password & PIN (saved securely via `flutter_secure_storage`)
- **Auto login** on relaunch — no need to re-enter credentials
- **Demo mode** — test the UI without real credentials
- **Dashboard** showing:
  - Vehicle nickname, model, year, colour & fuel type badge
  - Lock status, engine status, charging status
  - Battery level + range bar (EV/PHEV)
  - Fuel level + range bar (ICE/HEV)
  - Door, bonnet & boot open/close
  - Defrost status
  - Tyre pressure (all 4 corners, in kPa)
  - External temperature
  - Odometer reading
  - GPS coordinates
  - Full VIN & vehicle details
  - Last updated timestamp
- **Pull-to-refresh** and refresh button
- **Sign out**

---

## Setup

### Prerequisites

- Flutter 3.x+ installed
- `flutter doctor` passing for your target platform (iOS or Android)

### Install

```bash
cd bluelink_au
flutter pub get
flutter run
```

### Build release APK (Android)

```bash
flutter build apk --release
```

### Build for iOS

```bash
flutter build ios --release
```

---

## ⚠️ Important Notes

### Unofficial API

The Bluelink Australia API is **not officially published** by Hyundai.
This app uses endpoints reverse-engineered by the community:

- [hyundai_kia_connect_api](https://github.com/Hyundai-Kia-Connect/hyundai_kia_connect_api)
- [blog.kumo.dev — Reverse engineering Bluelink](https://blog.kumo.dev/2024/05/22/reverse_engineering_hkg_apps.html)

### Stamp Mechanism

Hyundai's AU API requires a rotating "stamp" header.
This app fetches stamps from the community stamp server:
`https://raw.githubusercontent.com/neoPix/bluelinky-stamps/master/hyundai-{appId}.v2.json`

If the stamp server is unavailable, some API calls may fail.

### Rate Limits

Avoid refreshing too frequently — over-polling can drain your car's 12V battery.
The app uses **cached status** (latest known state) by default, which is safe.
Force-refresh directly queries the car's modem.

### Android Network Config

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
android:usesCleartextTraffic="true"
android:networkSecurityConfig="@xml/network_security_config"
```

And create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">au-apigw.ccs.hyundai.com.au</domain>
    </domain-config>
</network-security-config>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
