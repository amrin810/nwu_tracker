#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// 1. WI-FI CONFIGURATION
// ============================================================================
// The ESP32-S3 will connect to this Wi-Fi network (e.g., driver's mobile
// hotspot or bus Wi-Fi)
#define WIFI_SSID "A"            // Change to your mobile hotspot / Wi-Fi SSID
#define WIFI_PASSWORD "12345678" // Change to your Wi-Fi password

// ============================================================================
// 2. BUS IDENTIFICATION
// ============================================================================
// Target Bus ID corresponding to the Flutter tracking app:
// Options: "BUS_101", "BUS_102", "BUS_103", "BUS_104"
#define BUS_ID "BUS_101"

// ============================================================================
// 3. FIREBASE REALTIME DATABASE CONFIGURATION
// ============================================================================
// Your Firebase Realtime Database Host (no trailing slash)
#define FIREBASE_HOST "https://nwu-bus-tracking-default-rtdb.firebaseio.com"

// Firebase Web API Key (from your project's firebase_options.dart)
#define FIREBASE_API_KEY "AIzaSyB_quaT0wOizTrB1n6JNkSB7shZjD6tbPc"

// Device Authentication Mode:
// Set true to authenticate with Email/Password (recommended for production
// rules) Set false if using Database Secret or open test rules
#define USE_EMAIL_AUTH true
#define DEVICE_EMAIL "tracker_bus101@nwu.edu.bd"
#define DEVICE_PASSWORD "tracker@nwu2026"

// (Optional) Database Secret token if USE_EMAIL_AUTH is false
#define FIREBASE_SECRET ""

// ============================================================================
// 4. HARDWARE PIN DEFINITIONS (ESP32-S3 WROOM)
// ============================================================================
// UART1 pins connected to u-blox NEO-7N GPS module:
// Connect NEO-7N TX pin  -->  ESP32 GPS_RX_PIN (GPIO 18)
// Connect NEO-7N RX pin  -->  ESP32 GPS_TX_PIN (GPIO 17)
#define GPS_RX_PIN 18
#define GPS_TX_PIN 17
#define GPS_BAUD_RATE 9600 // Default u-blox baud rate

// Status LED Pin:
// Blinks fast (100ms) = Connecting to Wi-Fi
// Blinks slow (500ms) = Wi-Fi OK, searching for GPS satellites
// Solid ON / Flash on upload = GPS Lock acquired & streaming coordinates
#define STATUS_LED_PIN 2

// ============================================================================
// 5. TRANSMISSION & FILTERING TIMERS
// ============================================================================
#define TELEMETRY_INTERVAL_MS                                                  \
  3000 // Publish GPS update every 3 seconds (3000ms)
#define REAUTH_INTERVAL_MS                                                     \
  3000000 // Refresh Firebase ID token every ~50 minutes

#endif // CONFIG_H
