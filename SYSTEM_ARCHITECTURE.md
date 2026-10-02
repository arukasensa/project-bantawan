# BANTAWAN - System Architecture Documentation

> เอกสารฉบับนี้จัดเก็บอย่างเป็นทางการในโฟลเดอร์ **[`docs/SYSTEM_ARCHITECTURE.md`](file:///f:/flutter1/flutter1/docs/SYSTEM_ARCHITECTURE.md)**

---

# 1. บทนำและแนวคิดสถาปัตยกรรม (Architecture Overview)

**BANTAWAN** ถูกออกแบบขึ้นตามหลักการ **Offline-First** และ **High Operational Resilience** เพื่อให้มั่นใจได้ว่าระบบสามารถสนับสนุนชีวิตของผู้ประสบภัยและผู้กู้ภัยได้แม้อยู่ในสภาวะที่โครงสร้างพื้นฐานด้านโทรคมนาคม (Cell Towers, ISPs, Centralized Servers) ทำงานไม่ได้ หรือถูกทำลายจากภัยพิบัติ

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERFACE LAYER                           │
│     Screens (Home, Map, SOS, Nearby, Survival Tools, First Aid, Hike)      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            STATE MANAGEMENT LAYER                           │
│        Providers (MapProvider, ProfileProvider, Service Listeners)          │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DOMAIN & REPOSITORY LAYER                         │
│           IPoiRepository, IRoutingRepository & Implementations              │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INFRASTRUCTURE & SERVICE LAYER                      │
│   APIs (Longdo, OSM, OSRM)  │ P2P Mesh Network │ Hardware (GPS, BT, Sound) │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. การแบ่งชั้นสถาปัตยกรรม (Layer Responsibilities)

### 2.1 User Interface (UI) Layer (`lib/screens/`, `lib/widgets/`)
- **หน้าที่**: แสดงผลส่วนปฏิสัมพันธ์กับผู้ใช้ (User Interactions) แบบ Dark Mode นีออน (Glassmorphism & Tactical HUD Design)
- **การทำงาน**: รับคำสั่งจากผู้ใช้ (User Actions) แล้วเรียกใช้ `Provider` เพื่ออัปเดตสถานะ โดยไม่มีการฝัง Business Logic ซับซ้อนไว้ที่หน้าจอ

### 2.2 State Management Layer (`lib/providers/`)
- **หน้าที่**: บริหารจัดการสถานะของแอปพลิเคชัน (Reactive State Management) ผ่านรูปแบบ **Provider Pattern** (`ChangeNotifier`)
- **การทำงาน**: เก็บข้อมูลสถานะของแผนที่ (`MapProvider`), ข้อมูลส่วนบุคคลและสุขภาพ (`ProfileProvider`), ป้องกันการเกิด Rebuild หน้าจอที่ไม่จำเป็น และแจ้งเตือนหน้าจอ UI เมื่อข้อมูลมีการเปลี่ยนแปลงผ่าน `notifyListeners()`

### 2.3 Domain & Repository Layer (`lib/repositories/`, `lib/models/`)
- **หน้าที่**: กำหนดสัญญารูปแบบข้อมูล (Data Contracts / Interfaces) และจัดการตรรกะการเลือกแหล่งข้อมูล (Data Source Strategy)
- **คีย์ส่วนประกอบ**:
  - `IPoiRepository` / `PoiRepositoryImpl`: จัดการการดึงพิกัดโรงพยาบาลและสถานพยาบาล สลับระหว่างออนไลน์ (Longdo/Overpass) และออฟไลน์ (Local Cache)
  - `IRoutingRepository` / `RoutingRepositoryImpl`: จัดการการคำนวณเส้นทางสลับระหว่าง OSRM API (ขับขี่) และ Direct-Line Bearing (เดินเท้าออฟไลน์)
  - `MedicalFacility`, `RouteResult`, `CacheMetadata`: Data Entities หลักของระบบ

### 2.4 Infrastructure & Service Layer (`lib/services/`)
- **หน้าที่**: ติดต่อสื่อสารกับฮาร์ดแวร์ของอุปกรณ์, ระบบปฏิบัติติการ Android/iOS, ฐานข้อมูลในเครื่อง, และ REST APIs ภายนอก

---

## 3. สถาปัตยกรรมสื่อสารไร้เน็ต (Offline P2P Mesh Network Architecture)

```text
[อุปกรณ์ A (ผู้ประสบภัย)] ──(Hop 1)──► [อุปกรณ์ B (ผู้กู้ภัย/Relay)] ──(Hop 2)──► [อุปกรณ์ C (ศูนย์ช่วยเหลือ)]
(ส่ง SOS: TTL=5)                     (ลด TTL เหลือ 4 & บันทึก ID)             (ได้รับข้อความ + สั่นเตือน)
```

1. **P2P Cluster Strategy**: ใช้อัลกอริทึม `Strategy.P2P_CLUSTER` ให้ทุกอุปกรณ์เป็นทั้ง Client และ Router
2. **Loop Prevention (Deduplication)**: บันทึก `Message ID` หากได้รับซ้ำจะถูกตัดทิ้งทันที
3. **Multi-hop Relay with TTL**:
   - ข้อความทั่วไป: `TTL = 3`
   - ข้อความขอความช่วยเหลือ SOS: `TTL = 5`

---

*ดูเอกสารฉบับสมบูรณ์ที่ [docs/SYSTEM_ARCHITECTURE.md](file:///f:/flutter1/flutter1/docs/SYSTEM_ARCHITECTURE.md)*
