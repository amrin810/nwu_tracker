# 🚌 University Bus Tracker

A real-time university transportation tracking mobile application built with **Flutter** for **North Western University**, Department of Computer Science & Engineering.

---

## 📋 Overview

University Bus Tracker helps students, drivers, conductors, and admins manage and monitor the university bus fleet in real time. It provides live GPS tracking, schedule management, pickup requests, distance calculation, and an intelligent **Bus Reachability Algorithm** that tells students if they can catch a bus in time.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🗺️ **Live Bus Tracking** | Real-time Google Maps view of bus positions |
| 📅 **Schedule Viewer** | Full departure/arrival schedule per bus & route |
| 📍 **Nearby Buses** | Find buses closest to your current GPS location |
| 🚏 **Pickup Request** | Request a pickup at a specific stop (student → conductor) |
| 📏 **Distance & Time** | Calculate distance and estimated travel time to a stop |
| ✅ **Reachability Check** | AI-rule-based algorithm: can you catch the bus in time? |
| 📞 **Conductor Contact** | Direct call/message to the bus conductor |
| 👤 **Role-based Access** | Student, Driver, Conductor, Admin roles with tailored UI |
| 🛠️ **Admin Dashboard** | Manage buses, routes, and pickup requests |

---

## 🏗️ Architecture

The project follows a **layered, feature-first architecture**:

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # Root widget (Providers + Theme + Router)
│
├── 📁 features/               # ── FRONTEND ──────────────────────────────
│   ├── splash/                # Splash/loading screen
│   ├── auth/                  # Login & Register pages
│   ├── main_shell/            # Bottom navigation shell
│   ├── home/                  # Home dashboard
│   ├── tracking/              # Live map tracking page
│   ├── schedule/              # Bus schedule page
│   ├── nearby/                # Nearby bus finder
│   ├── pickup/                # Pickup request page
│   ├── distance/              # Distance & time calculator
│   ├── reachability/          # Reachability algorithm page
│   ├── contact/               # Conductor contact page
│   ├── profile/               # User profile
│   └── admin/                 # Admin dashboard
│
├── 📁 widgets/                # Shared reusable UI components
│
├── 📁 providers/              # ── STATE LAYER ───────────────────────────
│   ├── auth_provider.dart     # Auth state (user, role, sign-in/out)
│   ├── bus_provider.dart      # Bus, route, schedule, pickup state
│   └── location_provider.dart # GPS, distance, reachability state
│
├── 📁 repositories/           # ── BACKEND INTERFACE ─────────────────────
│   ├── auth_repository.dart   # Firebase Auth + Cloud Firestore users
│   └── bus_repository.dart    # Cloud Firestore: buses, routes, schedules, requests
│
├── 📁 models/                 # Pure data models (JSON serializable)
│   ├── user_model.dart
│   ├── bus_model.dart
│   ├── bus_location_model.dart
│   ├── live_bus_location.dart
│   ├── route_model.dart
│   ├── stop_model.dart
│   ├── schedule_model.dart
│   ├── pickup_request_model.dart
│   └── reachability_model.dart
│
└── 📁 core/                   # ── CORE / BACKEND SERVICES ───────────────
    ├── constants/             # AppConstants, AppColors, AppStrings, NWUDefaultData
    ├── services/              # LocationService, MapService, ReachabilityService
    ├── theme/                 # AppTheme (Dark Navy Theme)
    ├── errors/
    └── utils/                 # AppLogger, Formatters
```

---

## 🧠 Reachability Algorithm

The core algorithmic feature of this project. Given a student's GPS position and a bus's expected arrival time at a stop:

```
Time Margin = Bus Arrival Time (min) - Student Walking Time (min)

Walking Speed = 5.0 km/h (configurable)
Safe Margin   = 3 minutes

Bus already passed stop  →  ❌ Bus Already Passed
Time Margin >= 3 min     →  ✅ Likely to Catch
Time Margin >= 0 min     →  ⚠️  Hurry – Bus is Nearby
Time Margin <  0 min     →  🔴 May Miss the Bus
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.13.4) |
| **State Management** | Provider ^6.1.5 |
| **Backend / Database** | Firebase (Cloud Firestore + Realtime Database) |
| **Authentication** | Firebase Auth (Email/Password + Google Sign-In) |
| **Maps & Tiles** | OpenStreetMap (flutter_map ^8.3.2 + OSRM Routing) |
| **GPS / Location** | Geolocator ^14.1.1 |
| **Date Formatting** | intl ^0.20.3 |
| **URL / Calls** | url_launcher ^6.3.2 |

