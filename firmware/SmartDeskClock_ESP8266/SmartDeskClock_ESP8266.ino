/*
  =============================================================================
  Project: DIY Smart Desk Clock (ESP8266 + DHT22 + LCD 1602 I2C + Future Hardware)
  Description: IoT Smart Desk Clock companion firmware for Flutter mobile app.
               Includes Side Quest 2 Wi-Fi stability fixes and modular hardware
               flags for future expansion (Battery ADC, Buzzer, External RTC).
  Target Hardware:
    - Board: ESP8266 (NodeMCU / Wemos D1 Mini with 18650 battery shield)
    - Display: LCD 16x2 with PCF8574 I2C module (Address: 0x27, SDA=D2, SCL=D1)
    - Sensor: DHT22 (Connected on Pin D4 / GPIO2)
    - Future Expansion Ready:
        1) Battery Sense Wire on Pin A0 (Set ENABLE_BATTERY_ADC to true when wired)
        2) Active/Passive Buzzer on Pin D5 (Set ENABLE_BUZZER_HW to true when wired)
        3) External RTC DS3231 on I2C (Set ENABLE_EXTERNAL_RTC to true when wired)
  =============================================================================
*/

#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <time.h>
#include <sys/time.h>
#include <ArduinoJson.h>

// ==================== 1. Modular Hardware Feature Flags ====================
// เปลี่ยนจาก false เป็น true ในอนาคตเมื่อต่ออุปกรณ์เสริมแต่ละชิ้นเรียบร้อยแล้ว
#define ENABLE_BATTERY_ADC   false  // [Option 1] false = ปิดการอ่านขา A0 ชั่วคราวเพื่อไม่ให้กวนคลื่น Wi-Fi (ส่งค่าจำลอง 85% ไปที่แอป)
#define ENABLE_BUZZER_HW     false  // [Option 2] false = ยังไม่ต่อลำโพง Buzzer (ใช้การกะพริบไฟจอ LCD + ข้อความปลุกแทนชั่วคราว)
#define ENABLE_EXTERNAL_RTC  false  // [Option 4] false = ยังไม่ต่อโมดูล RTC DS3231 (ใช้ NTP + ซิงค์เวลาจากแอป + เวลาสำรองภายในแทน)
#define SHOW_BATTERY_ON_LCD  false  // [LCD Mode] false = แสดงเฉพาะอุณหภูมิ/ความชื้นบนจอ LCD บรรทัดที่ 2 (แต่ยังส่งค่าแบตไปโชว์ในแอป)

// ==================== 2. Wi-Fi Configuration (2.4 GHz Only) ====================
const char* ssid     = "Celestino_2.4G";
const char* password = "BiMiLy3637^4Fv";

// ==================== 3. NTP Time Configuration (Bangkok UTC+7) ====================
const char* ntpServer          = "pool.ntp.org";
const long  gmtOffset_sec      = 7 * 3600; // GMT+7
const int   daylightOffset_sec = 0;

// ==================== 4. Hardware Pin Definitions ====================
#define DHTPIN     D4     // DHT22 Data pin (GPIO 2) - เสียบใช้งานจริงอยู่
#define DHTTYPE    DHT22  // Sensor type DHT22 (AM2302)
#define ANALOG_PIN A0     // ADC pin for 18650 battery sensing (สำหรับอนาคต)
#define BUZZER_PIN D5     // Buzzer pin (GPIO 14) สำหรับส่งเสียงปลุกในอนาคต

// Hardware objects
DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 16, 2);
ESP8266WebServer server(80);

// System state variables
bool isBacklightOn = true;
bool wasWifiConnected = false;
unsigned long lastSensorRead = 0;
unsigned long lastLcdUpdate = 0;
unsigned long lastDisplayToggle = 0;
int displayPage = 0;

// Cached sensor & battery values
float cachedTemp = 0.0;
float cachedHum = 0.0;
float cachedVoltage = 3.95;
int cachedBatteryPct = 85;

// Alarm state (companion to mobile app + future buzzer hardware)
int alarmHour = 7;
int alarmMinute = 0;
bool isAlarmEnabled = false;
bool isAlarmRinging = false;
int lastTriggeredMinute = -1;
unsigned long alarmStartMillis = 0;
bool alarmFlashState = false;

// ==================== 5. Modular Hardware Functions ====================

