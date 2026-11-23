/**
 * ============================================================================
 * North Western University (NWU) Bus Tracking System
 * Hardware Tracker Firmware for ESP32-S3 WROOM + u-blox NEO-7N GPS
 * ============================================================================
 * 
 * Hardware:
 *   - ESP32-S3 WROOM (Dual-Core 240MHz, 2.4GHz Wi-Fi)
 *   - u-blox NEO-7N / NEO-7M GPS Module (UART @ 9600 baud)
 * 
 * Function:
 *   - Reads live NMEA sentences from NEO-7N GPS module via HardwareSerial(1)
 *   - Filters out (0, 0) coordinates and invalid GPS fixes
 *   - Formats telemetry strictly conforming to Firebase Realtime Database rules:
 *     { "latitude": double, "longitude": double, "speed": double, "lastUpdated": uint64, "isActive": bool }
 *   - Streams telemetry over HTTPS to Firebase Realtime Database (/bus_locations/{BUS_ID})
 *   - Reconnects automatically to Wi-Fi and handles Firebase Token Refreshing
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <TinyGPSPlus.h>
#include <time.h>
#include "config.h"

// Hardware Serial instance for NEO-7N GPS module
HardwareSerial gpsSerial(1);

// TinyGPS++ parsing instance
TinyGPSPlus gps;

// Global State
String firebaseIdToken = "";
unsigned long lastTelemetryMs = 0;
unsigned long lastAuthMs = 0;
unsigned long lastLedBlinkMs = 0;
bool ledState = false;

// Forward Declarations
void connectWiFi();
bool authenticateFirebase();
void sendTelemetry();
uint64_t getEpochTimeMs();
void updateLedIndicator();

void setup() {
  // 1. Initialize USB Serial for diagnostic logging
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=======================================================");
  Serial.println("  NWU Bus Tracking System — ESP32-S3 GPS Transmitter  ");
  Serial.printf ("  Target Bus: %s\n", BUS_ID);
  Serial.println("=======================================================");

  // 2. Configure Status LED
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  // 3. Initialize HardwareSerial(1) for NEO-7N GPS
  Serial.printf("[GPS] Initializing NEO-7N on RX=GPIO%d, TX=GPIO%d @ %d baud...\n", 
                GPS_RX_PIN, GPS_TX_PIN, GPS_BAUD_RATE);
  gpsSerial.begin(GPS_BAUD_RATE, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  // 4. Connect to Wi-Fi
  connectWiFi();

  // 5. Synchronize System Clock with NTP
  Serial.println("[NTP] Synchronizing network time...");
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");

  // 6. Authenticate with Firebase if configured
  if (USE_EMAIL_AUTH) {
    authenticateFirebase();
  } else if (strlen(FIREBASE_SECRET) > 0) {
    firebaseIdToken = FIREBASE_SECRET;
  }

  Serial.println("[SYSTEM] Setup completed. Listening for GPS fix...");
}

void loop() {
  // Feed incoming UART bytes from GPS into TinyGPS++ parser
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  // Ensure Wi-Fi remains connected
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // Periodic Firebase Re-authentication (every ~50 minutes)
  if (USE_EMAIL_AUTH && (millis() - lastAuthMs >= REAUTH_INTERVAL_MS || firebaseIdToken.length() == 0)) {
    authenticateFirebase();
  }

  // Periodic Telemetry Dispatch
  if (millis() - lastTelemetryMs >= TELEMETRY_INTERVAL_MS) {
    lastTelemetryMs = millis();
    sendTelemetry();
  }

  // Update Status LED indicator
  updateLedIndicator();
}

/**
 * Connects to the designated Wi-Fi access point with watchdog timeout
 */
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  Serial.printf("[WIFI] Connecting to SSID: '%s'...\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 15000) {
    delay(250);
    Serial.print(".");
    digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN)); // Fast flash while connecting
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[WIFI] Connected! IP Address: %s (RSSI: %d dBm)\n", 
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
  } else {
    Serial.println("[WIFI] Connection failed. Will retry in loop...");
  }
}

/**
 * Authenticates against Google Identity Toolkit REST API to retrieve an ID token
 */
bool authenticateFirebase() {
  if (WiFi.status() != WL_CONNECTED) return false;

  Serial.println("[AUTH] Authenticating with Firebase Identity Toolkit...");
  WiFiClientSecure client;
  client.setInsecure(); // Skip root CA verification for lightweight embedded handshake

  HTTPClient http;
  String authUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + String(FIREBASE_API_KEY);

  if (!http.begin(client, authUrl)) {
    Serial.println("[AUTH] HTTP begin failed.");
    return false;
  }

  http.addHeader("Content-Type", "application/json");

  String requestBody = "{\"email\":\"" + String(DEVICE_EMAIL) + "\",\"password\":\"" + String(DEVICE_PASSWORD) + "\",\"returnSecureToken\":true}";
  int httpCode = http.POST(requestBody);

  if (httpCode == 200) {
    String response = http.getString();
    // Lightweight parser for "idToken": "..."
    int tokenIndex = response.indexOf("\"idToken\": \"");
    if (tokenIndex != -1) {
      int start = tokenIndex + 11;
      int end = response.indexOf("\"", start);
      firebaseIdToken = response.substring(start, end);
      lastAuthMs = millis();
      Serial.println("[AUTH] Successfully authenticated! ID Token acquired.");
      http.end();
      return true;
    }
  }

  Serial.printf("[AUTH] Authentication failed (HTTP %d). Re-check email/password in config.h\n", httpCode);
  http.end();
  return false;
}

