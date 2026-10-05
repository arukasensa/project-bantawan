# BANTAWAN - ระบบกู้ภัยและเอาชีวิตรอดอัจฉริยะ (Smart Survival & Search & Rescue Assistant)

> **BANTAWAN** คือแอปพลิเคชันช่วยเหลือฉุกเฉินและเอาชีวิตรอดอัจฉริยะ พัฒนาด้วย **Flutter Framework** ออกแบบตามหลัก **Offline-First Architecture** และ **Emergency UX** เพื่อสนับสนุนการเอาชีวิตรอด การสื่อสารไร้เน็ต และการนำทางบนแผนที่ได้แม้อยู่ในพื้นที่ปิดล้อม ภัยพิบัติ หรือจุดอับสัญญาณอินเทอร์เน็ต (Off-Grid) 

---

## 📚 เอกสารประกอบโครงการ (Project Documentation Index)

เอกสารทางเทคนิคและสถาปัตยกรรมฉบับสมบูรณ์จัดเก็บเป็นหมวดหมู่อยู่ในโฟลเดอร์ **[`docs/`](file:///f:/flutter1/flutter1/docs/README.md)**:

| หมวดหมู่ | เอกสารหลัก | รายละเอียดและขอบเขตเนื้อหา | ลิงก์เข้าชม |
|---|---|---|---|
| **Architecture** | **System Architecture** | สถาปัตยกรรมระบบ Clean Feature-First, State Management, SQLite V6 | [SYSTEM_ARCHITECTURE.md](docs/architecture/SYSTEM_ARCHITECTURE.md) |
| **Mesh Protocol**| **Mesh Routing Protocol** | เจาะลึกวิทยุสื่อสาร Multi-hop Flooding Relay, Dynamic Hop, Data Mule | [MESH_ROUTING.md](docs/architecture/MESH_ROUTING.md) |
| **Offline-First** | **Offline Storage Design** | กลยุทธ์การทำงานออฟไลน์ 100%, Slippy Map Tiling, Cache Eviction | [OFFLINE_DESIGN.md](docs/architecture/OFFLINE_DESIGN.md) |
| **GIS & Maps**   | **Map Module Deep Dive** | ระบบแผนที่ 3 สไตล์, OfflineFallbackTileProvider, POI Pipeline | [MAP_MODULE.md](docs/modules/MAP_MODULE.md) |
| **REST APIs**    | **API Documentation** | สเปกและตัวอย่างคำขอ Longdo Map, OSM Overpass, OSRM, Open-Meteo | [API_DOCUMENTATION.md](docs/api/API_DOCUMENTATION.md) |
| **Guides**       | **Installation & Deploy**| คู่มือการติดตั้งและคำแนะนำการคอมไพล์ Production APK / Release | [INSTALL.md](docs/guides/INSTALL.md) \| [DEPLOY.md](docs/guides/DEPLOYMENT.md) |
| **Change Log**   | **Version History** | บันทึกประวัติการพัฒนาและฟีเจอร์ใหม่แต่ละเวอร์ชัน (v1.0.0 - v1.4.0) | [CHANGELOG.md](CHANGELOG.md) |

> 📌 *ดูสารบัญและแผนผังเอกสารฉบับเต็มได้ที่ [docs/README.md](docs/README.md)*

---

## 🌟 ฟีเจอร์หลักของระบบ (Core Features)

* **🗺️ ระบบแผนที่ออฟไลน์และการนำทางฉุกเฉิน (Offline Map & Emergency Navigation)**
  * สลับแผนที่ได้ 3 สไตล์: **Dark Mode** (สบายตาถนอมแบต), **Satellite Mode** (ภาพถ่ายดาวเทียม), **Traffic Mode** (ดูอุบัติเหตุการจราจรเรียลไทม์)
  * **OfflineFallbackTileProvider**: ดึงแผ่นแผนที่จากความจำเครื่อง (`map_tiles/{z}/{x}/{y}.png`) มาแสดงผลทันทีแบบ 0ms แม้ไร้เน็ต 100%
  * ดึงพิกัดสถานพยาบาลออนไลน์แบบคู่ขนาน (**Longdo REST + OpenStreetMap Overpass**) พร้อมระบบแคชลงเครื่อง ใช้งานได้แม้ไม่มีเน็ต
  * คำนวณเส้นทางขับขี่ด้วย OSRM API และสลับเป็น **Direct-line Bearing Navigation** พร้อมประมาณเวลาเดินเท้าเมื่อออฟไลน์
  * ระบบแคชอัจฉริยะ **CacheMetadata**: เช็คอายุแคช 24 ชั่วโมง และทำลายแคชเก่าเกิน 7 วันอัตโนมัติ

* **📻 ระบบแชทฉุกเฉินไร้เน็ต (Offline P2P Mesh Network Chat)**
  * สร้างห้องแชทไร้เน็ตผ่านสัญญาณ Bluetooth Low Energy และ WiFi Direct (Google Nearby Connections API)
  * อัลกอริทึม **Multi-hop Flooding Relay with Dynamic Hop Count**: ส่งต่อข้อความผ่านโหนดกลางทางอัตโนมัติ (TTL=3 สำหรับแชท, TTL=5 สำหรับ SOS) ขยายรัศมีสัญญาณได้หลายร้อยเมตร
  * ระบบซิงก์บริดจ์ **Active Peer Announce** ทุก 25 วินาที พร้อมปรับระยะ Hop Count อัตโนมัติตามระยะเดินจริง
  * ระบบป้องกันข้อความวนลูป (**Loop Prevention via UUID Deduplication & LruCache**)
  * ระบบตอบกลับใบเสร็จรับส่งเจาะจงท่อทางเดิม (**Smart Reverse-Path Unicast ACK**) ประหยัดแบนด์วิดท์วิทยุ 80%+
  * ระบบ **Data Mule (Store-Carry-and-Forward)** ฝากจดหมายเข้ารหัสเดินทางข้ามพื้นที่ห่างไกล

* **🚨 ระบบขอความช่วยเหลือฉุกเฉินบูรณาการ (SOS Command Suite)**
  * ปุ่ม SOS กดค้าง 3 วินาที (ป้องกันการกดโดนโดยอุบัติเหตุ) เพื่อเปิดเสียงไซเรนฉุกเฉินความถี่สูง, สังเคราะห์เสียงบรรยายภาษาไทย (TTS), และส่ง SMS พิกัดดาวเทียมฉุกเฉิน

* **🧭 ชุดเครื่องมือเอาชีวิตรอดดิจิทัล (Digital Survival Tools)**
  * ไฟฉายกะพริบสัญญาณรหัสมอร์สสากล SOS (`... --- ...`), เข็มทิศดิจิทัลบอกพิกัดความสูง, และระบบบันทึกเส้นทางเดินป่า (Hiking Dashboard) พร้อมระบบนำทางย้อนรอย (Backtrack) แม้ล็อกหน้าจอ

* **🩺 คู่มือปฐมพยาบาลประกอบจังหวะ (First Aid Visualizer)**
  * คู่มือการช่วยชีวิตออฟไลน์ พร้อมภาพกราฟิกแอนิเมชันประกอบเสียงสังเคราะห์และตัวสั่นจังหวะช่วยบอกเวลาในการทำ CPR (100-110 BPM) และการขันชะเนาะห้ามเลือด

---

## 🛠️ เทคโนโลยีที่เลือกใช้งาน (Technology Stack)

* **Core Framework**: Flutter SDK `^3.10.4` (Dart Language)
* **State Management**: Provider Pattern (`provider: ^6.1.1`)
* **GIS Map Engine**: `flutter_map: ^6.1.0` และ `latlong2: ^0.9.0`
* **Mesh Network Protocol**: Google Nearby Connections API (`nearby_connections: ^4.3.0`)
* **Encryption**: AES-256-CTR, X25519 ECDH, HKDF-SHA256, HMAC-SHA256
* **Database & Persistence**: SQLite (`sqflite: ^2.3.3+1`) Schema V6 & SharedPreferences
* **Hardware & Sensors**: `geolocator`, `flutter_compass`, `torch_light`, `audioplayers`, `flutter_tts`, `record`

---

## 📂 โครงสร้างโฟลเดอร์โครงการ (Project Architecture Structure)

```text
lib/
├── main.dart                          # จุดเริ่มต้นแอปพลิเคชันและการลงทะเบียน MultiProvider
├── l10n/                              # ระบบสลับภาษา (Localization: Thai / English)
├── navigation/                        # Main Navigation Shell (Floating Glassmorphism Bar)
├── providers/                         # Shared ViewModels (MapProvider, ProfileProvider)
└── features/                          # Feature-First Architecture Modules
    ├── chat/                          # ระบบแชทออฟไลน์ Mesh Relay, E2EE, Data Mule, SQLite V6
    ├── map/                           # ระบบแผนที่ GIS, Offline Tile Fallback, POI Markers
    ├── survival/                      # เครื่องมือยังชีพ, Hike Tracker, เข็มทิศ, ไซเรน SOS
    ├── first_aid/                     # คู่มือปฐมพยาบาล, CPR Metronome, Tourniquet
    ├── weather/                       # สภาพอากาศและฝุ่น PM2.5 แจ้งเตือนภัยพิบัติ
    └── home/                          # Dashboard สรุปความพร้อมของอุปกรณ์และสถานะวิทยุ
```

```text
docs/                                  # ศูนย์รวมเอกสารสถาปัตยกรรมและวิชาการฉบับเต็ม
├── architecture/                      # สถาปัตยกรรมระบบ, Mesh Routing, Offline Design
├── modules/                           # สเปกมอดูลแผนที่, ฟีเจอร์, และ Roadmap
├── api/                               # สเปกการเชื่อมต่อ REST API ภายนอก
├── guides/                            # คู่มือติดตั้ง, Deploy, และ Troubleshooting
├── rules/                             # กฎระเบียบและมาตรฐานการเขียนโค้ด
└── academic/                          # เอกสารวิชาการ, บทคัดย่อ, ทฤษฎี, และ AI Log
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