// [Future-Ready Function 1] อ่านค่าระดับแบตเตอรี่ 18650 (หรือใช้ค่าจำลองเมื่อยังไม่ต่อสาย A0)
void updateBatteryReading() {
#if ENABLE_BATTERY_ADC
  // โหมดฮาร์ดแวร์จริง: อ่านค่าแรงดันจากขา A0 เมื่อต่อสายแบ่งแรงดันจากถ่าน 18650 แล้ว
  int rawValue = analogRead(ANALOG_PIN);
  cachedVoltage = (rawValue / 1023.0) * 4.2;
  int pct = map((long)(cachedVoltage * 100), 300, 420, 0, 100);
  if (pct > 100) pct = 100;
  if (pct < 0) pct = 0;
  cachedBatteryPct = pct;
#else
  // โหมดจำลอง (ตัดการเรียก analogRead(A0) เพื่อป้องกันการกวนวงจร RF Calibration ของ Wi-Fi)
  cachedVoltage = 3.95;
  cachedBatteryPct = 85;
#endif
}

// [Active Hardware Function] อ่านค่าอุณหภูมิและความชื้นจริงจาก DHT22 ที่ขา D4
void updateSensorReadings() {
  updateBatteryReading();

  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (!isnan(t)) cachedTemp = t;
  if (!isnan(h)) cachedHum = h;
}

// [Future-Ready Function 2] ระบบเวลาสำรองและซิงค์โมดูล RTC ภายนอก (DS3231)
void initFallbackClockAndRTC() {
  // ตั้งเวลาเริ่มต้นสำรองไว้ที่ 12:00:00 (2026-01-01 12:00:00 UTC+7)
  // เพื่อไม่ให้หน้าจอค้างคำว่า "Syncing Time..." กรณีรอ Wi-Fi หรือใช้งานนอกสถานที่
  struct timeval tv;
  tv.tv_sec = 1767243600UL;
  tv.tv_usec = 0;
  settimeofday(&tv, NULL);

#if ENABLE_EXTERNAL_RTC
  // โครงสร้างรองรับโมดูล DS3231 RTC ผ่านบัส I2C (D1/D2) ในอนาคต
  Serial.println("[RTC] External RTC module hook enabled.");
#endif
}

// [Future-Ready Function 3] ระบบตรวจสอบเวลาปลุกและสั่งงาน Buzzer / ไฟกะพริบหน้าจอ
void checkAlarmAndTrigger(struct tm* timeinfo) {
  if (!isAlarmEnabled) {
    if (isAlarmRinging) {
      isAlarmRinging = false;
#if ENABLE_BUZZER_HW
      noTone(BUZZER_PIN);
      digitalWrite(BUZZER_PIN, LOW);
#endif
      // คืนค่าไฟหน้าจอตามสถานะเดิม
      if (isBacklightOn) lcd.backlight(); else lcd.noBacklight();
    }
    return;
  }

  // ตรวจสอบว่าถึงเวลาปลุก (ชั่วโมงและนาทีตรงกัน และยังไม่เคยปลุกในนาทีนี้)
  if (timeinfo->tm_hour == alarmHour &&
      timeinfo->tm_min == alarmMinute &&
      lastTriggeredMinute != timeinfo->tm_min) {
    isAlarmRinging = true;
    lastTriggeredMinute = timeinfo->tm_min;
    alarmStartMillis = millis();
    Serial.println("[ALARM] Alarm triggered!");
  }

  // รีเซ็ตตัวล็อกนาทีเมื่อผ่านนาทีที่ตั้งปลุกไปแล้ว
  if (timeinfo->tm_min != alarmMinute) {
    lastTriggeredMinute = -1;
  }

  // หากกำลังปลุกอยู่ ให้ทำงานเป็นเวลา 60 วินาที หรือจนกว่าจะกดปิดจากแอป
  if (isAlarmRinging) {
    if (millis() - alarmStartMillis > 60000) {
      isAlarmRinging = false;
#if ENABLE_BUZZER_HW
      noTone(BUZZER_PIN);
      digitalWrite(BUZZER_PIN, LOW);
#endif
      if (isBacklightOn) lcd.backlight(); else lcd.noBacklight();
    } else {
      // สลับสถานะทุกๆ 1 วินาที: กะพริบไฟจอ LCD + ส่งเสียง Buzzer (ถ้าต่ออุปกรณ์แล้ว)
      alarmFlashState = !alarmFlashState;
      if (alarmFlashState) {
        lcd.backlight();
#if ENABLE_BUZZER_HW
        tone(BUZZER_PIN, 2000, 400); // ส่งเสียงความถี่ 2000Hz นาน 400ms เมื่อต่อ Buzzer ที่ขา D5
#endif
      } else {
        lcd.noBacklight();
#if ENABLE_BUZZER_HW
        noTone(BUZZER_PIN);
#endif
      }
    }
  }
}

