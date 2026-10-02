# BANTAWAN - ระบบกู้ภัยและเอาชีวิตรอดอัจฉริยะ (Smart Survival & Search & Rescue Assistant)

> **BANTAWAN** คือแอปพลิเคชันช่วยเหลือฉุกเฉินและเอาชีวิตรอดอัจฉริยะ พัฒนาด้วย **Flutter Framework** ออกแบบตามหลัก **Offline-First Architecture** และ **Emergency UX** เพื่อสนับสนุนการเอาชีวิตรอด การสื่อสารไร้เน็ต และการนำทางบนแผนที่ได้แม้อยู่ในพื้นที่ปิดล้อม ภัยพิบัติ หรือจุดอับสัญญาณอินเทอร์เน็ต (Off-Grid) 

---

## 📚 เอกสารประกอบโครงการ (Project Documentation Index)

เอกสารทางวิชาการและคู่มือทางสถาปัตยกรรมฉบับสมบูรณ์จัดเก็บไว้ในโฟลเดอร์ **[`docs/`](file:///f:/flutter1/flutter1/docs)** และเอกสารหลักตามหมวดหมู่ดังนี้:

| เอกสาร | รายละเอียดและขอบเขตเนื้อหา | ลิงก์เข้าชม |
|---|---|---|
| **System Architecture** | สถาปัตยกรรมระบบ, Layer Dependencies, Mesh Network & State Management | [SYSTEM_ARCHITECTURE.md](file:///f:/flutter1/flutter1/docs/SYSTEM_ARCHITECTURE.md) |
| **Map Module Deep Dive** | ระบบแผนที่ 3 สไตล์, POI Data Pipeline, OSRM/Bearing Routing & Cache Eviction | [MAP_MODULE.md](file:///f:/flutter1/flutter1/docs/MAP_MODULE.md) |
| **API Documentation** | ข้อมูลการยิง REST APIs (Longdo, OSM Overpass, OSRM, Open-Meteo, Geocoding) | [API_DOCUMENTATION.md](file:///f:/flutter1/flutter1/docs/API_DOCUMENTATION.md) |
| **Project Roadmap** | แผนงานไมล์สโตนโครงการ และแผนการปรับปรุงโครงสร้างสถาปัตยกรรม (High/Med/Low) | [ROADMAP.md](file:///f:/flutter1/flutter1/docs/ROADMAP.md) |
| **Change Log** | บันทึกประวัติการพัฒนาและฟีเจอร์ใหม่แต่ละเวอร์ชัน (v1.0.0 - v1.4.0) | [CHANGELOG.md](file:///f:/flutter1/flutter1/docs/CHANGELOG.md) |

---

## 🌟 ฟีเจอร์หลักของระบบ (Core Features)

* **🗺️ ระบบแผนที่ออฟไลน์และการนำทางฉุกเฉิน (Offline Map & Emergency Navigation)**
  * สลับแผนที่ได้ 3 สไตล์: **Dark Mode** (สบายตาถนอมแบต), **Satellite Mode** (ภาพถ่ายดาวเทียม), **Traffic Mode** (ดูอุบัติเหตุการจราจรเรียลไทม์)
  * ดึงพิกัดสถานพยาบาลออนไลน์แบบคู่ขนาน (**Longdo REST + OpenStreetMap Overpass**) พร้อมระบบแคชลงเครื่อง ใช้งานได้แม้ไม่มีเน็ต
  * คำนวณเส้นทางขับขี่ด้วย OSRM API และสลับเป็น **Direct-line Bearing Navigation** พร้อมประมาณเวลาเดินเท้าเมื่อออฟไลน์
  * ระบบแคชอัจฉริยะ **CacheMetadata**: เช็คอายุแคช 24 ชั่วโมง และทำลายแคชเก่าเกิน 7 วันอัตโนมัติ

* **📻 ระบบแชทฉุกเฉินไร้เน็ต (Offline P2P Mesh Network Chat)**
  * สร้างห้องแชทไร้เน็ตผ่านสัญญาณ Bluetooth และ WiFi Direct (Google Nearby Connections API)
  * อัลกอริทึม **Multi-hop Flooding Relay with TTL**: ส่งต่อข้อความผ่านโหนดกลางทางอัตโนมัติ (TTL=3 สำหรับแชท, TTL=5 สำหรับ SOS) ขยายรัศมีสัญญาณได้หลายร้อยเมตร
  * ระบบป้องกันข้อความวนลูป (**Loop Prevention via UUID Deduplication**)
  * แสดงป้ายสัญลักษณ์ `[🔗 Mesh Relay]` บนหน้าจอสำหรับข้อความที่เดินทางผ่านโหนดกลางทาง

* **🚨 ระบบขอความช่วยเหลือฉุกเฉินบูรณาการ (SOS Command Suite)**
  * ปุ่ม SOS กดค้าง 3 วินาที (ป้องกันการกดโดนโดยอุบัติเหตุ) เพื่อเปิดเสียงไซเรนฉุกเฉินความถี่สูง, สังเคราะห์เสียงบรรยายภาษาไทย (TTS), และส่ง SMS พิกัดดาวเทียมฉุกเฉิน

* **🧭 ชุดเครื่องมือเอาชีวิตรอดดิจิทัล (Digital Survival Tools)**
  * ไฟฉายกะพริบสัญญาณรหัสมอร์สสากล SOS (`... --- ...`), เข็มทิศดิจิทัลบอกพิกัดความสูง, และระบบบันทึกเส้นทางเดินป่า (Hiking Dashboard)

* **🩺 คู่มือปฐมพยาบาลประกอบจังหวะ (First Aid Visualizer)**
  * คู่มือการช่วยชีวิตออฟไลน์ พร้อมภาพกราฟิกแอนิเมชันประกอบเสียงสังเคราะห์ช่วยบอกจังหวะเวลาในการทำ CPR และห้ามเลือด

---

## 🛠️ เทคโนโลยีที่เลือกใช้งาน (Technology Stack)

* **Core Framework**: Flutter SDK `^3.10.4` (Dart Language)
* **State Management**: Provider Pattern (`provider: ^6.1.1`)
* **GIS Map Engine**: `flutter_map: ^6.1.0` และ `latlong2: ^0.9.0`
* **Mesh Network Protocol**: Google Nearby Connections API (`nearby_connections: ^4.3.0`)
* **Persistence & Caching**: Shared Preferences (`shared_preferences: ^2.2.2`) & Dio Tile Cache
* **Hardware & Sensors**: `geolocator`, `flutter_compass`, `torch_light`, `audioplayers`, `flutter_tts`

---

## 📂 โครงสร้างโฟลเดอร์โครงการ (Project Architecture Structure)

```text
lib/
├── main.dart                          # จุดเริ่มต้นแอปพลิเคชันและการลงทะเบียน Providers
├── l10n/                              # ระบบสลับภาษา (Localization: Thai / English)
├── models/                            # Data Entities (MedicalFacility, RouteResult, CacheMetadata)
├── navigation/                        # Main Navigation Shell
├── providers/                         # State Management Layer (MapProvider, ProfileProvider)
├── repositories/                      # Architecture Interfaces & Repositories (PoiRepository, RoutingRepository)
├── screens/                           # UI Screens (Home, Map, SOS, Nearby Chat, Survival Tools, Hike, First Aid)
├── services/                          # Low-level REST APIs, Local Storage & Hardware Services
└── widgets/                           # Reusable UI Widgets & Map Custom Components
    └── map/                           # Map Component Widgets (MapControls, FacilitySheet, RoutingPanel)

docs/                                  # โฟลเดอร์เอกสารสถาปัตยกรรมฉบับเต็ม
├── SYSTEM_ARCHITECTURE.md             # รายงานสถาปัตยกรรมระบบขั้นสูง
├── MAP_MODULE.md                      # รายละเอียดเชิงลึกมอดูลแผนที่และการแคช
├── API_DOCUMENTATION.md               # ข้อกำหนด API สเปกอย่างละเอียด
├── ROADMAP.md                         # ไมล์สโตนและแผนผังปรับปรุงสถาปัตยกรรม
└── CHANGELOG.md                       # ประวัติการอัปเดตแต่ละเวอร์ชัน
```

---

## 🚀 ขั้นตอนการติดตั้งและรันโครงการ (Quick Start)

1. **เตรียมความพร้อมสภาพแวดล้อม**: ติดตั้ง Flutter SDK (เวอร์ชัน 3.10 ขึ้นไป) และ Android Studio / VS Code
2. **ติดตั้ง Dependencies**:
   ```bash
   flutter pub get
   ```
3. **รันตรวจสอบความถูกต้องของโค้ด**:
   ```bash
   flutter analyze
   ```
4. **รันทดสอบบนอุปกรณ์หรือ Emulator**:
   ```bash
   flutter run
   ```

---

## 📄 ใบอนุญาตและการประเมิน (License & Assessment)

จัดทำขึ้นเพื่อการประเมินทางวิชาการและการพัฒนาเทคโนโลยีกู้ภัยฉุกเฉิน (Academic Project & Digital Emergency Research)
#   i o s - b u i l d  
 