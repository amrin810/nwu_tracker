# 📡 ESP32-S3 WROOM + u-blox NEO-7N GPS Bus Tracker

This directory contains the production embedded firmware and diagnostic tools for the North Western University (NWU) Bus Tracking IoT hardware beacon.

---

## 🔌 Circuit Connection Diagram

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

> **Note on Cross-over:** GPS **TX** must connect to ESP32 **RX (GPIO 18)**, and GPS **RX** connects to ESP32 **TX (GPIO 17)**.

---

## 📁 Files in This Directory

1. **[`config.h`](config.h)**: Wi-Fi credentials, Target Bus ID (`BUS_101`), Firebase host, API key, and pin definitions.
2. **[`esp32_bus_tracker.ino`](esp32_bus_tracker.ino)**: Main production firmware streaming real-time GPS telemetry to Firebase Realtime Database.
3. **[`gps_diagnostic.ino`](gps_diagnostic.ino)**: 1-minute diagnostic utility to test GPS wiring, baud rate, and satellite fix without needing Wi-Fi.
4. **[`HARDWARE_SETUP_GUIDE.md`](HARDWARE_SETUP_GUIDE.md)**: Full Bengali & English step-by-step flashing guide for Arduino IDE and PlatformIO.
5. **[`platformio.ini`](platformio.ini)**: PlatformIO build configuration for VS Code users.