// ประเมินระดับความสบายจากอุณหภูมิและความชื้น
String getComfortText(float temp, float hum) {
  if (temp == 0.0 && hum == 0.0) return "Reading...";
  if (temp >= 21.0 && temp <= 27.5 && hum >= 40.0 && hum <= 65.0) {
    return "Comfortable";
  } else if (hum < 40.0) {
    return "Dry";
  } else if (hum > 65.0) {
    return "Humid";
  } else if (temp > 28.0) {
    return "Warm";
  } else {
    return "Cool";
  }
}

String getComfortIcon(float temp, float hum) {
  if (temp == 0.0 && hum == 0.0) return "^_^";
  if (temp >= 21.0 && temp <= 27.5 && hum >= 40.0 && hum <= 65.0) {
    return "^_^";
  } else if (hum < 40.0 || hum > 65.0) {
    return "~_~";
  } else {
    return "-_-";
  }
}

// ส่ง CORS Headers เพื่อให้แอป Flutter เชื่อมต่อข้ามโดเมนได้โดยไม่ติดบล็อก
void setCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
}

// ==================== 6. REST API Handlers ====================

void handleOptions() {
  setCorsHeaders();
  server.send(204);
}

// API: GET /api/data (ส่งข้อมูลอุณหภูมิ ความชื้น แบตเตอรี่ และสถานะนาฬิกาให้แอปทันที)
void handleGetData() {
  setCorsHeaders();

  time_t now = time(nullptr);
  struct tm* timeinfo = localtime(&now);
  char timeBuffer[16] = "12:00:00";
  strftime(timeBuffer, sizeof(timeBuffer), "%H:%M:%S", timeinfo);

  StaticJsonDocument<448> doc;
  doc["temp"]           = ((int)(cachedTemp * 10)) / 10.0;
  doc["temperature"]    = ((int)(cachedTemp * 10)) / 10.0;
  doc["hum"]            = ((int)(cachedHum * 10)) / 10.0;
  doc["humidity"]       = ((int)(cachedHum * 10)) / 10.0;
  doc["battery"]        = cachedBatteryPct;
  doc["batteryPercent"] = cachedBatteryPct;
  doc["batteryVoltage"] = ((int)(cachedVoltage * 100)) / 100.0;
  doc["online"]         = true;
  doc["isOnline"]       = true;
  doc["isBacklightOn"]  = isBacklightOn;
  doc["time"]           = String(timeBuffer);
  doc["comfort"]        = getComfortText(cachedTemp, cachedHum);
  doc["comfortIcon"]    = getComfortIcon(cachedTemp, cachedHum);
  doc["alarmEnabled"]   = isAlarmEnabled;
  doc["alarmRinging"]   = isAlarmRinging;
  doc["alarmHour"]      = alarmHour;
  doc["alarmMinute"]    = alarmMinute;
  doc["uptime"]         = millis() / 1000;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// API: POST /api/backlight (สั่งเปิด-ปิดไฟหน้าจอ LCD จากแอป)
void handleBacklight() {
  setCorsHeaders();
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Body missing\"}");
    return;
  }

  StaticJsonDocument<128> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Invalid JSON\"}");
    return;
  }

  if (doc.containsKey("state")) {
    isBacklightOn = doc["state"].as<bool>();
    if (isBacklightOn) {
      lcd.backlight();
    } else {
      lcd.noBacklight();
    }
  }

  server.send(200, "application/json", isBacklightOn ? "{\"status\":\"ok\",\"backlight\":true}" : "{\"status\":\"ok\",\"backlight\":false}");
}

