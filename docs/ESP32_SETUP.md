# ESP32 + NEO-6M GPS Tracker Setup Guide

This guide walks you through connecting an **ESP32 microcontroller** with a **u-blox NEO-6M GPS module** to transmit real-time bus locations to Firebase Realtime Database for the North Western University Bus Tracking system.

---

## 1. Security First (Important Rules)

> [!CAUTION]
> **NEVER** put Firebase Admin SDK credentials, database secrets, or master service account keys on the ESP32! Microcontroller firmware can be dumped or read.
> 
> Instead, this system uses **Device Accounts**: each bus has its own dedicated Firebase Authentication account (e.g. `bus101.tracker@nwu.edu.bd`). The ESP32 exchanges this email and password for a temporary ID token via the official Firebase Auth REST API, and writes ONLY to its assigned node (`bus_locations/BUS_101`).

---

## 2. Hardware Wiring (ESP32 to NEO-6M)

Connect the NEO-6M GPS module to the ESP32 using hardware UART serial pins:

| NEO-6M GPS Pin | ESP32 Pin | Description |
| :--- | :--- | :--- |
| **VCC** | **3.3V** or **5V** | Power supply (check your NEO-6M board voltage rating) |
| **GND** | **GND** | Ground |
| **TX** | **GPIO 16** (RX2) | GPS Serial Output -> ESP32 Serial Input |
| **RX** | **GPIO 17** (TX2) | GPS Serial Input <- ESP32 Serial Output |

> [!TIP]
> Place the NEO-6M ceramic patch antenna near a window or outdoors with an unobstructed view of the sky until the onboard tiny blue/red LED begins blinking (this signals a valid satellite GPS lock).

---

## 3. Creating Device Accounts in Firebase Console

