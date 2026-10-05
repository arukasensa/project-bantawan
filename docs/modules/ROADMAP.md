# BANTAWAN - Project & Refactoring Roadmap

**โครงการ**: BANTAWAN (Smart Survival & Emergency Assistance Application)  
**สถานะปัจจุบัน**: Version 1.4.0 (Production Candidate / Academic Ready)  

---

## 📌 แผนภาพการดำเนินงาน (Milestones Overview)

```text
[ Phase 1: Core Foundation ] ──► [ Phase 2: Mesh Relay ] ──► [ Phase 3: Traffic Layer ]
         ✅ สำเร็จ                      ✅ สำเร็จ                      ✅ สำเร็จ
                                                                           │
                                                                           ▼
[ Phase 5: LoRa Radio Mesh ] ◄── [ Phase 4: Architecture Refactoring ] ◄──┘
         🔮 อนาคต                       🟡 วางแผนดำเนินการ
```

---

## 1. เฟสที่ดำเนินการสำเร็จแล้ว (Completed Phases)

### ✅ Phase 1: Core Foundation & Offline Capabilities (v1.0.0 - v1.1.0)
- พัฒนาโครงสร้างแอปพลิเคชันหลักด้วย Flutter SDK และ Provider Pattern
- สร้างเอ็นจินแผนที่ `flutter_map` และระบบดาวน์โหลดแผ่นภาพแผนที่ออฟไลน์ 10 ตร.กม.
- พัฒนาคู่มือปฐมพยาบาล CPR Visualizer และชุดเครื่องมือเอาชีวิตรอด (ไฟฉายมอร์ส SOS, เข็มทิศ, ไซเรน)

### ✅ Phase 2: Mesh Network & Multi-hop Relay (v1.2.0 - v1.3.0)
- รวมเอา Google Nearby Connections API มาสร้างห้องแชทไร้เน็ต P2P Cluster
- ติดตั้งอัลกอริทึม **Multi-hop Flooding Relay with TTL** (TTL=3 สำหรับแชททั่วไป, TTL=5 สำหรับ SOS)
- ระบบป้องกันการเกิด Broadcast Storm (Message Deduplication via UUID)

### ✅ Phase 3: Traffic & Incident Integration (v1.4.0)
- เชื่อมต่อ Longdo Traffic Incidents REST API
- แสดงผลหมุดอุบัติเหตุ/การจราจรติดขัด/งานก่อสร้างบนแผนที่สว่างสไตล์ CartoDB Voyager
- พัฒนาสถาปัตยกรรม Repository Pattern ให้กับมอดูลแผนที่ (`IPoiRepository`, `IRoutingRepository`, `PoiCacheService`)
- ผ่านการตรวจสอบประเภทโค้ด `flutter analyze` สะอาด 100% (No issues found!)

---

## 2. แผนการปรับปรุงสถาปัตยกรรม (Phase 4: Architecture Refactoring Roadmap)

### 🔴 High Priority (สิ่งที่ควรทำก่อน)
1. **Decouple State Management from Services**: ถอด `ChangeNotifier` ออกจาก `NearbyService`, `HikeService`, `MapOfflineService`, `SafetyCheckService`, `DeviceHealthService` แล้วสร้าง `Provider` แยกหน้าที่เฉพาะ
2. **Decompose Monolithic Screen Files**: ซอยย่อยไฟล์ขนาดใหญ่ เช่น `survival_tools_screen.dart` (~2,000 บรรทัด) และ `home_screen.dart` (~1,600 บรรทัด) ออกเป็นชิ้นส่วน Widgets ย่อยในโฟลเดอร์ `lib/widgets/`

### 🟡 Medium Priority (สิ่งที่ควรทำลำดับถัดไป)
1. **Standardize Repository Pattern Across All Modules**: ขยายการใช้งาน Repository Pattern ไปยังมอดูล Weather, Emergency Contacts, และ Nearby Chat
2. **Extract Static JSON Data**: ย้ายข้อมูลคู่มือปฐมพยาบาลใน `first_aid_service.dart` ออกไปอยู่ในไฟล์ `assets/data/first_aid.json`

### 🟢 Low Priority (สิ่งที่ควรทำเมื่อระบบหลักลงตัว)
1. **Reorganize Layer File Locations**: ย้ายตำแหน่งไฟล์ให้ตรงกับ Clean Architecture Layer (เช่น ย้าย Data Driver ไปที่ `data/datasources/`)
2. **Separate Controller from Visualizer Widgets**: แยกตรรกะเวลาของ `first_aid_visualizer.dart` ออกจากส่วนการวาด UI

---

## 3. แผนการขยายผลในอนาคต (Phase 5: Future Enhancements)

1. **End-to-End Encryption (E2EE)**: เพิ่มการเข้ารหัสข้อความแชท Nearby ด้วยอัลกอริทึม AES-256 / ECDH Key Exchange
2. **Hardware LoRa Radio Integration**: เชื่อมต่ออุปกรณ์วิทยุไร้สายระยะไกล (เช่น LoRa 433/915 MHz / Meshtastic) ผ่าน Bluetooth สำหรับส่ง SOS ข้ามระยะทางเกิน 10 กิโลเมตร
3. **Emergency SOS via Satellite Support**: พัฒนาการรองรับระบบสื่อสารดาวเทียมวงโคจรต่ำเมื่อเทคโนโลยีเปิดให้ใช้งานสาธารณะ