// API: POST /api/synctime (ซิงค์เวลาจากโทรศัพท์มือถือเข้าสู่บอร์ดโดยตรง)
void handleSyncTime() {
  setCorsHeaders();
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Body missing\"}");
    return;
  }

  StaticJsonDocument<128> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Invalid JSON\"}");
    return;
  }

  unsigned long epochTime = doc["timestamp"].as<unsigned long>();
  if (epochTime > 1000000000UL) {
    struct timeval tv;
    tv.tv_sec = epochTime + gmtOffset_sec; // ปรับชดเชยเวลาท้องถิ่น GMT+7
    tv.tv_usec = 0;
    settimeofday(&tv, NULL);

    Serial.printf("[TIME] System clock synced from mobile app: %lu\n", epochTime);
    server.send(200, "application/json", "{\"status\":\"success\",\"message\":\"Clock synchronized\"}");
  } else {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Invalid timestamp\"}");
  }
}

// API: POST /api/alarm (ตั้งเวลาปลุกและเปิด/ปิดเสียงปลุกจากแอป)
void handleAlarm() {
  setCorsHeaders();
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Body missing\"}");
    return;
  }

  StaticJsonDocument<128> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Invalid JSON\"}");
    return;
  }

  if (doc.containsKey("enabled")) isAlarmEnabled = doc["enabled"].as<bool>();
  if (doc.containsKey("hour"))    alarmHour = doc["hour"].as<int>();
  if (doc.containsKey("minute"))  alarmMinute = doc["minute"].as<int>();

  // หากสั่งปิด Alarm จากแอปขณะกำลังปลุกอยู่ ให้หยุดปลุกทันที
  if (!isAlarmEnabled && isAlarmRinging) {
    isAlarmRinging = false;
#if ENABLE_BUZZER_HW
    noTone(BUZZER_PIN);
    digitalWrite(BUZZER_PIN, LOW);
#endif
    if (isBacklightOn) lcd.backlight(); else lcd.noBacklight();
  }

  StaticJsonDocument<128> res;
  res["status"] = "ok";
  res["alarmEnabled"] = isAlarmEnabled;
  res["hour"] = alarmHour;
  res["minute"] = alarmMinute;
  String out;
  serializeJson(res, out);
  server.send(200, "application/json", out);
}

// API: GET /api/ping (ตรวจสอบการเชื่อมต่อ)
void handlePing() {
  setCorsHeaders();
  server.send(200, "application/json", "{\"status\":\"ok\",\"device\":\"SmartDeskClock\",\"version\":\"2.2\"}");
}

// ==================== 7. Arduino Setup ====================
void setup() {
  Serial.begin(115200);
  Wire.begin(D2, D1); // I2C SDA=D2 (GPIO4), SCL=D1 (GPIO5)

#if ENABLE_BUZZER_HW
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
#endif

  // ตั้งเวลาสำรองเริ่มต้นทันที เพื่อไม่ให้หน้าจอค้างหากไม่มีอินเทอร์เน็ต
  initFallbackClockAndRTC();

  lcd.init();
  lcd.backlight();
  isBacklightOn = true;

  lcd.setCursor(0, 0);
  lcd.print("Smart Desk Clock");
  lcd.setCursor(0, 1);
  lcd.print("Connecting WiFi");

  // ตั้งค่า Wi-Fi เสถียรภาพสูง (แก้ปัญหา Side Quest 2)
  // - ปิดโหมดประหยัดพลังงาน Wi-Fi เพื่อไม่ให้สัญญาณหลุดขณะรอรับคำสั่งจากแอป
  // - ยังไม่สั่งเริ่ม DHT22 และไม่อ่านค่า A0 ระหว่างจับคู่คลื่นวิทยุ
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.setSleepMode(WIFI_NONE_SLEEP);
  WiFi.setAutoReconnect(true);
  WiFi.begin(ssid, password);

  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 50) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  lcd.clear();
  if (WiFi.status() == WL_CONNECTED) {
    wasWifiConnected = true;
    Serial.println("");
    Serial.print("Connected! IP Address: ");
    Serial.println(WiFi.localIP());

    // แสดง IP Address บนหน้าจอ 5 วินาทีเพื่อให้จดไปกรอกในแอปได้สะดวก
    lcd.setCursor(0, 0);
    lcd.print("WiFi Connected!");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    delay(5000);

    // ซิงค์เวลามาตรฐานจาก NTP Server
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  } else {
    Serial.println("\nWiFi still connecting in background. Starting offline clock...");
    lcd.setCursor(0, 0);
    lcd.print("Offline / Auto");
    lcd.setCursor(0, 1);
    lcd.print("Clock Running...");
    delay(2000);
  }

  // เริ่มการทำงานของเซนเซอร์ DHT22 หลังจากขั้นตอน Wi-Fi เสร็จสิ้น
  dht.begin();
  delay(100);
  updateSensorReadings();

  // ลงทะเบียน REST API Endpoints สำหรับแอปมือถือ
  server.on("/api/data", HTTP_GET, handleGetData);
  server.on("/api/data", HTTP_OPTIONS, handleOptions);

  server.on("/api/backlight", HTTP_POST, handleBacklight);
  server.on("/api/backlight", HTTP_OPTIONS, handleOptions);

  server.on("/api/synctime", HTTP_POST, handleSyncTime);
  server.on("/api/synctime", HTTP_OPTIONS, handleOptions);

  server.on("/api/alarm", HTTP_POST, handleAlarm);
  server.on("/api/alarm", HTTP_OPTIONS, handleOptions);

  server.on("/api/ping", HTTP_GET, handlePing);
  server.on("/api/ping", HTTP_OPTIONS, handleOptions);

  server.begin();
  lcd.clear();
}