1. Open **[Firebase Console](https://console.firebase.google.com/)** and select your project.
2. In the left navigation, go to **Build** > **Authentication** > **Users**.
3. Click **Add User** and create an account for each bus:
   - **Bus 101**: `bus101.tracker@nwu.edu.bd` (set a secure password)
   - **Bus 102**: `bus102.tracker@nwu.edu.bd`
   - **Bus 103**: `bus103.tracker@nwu.edu.bd`
4. Copy the **User UID** generated for each user.
5. In **Realtime Database** > **Data**, create the `device_owners` node mapping each bus ID to its UID:
   ```json
   {
     "device_owners": {
       "BUS_101": "<UID_OF_BUS_101_USER>",
       "BUS_102": "<UID_OF_BUS_102_USER>",
       "BUS_103": "<UID_OF_BUS_103_USER>"
     }
   }
   ```
6. Paste the contents of [`database.rules.json`](../database.rules.json) into **Realtime Database** > **Rules** and click **Publish**. Now, each bus tracker can only update its own coordinates!

---

## 4. Realtime Database Data Format

Every 5 seconds, the ESP32 transmits a JSON payload to:
`https://<YOUR-DATABASE-URL>/bus_locations/BUS_101.json?auth=<ID_TOKEN>`

```json
{
  "latitude": 22.8230,
  "longitude": 89.5440,
  "speed": 26.5,
  "lastUpdated": 1730800000,
  "isActive": true
}
```

- **`latitude`**: Between `-90.0` and `90.0` (Khulna is ~`22.82`). Must not be `0.0`.
- **`longitude`**: Between `-180.0` and `180.0` (Khulna is ~`89.54`). Must not be `0.0`.
- **`speed`**: Speed in kilometers per hour (`km/h`).
- **`lastUpdated`**: Current Unix timestamp in **seconds** (e.g. from GPS time or NTP).
- **`isActive`**: `true` while the bus engine is running and tracking is active.

---

## 5. Arduino IDE Code for ESP32

Install these libraries in the Arduino Library Manager:
- **TinyGPSPlus** (by Mikal Hart)
- **ArduinoJson** (by Benoît Blanchon)

```cpp
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <TinyGPSPlus.h>
#include <ArduinoJson.h>
#include <time.h>

// ---------------------- CONFIGURATION ----------------------
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase Web API Key (found in Project Settings > General in Firebase Console)
const char* FIREBASE_API_KEY = "AIzaSy...";

// Firebase Realtime Database Host (without https://)
// e.g. "nwu-bus-tracking-default-rtdb.asia-southeast1.firebasedatabase.app"
const char* RTDB_HOST = "YOUR_PROJECT_ID-default-rtdb.asia-southeast1.firebasedatabase.app";

// Device credentials for this bus
const char* BUS_ID        = "BUS_101";
const char* DEVICE_EMAIL  = "bus101.tracker@nwu.edu.bd";
const char* DEVICE_PASS   = "YourSecurePassword123";

// Update interval (every 5 seconds)
const unsigned long UPDATE_INTERVAL_MS = 5000;
// -----------------------------------------------------------

TinyGPSPlus gps;
HardwareSerial ss(2); // UART2: GPIO 16 (RX), GPIO 17 (TX)

String idToken = "";
unsigned long tokenExpireTime = 0;
unsigned long lastSendTime = 0;

// Function to authenticate device via Firebase Auth REST API
bool refreshFirebaseToken() {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String authUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + String(FIREBASE_API_KEY);

  http.begin(authUrl);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<200> reqDoc;
  reqDoc["email"] = DEVICE_EMAIL;
  reqDoc["password"] = DEVICE_PASS;
  reqDoc["returnSecureToken"] = true;

  String reqBody;
  serializeJson(reqDoc, reqBody);

  int httpCode = http.POST(reqBody);
  if (httpCode == 200) {
    String response = http.getString();
    DynamicJsonDocument resDoc(1024);
    deserializeJson(resDoc, response);

    idToken = resDoc["idToken"].as<String>();
    int expiresIn = resDoc["expiresIn"].as<int>(); // usually 3600 seconds
    tokenExpireTime = millis() + ((expiresIn - 120) * 1000UL); // renew 2 mins early

    Serial.println("[AUTH] Successfully acquired Firebase ID Token!");
    http.end();
    return true;
  } else {
    Serial.printf("[AUTH] Sign-in failed. HTTP Code: %d\n", httpCode);
    http.end();
    return false;
  }
}

// Function to transmit GPS payload to Realtime Database
void sendGpsData(double lat, double lng, double speedKmh, unsigned long unixSeconds) {
  if (millis() > tokenExpireTime || idToken == "") {
    if (!refreshFirebaseToken()) return;
  }

  HTTPClient http;
  String url = "https://" + String(RTDB_HOST) + "/bus_locations/" + String(BUS_ID) + ".json?auth=" + idToken;

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> doc;
  doc["latitude"]    = lat;
  doc["longitude"]   = lng;
  doc["speed"]       = speedKmh;
  doc["lastUpdated"] = unixSeconds;
  doc["isActive"]    = true;

  String jsonPayload;
  serializeJson(doc, jsonPayload);

  int httpCode = http.PUT(jsonPayload);
  if (httpCode == 200) {
    Serial.printf("[GPS] Sent: Lat=%.4f, Lng=%.4f, Speed=%.1f km/h, Time=%lu\n", lat, lng, speedKmh, unixSeconds);
  } else {
    Serial.printf("[GPS] RTDB write failed. HTTP: %d\n", httpCode);
  }
  http.end();
}

void setup() {
  Serial.begin(115200);
  ss.begin(9600, SERIAL_8N1, 16, 17); // NEO-6M default baud rate: 9600

  Serial.println("\n[SYSTEM] Starting NWU Bus GPS Tracker...");

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n[WIFI] Connected to network!");

  // Initialize NTP time as fallback for accurate seconds timestamp
  configTime(6 * 3600, 0, "pool.ntp.org", "time.google.com"); // UTC+6 for Bangladesh

  refreshFirebaseToken();
}

void loop() {
  // Feed incoming NMEA sentences from GPS to TinyGPS++
  while (ss.available() > 0) {
    gps.encode(ss.read());
  }

  // Periodic transmission
  if (millis() - lastSendTime >= UPDATE_INTERVAL_MS) {
    lastSendTime = millis();

    if (gps.location.isValid()) {
      double lat = gps.location.lat();
      double lng = gps.location.lng();
      double speed = gps.speed.kmh();

      // Acquire current Unix timestamp in seconds
      time_t now;
      time(&now);

      sendGpsData(lat, lng, speed, (unsigned long)now);
    } else {
      Serial.printf("[GPS] Waiting for valid satellite lock... (Satellites: %d)\n", gps.satellites.value());
    }
  }
}
```

---

## 6. How to Test in Firebase Console (Without Hardware)

You can easily simulate live buses by writing JSON directly into the Firebase Realtime Database:

1. Open **Firebase Console** > **Realtime Database** > **Data**.
2. Click the `+` icon on the root node and add a child named `bus_locations`.
3. In `bus_locations`, paste the following JSON test data (Khulna coordinates):

```json
{
  "BUS_101": {
    "latitude": 22.8230,
    "longitude": 89.5440,
    "speed": 26.5,
    "lastUpdated": 1730800000,
    "isActive": true
  },
  "BUS_102": {
    "latitude": 22.8270,
    "longitude": 89.5380,
    "speed": 31.0,
    "lastUpdated": 1730800000,
    "isActive": true
  },
  "BUS_103": {
    "latitude": 22.8180,
    "longitude": 89.5460,
    "speed": 18.0,
    "lastUpdated": 1730800000,
    "isActive": true
  }
}
```

> [!IMPORTANT]
> Replace `1730800000` with the current **Unix timestamp in seconds**!
> 
> In PowerShell, you can get the current timestamp by running:
> ```powershell
> [int][double]::Parse((Get-Date -UFormat %s))
> ```
> Or use [epochconverter.com](https://www.epochconverter.com/).
> 
> If `lastUpdated` is more than 60 seconds old, the app will correctly identify the bus as **Stale** and display the amber warning badge.

### Verifying Live Marker Glide Animation:
While keeping the Flutter app open on the **Live Bus Tracking** screen:
1. Change the `latitude` of `BUS_101` in Firebase Console from `22.8230` to `22.8245`.
2. Notice how the blue bus marker immediately slides smoothly across the road to the new coordinates in 60fps!

