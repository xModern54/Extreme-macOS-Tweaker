<p align="center">
  <img src="docs/app-icon.png" width="168" alt="Extreme macOS Tweaker">
</p>

<h1 align="center">Extreme macOS Tweaker</h1>

<p align="center">
  Turn off the parts of macOS you don't use.
</p>

<p align="center">
  <img alt="macOS 15+" src="https://img.shields.io/badge/macOS-15%2B-7B5EA7?style=flat-square">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5-8B6FBF?style=flat-square">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-9B7ED0?style=flat-square">
</p>

macOS runs a lot of background services for features most people never touch: Siri, Spotlight, iCloud, Photos analysis, telemetry, Continuity, and more. They sit in RAM anyway.

Extreme macOS Tweaker lets you disable that unused layer, remove system apps Apple won't let you delete, and drop large unused system files. Fewer processes, less memory, more free disk.

Native SwiftUI app. You pick the changes, review them, enter the administrator password once.

## Features

**System Tweaker.** Categories of macOS features. Each toggle turns off the related background services. Spotlight, Siri, Apple Intelligence, iCloud helpers, telemetry: if you don't use it, it stops running.

**System Apps.** Disable or delete apps from `/System/Applications` (Mail, Maps, Stocks, and the rest). Finder can't do this. The app rewrites the sealed system volume and creates a new boot snapshot.

**System Debloat.** Removes unused heavy system data: Apple Intelligence models, Siri offline packs, translation, dictation, simulator runtimes. Frees disk space.

**Security.** Toggle Gatekeeper, XProtect, and system policy from one screen.

## Requirements

- macOS 15 or newer, Apple Silicon or Intel
- Administrator password to apply changes
- SIP off for system daemons, debloat, and system apps
- Authenticated Root off to edit the system volume

This is a power-user tool. It changes the running system.