// ==================== 8. Arduino Main Loop ====================
void loop() {
  // 1. รับคำสั่ง HTTP จากแอปมือถืออย่างรวดเร็ว (ไม่มี delay ยาวขวางการทำงาน)
  server.handleClient();

  // 2. หาก Wi-Fi เชื่อมต่อสำเร็จตามหลังใน Background ให้ซิงค์ NTP และโชว์ IP อัตโนมัติ
  if (WiFi.status() == WL_CONNECTED && !wasWifiConnected) {
    wasWifiConnected = true;
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

    Serial.print("\nWiFi Connected (Background)! IP: ");
    Serial.println(WiFi.localIP());

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Connected!");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP());
    delay(5000);
    lcd.clear();
  }

  // 3. อ่านค่าเซนเซอร์ DHT22 จริงทุกๆ 5 วินาที (ไม่บล็อก Interrupt ถี่เกินไป)
  if (millis() - lastSensorRead >= 5000) {
    lastSensorRead = millis();
    updateSensorReadings();
  }

  // 4. อัปเดตหน้าจอ LCD และเช็กสถานะปลุกทุกๆ 1 วินาที (ลดภาระบัส I2C และการดึงกระแสไฟ)
  if (millis() - lastLcdUpdate >= 1000) {
    lastLcdUpdate = millis();

    time_t now = time(nullptr);
    struct tm* timeinfo = localtime(&now);

    // ตรวจสอบเวลาปลุก
    checkAlarmAndTrigger(timeinfo);

    // บรรทัดที่ 1: แสดงเวลาดิจิทัล HH:MM:SS (เดินเวลาต่อเนื่องไม่มีค้างหน้า Syncing)
    char line1[17];
    strftime(line1, sizeof(line1), "Time: %H:%M:%S  ", timeinfo);
    lcd.setCursor(0, 0);
    lcd.print(line1);

    // บรรทัดที่ 2: หากกำลังปลุกให้แสดงข้อความปลุก หากปกติให้แสดงอุณหภูมิ/ความชื้นจาก DHT22
    lcd.setCursor(0, 1);
    if (isAlarmRinging) {
      lcd.print("! ALARM RINGING!");
    } else {
#if SHOW_BATTERY_ON_LCD
      if (millis() - lastDisplayToggle > 4000) {
        displayPage = (displayPage + 1) % 2;
        lastDisplayToggle = millis();
      }
#else
      displayPage = 0; // แสดงเฉพาะหน้าอุณหภูมิและความชื้นตามที่เลือก
#endif

      if (displayPage == 0) {
        if (cachedTemp != 0.0 || cachedHum != 0.0) {
          String icon = getComfortIcon(cachedTemp, cachedHum);
          char line2[17];
          snprintf(line2, sizeof(line2), "%.1fC %.0f%% (%s) ", cachedTemp, cachedHum, icon.c_str());
          lcd.print(line2);
        } else {
          lcd.print("Reading DHT22...");
        }
      } else {
        char line2[17];
        snprintf(line2, sizeof(line2), "Batt: %d%% (%.1fV)", cachedBatteryPct, cachedVoltage);
        lcd.print(line2);
      }
    }
  }

  delay(10); // คืนจังหวะให้ระบบจัดการคลื่น Wi-Fi ของ ESP8266 ทำงานได้อย่างราบรื่น
}
