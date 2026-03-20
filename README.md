# Hyundai Bluelink AU — Flutter App

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/gjwgit/konapod)
[![GitHub License](https://img.shields.io/github/license/gjwgit/konapod)](https://raw.githubusercontent.com/gjwgit/konapod/dev/LICENSE)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/gjwgit/konapod/master/pubspec.yaml&query=$.version&label=version)](https://github.com/gjwgit/konapod/blob/dev/CHANGELOG.md)
[![Last Updated](https://img.shields.io/github/last-commit/gjwgit/konapod?label=last%20updated)](https://github.com/gjwgit/konapod/commits/dev/)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/gjwgit/konapod/dev)](https://github.com/gjwgit/rattle/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/gjwgit/konapod)](https://github.com/gjwgit/konapod/issues)

KonaPod is a tool to collect your Hyundai vehicle data together in one
secure and private place. You can selectively share any parts of your
data with others. The app itself presents the data and analyses of the
data. It is being developed by [Togaware](https://togaware.com) and
pair programmed by [Graham
Williams](https://togaware.com/Graham.Williams.html) and [Claude
Code](https://claude.com/product/claude-code).

If you appreciate the app then please show some ❤️ and star the GitHub
Repository to support the project.

The latest version of the app can be run online at
[konapod.solidcommunity.au](https://konapod.solidcommunity.au) with no
installation required though requiring a Bluelink login, or downloaded
and installed for your platform from the [Solid Community
AU](https://solidcommunity.au) repository:

<!-- markdownlint-disable MD036 -->
+ **Web**
  [solidcommunity](https://konapod.solidcommunity.au/);
+ **Android**
  [aab](https://solidcommunity.au/installers/konapod.aab) or
  [apk](https://solidcommunity.au/installers/konapod.apk);
+ **GNU/Linux**
  [deb](https://solidcommunity.au/installers/konapod_amd64.deb) or
  [snap](https://solidcommunity.au/installers/konapod_amd64.snap) or
  [zip](https://solidcommunity.au/installers/konapod-linux.zip);
+ **macOS**
  [dmg](https://solidcommunity.au/installers/konapod-macos.dmg) or
  [zip](https://solidcommunity.au/installers/konapod-macos.zip);
+ **Windows**
  [inno](https://solidcommunity.au/installers/konapod-windows-inno.exe) or
  [zip](https://solidcommunity.au/installers/konapod-windows.zip).

Installation details are available for all platforms from
[github](https://github.com/gjwgit/konapod/blob/dev/installers/README.md).

Contributions are welcome. Visit
[github](https://github.com/gjwgit/konapod) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request. The app is implemented in
[Flutter](https://flutter.dev) using
[solidui](https://pub.dev/packages/solidui). Thanks.

## Introduction

A Flutter app to view your Hyundai Bluelink vehicle data (currently
for Australia / NZ but please send in PRs for other regions).

---

## Features

+ **Login** with your Bluelink email, password & PIN
+ **Auto login** on relaunch — no need to re-enter Bluelink credentials
+ **Demo mode** — test the UI without real credentials
+ **Dashboard** showing:
  + Vehicle nickname, model, year, colour & fuel type badge
  + Lock status, engine status, charging status
  + Battery level + range bar (EV/PHEV)
  + Fuel level + range bar (ICE/HEV)
  + Door, bonnet & boot open/close
  + Defrost status
  + Tyre pressure (all 4 corners, in kPa)
  + External temperature
  + Odometer reading
  + GPS coordinates
  + Full VIN & vehicle details
  + Last updated timestamp
+ **Pull-to-refresh** and refresh button
+ **Sign out**


---

## Showcase

Login Screen

![Login Screen](./assets/screenshots/login.png)

Changelog Screen

![Change Log](./assets/screenshots/changelog.png)

Status Page

![Status Page](./assets/screenshots/status.png)

Energy Page

![Energy Page](./assets/screenshots/energy.png)

Visuals Page

![Visuals Page](./assets/screenshots/visuals.png)

History Page

![History Page](./assets/screenshots/history.png)

---

## Setup to Build

### Prerequisites

+ Flutter 3.x+ installed
+ `flutter doctor` passing for your target platform

### Install

```bash
git clone git@github.com:gjwgit/konapod.git
cd konapod
flutter pub get
flutter run
```

---

## ⚠️ Important Notes

### Unofficial API

The Bluelink Australia API is **not officially published** by Hyundai.
This app uses endpoints reverse-engineered by the community:

+ [hyundai_kia_connect_api](https://github.com/Hyundai-Kia-Connect/hyundai_kia_connect_api)
+ [blog.kumo.dev — Reverse engineering Bluelink](https://blog.kumo.dev/2024/05/22/reverse_engineering_hkg_apps.html)

## Stamp Mechanism

Hyundai's AU API requires a rotating "stamp" header.
This app fetches stamps from the community stamp server:
`https://raw.githubusercontent.com/neoPix/bluelinky-stamps/master/hyundai-{appId}.v2.json`

If the stamp server is unavailable, some API calls may fail.

## Rate Limits

Avoid refreshing too frequently — over-polling can drain your car's 12V battery.
The app uses **cached status** (latest known state) by default, which is safe.
Force-refresh directly queries the car's modem.

## Android Network Config

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

## iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
