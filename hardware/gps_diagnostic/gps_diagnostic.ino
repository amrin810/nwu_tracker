/**
 * ============================================================================
 * NWU Bus Tracking — NEO-7N GPS Hardware Diagnostic Tool
 * ============================================================================
 * 
 * Purpose:
 *   Use this quick diagnostic sketch to verify your NEO-7N GPS wiring, antenna,
 *   and satellite fix BEFORE deploying the full Wi-Fi/Firebase code.
 * 
 * Instructions:
 *   1. Upload this sketch to your ESP32-S3 WROOM.
 *   2. Open the Serial Monitor @ 115200 baud.
 *   3. If you see raw NMEA text ($GPRMC, $GPGGA...), the wiring is 100% correct!
 *   4. Take the antenna near a window or outdoors to get satellite lock.
 */

#include "TinyGPSPlus.h"
#include "config.h"

HardwareSerial gpsSerial(1);
TinyGPSPlus gps;

unsigned long lastPrintMs = 0;

void setup() {
  Serial.begin(115200);
  delay(1500);

  Serial.println("\n=======================================================");
  Serial.println("     NEO-7N GPS Diagnostic Tool (ESP32-S3 WROOM)       ");
  Serial.println("=======================================================");
  Serial.printf("[SETUP] Initializing UART1 on RX=GPIO%d, TX=GPIO%d @ %d baud...\n",
                GPS_RX_PIN, GPS_TX_PIN, GPS_BAUD_RATE);

  gpsSerial.begin(GPS_BAUD_RATE, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  Serial.println("[SETUP] Ready! Waiting for NMEA data from NEO-7N module...\n");
  Serial.println("-------------------------------------------------------");
}

void loop() {
  // Read all incoming bytes from NEO-7N
  while (gpsSerial.available() > 0) {
    char c = gpsSerial.read();
    gps.encode(c);
  }

  // Print diagnostic status every 2 seconds
  if (millis() - lastPrintMs >= 2000) {
    lastPrintMs = millis();

    Serial.println("\n--- [GPS DIAGNOSTIC REPORT] ---");
    Serial.printf("Characters Processed: %lu\n", gps.charsProcessed());
    Serial.printf("Sentences with Fix  : %lu\n", gps.sentencesWithFix());
    Serial.printf("Checksum Errors     : %lu\n", gps.failedChecksum());

    if (gps.charsProcessed() < 10) {
      Serial.println("\n[!] WARNING: No data received from GPS module!");
      Serial.println("    -> Check your wiring: NEO-7N TX pin MUST connect to ESP32 GPIO 18 (RX).");
      Serial.println("    -> Ensure NEO-7N VCC is receiving 3.3V or 5V and GND is connected.");
      digitalWrite(STATUS_LED_PIN, LOW);
      return;
    }

    Serial.printf("Satellites in View  : %d\n", gps.satellites.value());

    if (gps.location.isValid()) {
      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("[*] GPS FIX ACQUIRED!");
      Serial.printf("    Latitude : %.6f\n", gps.location.lat());
      Serial.printf("    Longitude: %.6f\n", gps.location.lng());
      Serial.printf("    Speed    : %.2f km/h\n", gps.speed.kmph());
      Serial.printf("    Altitude : %.1f meters\n", gps.altitude.meters());
      if (gps.date.isValid() && gps.time.isValid()) {
        Serial.printf("    UTC Time : %04d-%02d-%02d %02d:%02d:%02d\n",
                      gps.date.year(), gps.date.month(), gps.date.day(),
                      gps.time.hour(), gps.time.minute(), gps.time.second());
      }
    } else {
      digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN)); // Flash LED
      Serial.println("[~] Searching for satellite lock...");
      Serial.println("    -> Make sure the external ceramic antenna is facing the open sky.");
      Serial.println("    -> First lock (cold start) takes 1 to 3 minutes outdoors.");
    }
  }
}