---

## ⚙️ Setup & Running

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code with Flutter plugin
- Configured Firebase project (`nwu-bus-tracking`)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Application
```bash
flutter run
```

### 3. Build Release APK
```bash
flutter build apk --release --no-tree-shake-icons
```

---

## 🗄️ Cloud Firestore Collections & RTDB Nodes

| Resource | Service | Purpose |
|---|---|---|
| `users/{uid}` | Cloud Firestore | User profiles, roles, and campus IDs |
| `buses/{id}` | Cloud Firestore | Bus fleet inventory, capacity, and route assignments |
| `routes/{id}` | Cloud Firestore | Bus route definitions and stops |
| `schedules/{id}` | Cloud Firestore | Departure and arrival timetables |
| `pickup_requests/{id}` | Cloud Firestore | Student pickup requests and statuses |
| `bus_locations/{busId}` | Realtime Database | Real-time GPS coordinates, speed, and active status |

---

## 📡 Hardware GPS Tracker (ESP32-S3 + u-blox NEO-7N)

For continuous, automatic bus tracking without manual phone operation, an IoT hardware beacon built with **ESP32-S3 WROOM** and **u-blox NEO-7N GPS** streams live coordinates to Firebase Realtime Database (`bus_locations/{busId}`).

### Wiring / Connection Diagram

```
+------------------------------------+          +---------------------------+
|         u-blox NEO-7N GPS          |          |      ESP32-S3 WROOM       |
|                                    |          |                           |
|  [ VCC ] -------------------------->--------> |  3.3V (or 5V / VIN)       |
|  [ GND ] -------------------------->--------> |  GND                      |
|  [ TX  ] -------------------------->--------> |  GPIO 18 (GPS_RX_PIN)     |
|  [ RX  ] -------------------------->--------> |  GPIO 17 (GPS_TX_PIN)     |
+------------------------------------+          +---------------------------+
```

| NEO-7N GPS Pin | ESP32-S3 Pin | Function |
|---|---|---|
| **VCC** | **3.3V** (or 5V / VIN) | Module Power Supply |
| **GND** | **GND** | Common Ground |
| **TX** | **GPIO 18** | Transmits NMEA GPS data to ESP32 RX |
| **RX** | **GPIO 17** | Receives configuration from ESP32 TX |

Firmware source code, diagnostic tools, and step-by-step flashing instructions are in [`hardware/esp32_bus_tracker/`](hardware/esp32_bus_tracker/).

---

## 👥 User Roles

| Role | Access |
|---|---|
| **Student** | Track buses, view schedules, request pickups, check reachability |
| **Driver** | View assigned route & schedule |
| **Conductor** | Manage pickup requests, contact students |
| **Admin** | Full dashboard: manage buses, routes, requests |

---

## 📁 Key Files Quick Reference

| File | Purpose |
|---|---|
| [`lib/main.dart`](lib/main.dart) | App entry point & Firebase initialization |
| [`lib/app.dart`](lib/app.dart) | Root widget & provider setup |
| [`lib/routes/app_routes.dart`](lib/routes/app_routes.dart) | All named routes |
| [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart) | Global config & constants |
| [`lib/core/constants/nwu_default_data.dart`](lib/core/constants/nwu_default_data.dart) | Foundational NWU transit fleet & offline cache |
| [`lib/core/services/reachability_service.dart`](lib/core/services/reachability_service.dart) | Core reachability algorithm |
| [`lib/repositories/bus_repository.dart`](lib/repositories/bus_repository.dart) | Cloud Firestore data access & offline fallback |
| [`lib/repositories/auth_repository.dart`](lib/repositories/auth_repository.dart) | Firebase Authentication & profile synchronization |

---

## 🎓 Academic Context

- **University:** North Western University
- **Department:** Computer Science & Engineering
- **Project Type:** Mobile Application Development
- **Version:** 1.0.0+1
