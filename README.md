# Modulabs

**Modulabs** is a Flutter mobile app to monitor and manage your Modulabs
self-hosted server straight from your phone — module status, live system
telemetry (CPU, RAM, storage) and real-time alerts, wherever you are.

Learn more about Modulabs itself here:
https://github.com/NOKIMIMO/homelab-project

## Features

- **Dashboard** — an at-a-glance overview of your server: how many modules are
  running and live system telemetry (CPU, RAM and storage usage), auto-refreshed
  every few seconds.
- **Modules** — browse every module on your server and start/stop it with a
  single tap, including its custom (SVG or raster) icon.
- **Events** — a scrollable history of the alerts your server has raised.
- **Real-time alerts** — get a phone notification the moment your server fires an
  alert. Delivery runs in a background service, so it keeps working even when the
  app is closed and when you're away from your home network.
- **Admin** — for administrators (or any account with `ADMIN_ACCESS`): approve
  new accounts, moderate password-reset requests, assign roles, and access system
  controls — all from your phone.
- **Secure sessions** — log in against your own server; the JWT session token is
  stored in the Android Keystore, and the app enforces forced password changes
  when the server requires one.

## How it works

The app is a thin client for your Modulabs backend. On first launch you enter
your server's URL, then sign in. From there:

1. **Connect** — point the app at your Modulabs server URL (saved across
   restarts).
2. **Sign in** — authenticate with your Modulabs account; the session is kept
   securely on-device.
3. **Monitor & manage** — the app talks to the Modulabs REST API for modules and
   telemetry, and subscribes to the alert stream for notifications.

> The app is **admin-oriented**: a valid session needs admin access, and it is
> re-checked on every launch, so revoked access signs you out automatically.

## Requirements

- An accessible **Modulabs backend** (see the main project above). To receive
  alerts while away from home, the backend must be reachable from outside your
  local network.
- **Android** device (built and packaged as `app-modulabs.apk`).

## Tech stack

- **Flutter / Dart** (Material design)
- `http` — REST calls to the Modulabs API
- `flutter_secure_storage` — JWT stored in the platform keystore
- `shared_preferences` — remembers the server URL
- `flutter_foreground_task` + `flutter_local_notifications` — background alert
  delivery and notifications
- `flutter_svg` — renders module icons served without a file extension

## Build & run

```bash
flutter pub get
flutter run                 # run on a connected device/emulator
flutter build apk --release # produce a release APK