/**
 * Validates GPS fix and sends real-time telemetry to Firebase RTDB
 */
void sendTelemetry() {
  // Check if GPS location fix is valid and non-zero
  if (!gps.location.isValid() || (gps.location.lat() == 0.0 && gps.location.lng() == 0.0)) {
    Serial.printf("[GPS] Searching for satellites... (Sats in view: %d, Sentences parsed: %lu)\n", 
                  gps.satellites.value(), gps.sentencesWithFix());
    return;
  }

  double lat = gps.location.lat();
  double lng = gps.location.lng();
  double speedKmh = gps.speed.isValid() ? gps.speed.kmh() : 0.0;

  // Filter stationary sensor jitter (ignore drift under 0.6 km/h)
  if (speedKmh < 0.6) {
    speedKmh = 0.0;
  }

  uint64_t epochMs = getEpochTimeMs();

  // Construct JSON strictly conforming to database.rules.json
  char payload[256];
  snprintf(payload, sizeof(payload),
    "{\"latitude\":%.6f,\"longitude\":%.6f,\"speed\":%.1f,\"lastUpdated\":%llu,\"isActive\":true}",
    lat, lng, speedKmh, epochMs
  );

  Serial.printf("[TELEMETRY] Dispatching -> %s\n", payload);

  // Send HTTPS PUT to Firebase Realtime Database: /bus_locations/{BUS_ID}.json
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();

    HTTPClient http;
    String targetUrl = String(FIREBASE_HOST) + "/bus_locations/" + String(BUS_ID) + ".json";
    if (firebaseIdToken.length() > 0) {
      targetUrl += "?auth=" + firebaseIdToken;
    }

    if (http.begin(client, targetUrl)) {
      http.addHeader("Content-Type", "application/json");
      int httpResponse = http.PUT((uint8_t*)payload, strlen(payload));

      if (httpResponse == 200 || httpResponse == 204) {
        Serial.printf("[FIREBASE] Success 200 OK! Bus %s updated on live map.\n", BUS_ID);
        // Quick flash LED to indicate successful transmission
        digitalWrite(STATUS_LED_PIN, HIGH);
        delay(80);
        digitalWrite(STATUS_LED_PIN, LOW);
      } else {
        Serial.printf("[FIREBASE] Write failed (HTTP %d): %s\n", httpResponse, http.getString().c_str());
        if (httpResponse == 401 && USE_EMAIL_AUTH) {
          // Token expired or invalid, trigger re-auth
          firebaseIdToken = "";
        }
      }
      http.end();
    }
  }
}

/**
 * Returns current timestamp in epoch milliseconds (from NTP or GPS UTC)
 */
uint64_t getEpochTimeMs() {
  time_t now;
  time(&now);
  if (now > 1700000000) {
    return ((uint64_t)now) * 1000ULL;
  }

  // Fallback: Compute epoch from TinyGPS++ date and time if NTP not yet synced
  if (gps.date.isValid() && gps.time.isValid() && gps.date.year() >= 2024) {
    struct tm t;
    t.tm_year = gps.date.year() - 1900;
    t.tm_mon  = gps.date.month() - 1;
    t.tm_mday = gps.date.day();
    t.tm_hour = gps.time.hour();
    t.tm_min  = gps.time.minute();
    t.tm_sec  = gps.time.second();
    t.tm_isdst = 0;
    return ((uint64_t)mktime(&t)) * 1000ULL + (gps.time.centisecond() * 10ULL);
  }

  // Absolute fallback
  return (uint64_t)millis();
}

/**
 * Status LED Visual Indicator:
 *   - Fast Blink (100ms) = Connecting to Wi-Fi
 *   - Slow Blink (800ms) = Wi-Fi Connected, acquiring GPS fix
 *   - Solid ON = GPS Fix active, tracking live
 */
void updateLedIndicator() {
  unsigned long now = millis();
  if (WiFi.status() != WL_CONNECTED) {
    // Fast blink
    if (now - lastLedBlinkMs >= 100) {
      lastLedBlinkMs = now;
      ledState = !ledState;
      digitalWrite(STATUS_LED_PIN, ledState);
    }
  } else if (!gps.location.isValid() || (gps.location.lat() == 0.0 && gps.location.lng() == 0.0)) {
    // Slow blink
    if (now - lastLedBlinkMs >= 800) {
      lastLedBlinkMs = now;
      ledState = !ledState;
      digitalWrite(STATUS_LED_PIN, ledState);
    }
  } else {
    // Solid ON when fix is established (with brief blips during sendTelemetry)
    digitalWrite(STATUS_LED_PIN, HIGH);
  }
}
