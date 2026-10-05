# BANTAWAN - Offline-First Architecture & Storage Strategy

**เอกสารการออกแบบระบบทำงานออฟไลน์และการจัดการแคช (Layer 1 - Layer 3)**  
**เวอร์ชัน**: 2.0.0  

---

## 🧭 1. ปรัชญา Offline-First (Offline-First Principles)

แอปพลิเคชันช่วยเหลือฉุกเฉินทั่วไปมักออกแบบโดยสมมุติว่า "มีอินเทอร์เน็ตเป็นหลัก แล้วค่อยทำระบบ Offline รองรับ" แต่ **BANTAWAN** ออกแบบบนสมมติฐานตรงกันข้ามคือ:
> **"เครือข่ายอินเทอร์เน็ตอาจไม่มีอยู่จริงตั้งแต่ต้น และระบบต้องพร้อมใช้งานฟังก์ชันช่วยชีวิตได้ 100% ทันทีที่เปิดแอป"**

---

## 🗺️ 2. ระบบแผนที่ออฟไลน์และการสลับโหมดอัตโนมัติ (Tile Caching & Fallback)

### 2.1 Slippy Map Tiling Engine (`MapOfflineService`)
* ระบบตัดแผ่นแผนที่ตามมาตรฐาน **Slippy Map (OSM XYZ Scheme)**
* แปลงพิกัดละติจูด/ลองจิจูดเป็นตำแหน่งแผ่นไทล์ผ่านสูตรคณิตศาสตร์:
  $$\text{tileX} = \lfloor \frac{\text{lon} + 180}{360} \times 2^{\text{zoom}} \rfloor$$
  $$\text{tileY} = \lfloor \frac{1 - \ln(\tan(\text{lat}_{\text{rad}}) + \sec(\text{lat}_{\text{rad}})) / \pi}{2} \times 2^{\text{zoom}} \rfloor$$
* ดาวน์โหลดครอบคลุมรัศมี 2 กิโลเมตร (พื้นที่ 10-12 ตร.กม.) ตั้งแต่ระดับซูม 12 ถึง 16
* จัดเก็บลงไดเรกทอรีของแอปพลิเคชัน:  
  `${ApplicationDocumentsDirectory}/map_tiles/{z}/{x}/{y}.png`

### 2.2 ตัวแสดงผลอัจฉริยะ (`OfflineFallbackTileProvider`)
* ในหน้าจอแผนที่หลัก (`map_screen.dart`):
  1. เมื่อแผนที่ต้องการเรนเดอร์พิกัด `(z, x, y)` จะตรวจสอบก่อนว่าไฟล์ `${localTilesPath}/z/x/y.png` มีอยู่จริงในเครื่องหรือไม่
  2. **หากมีไฟล์**: เรนเดอร์ด้วย `FileImage` ทันที ความเร็ว 0ms ไม่ต้องใช้อินเทอร์เน็ต และไม่เสียค่าบริการ
  3. **หากไม่มีไฟล์**: สลับไปดึงภาพจาก OpenStreetMap ผ่าน `NetworkImage` อัตโนมัติ

---

## 🏥 3. ท่อข้อมูลสถานพยาบาลออฟไลน์ (POI Pipeline & Cache Eviction)

```text
[ผู้ใช้เปิดแผนที่]
        │
        ▼
[ตรวจสอบอินเทอร์เน็ต]
  ├── มีเน็ต ──► ยิงดึงข้อมูลแบบขนาน (Longdo Tag + Keyword + OSM Overpass)
  │              └── บันทึกลง PoiCacheService (SQLite / SharedPreferences)
  │
  └── ไร้เน็ต ─► ดึงพิกัดโรงพยาบาลจาก PoiCacheService ในเครื่องทันที
                 └── กรองหาระยะทางและทิศทางรอบตัวผู้ใช้ (Harversine Formula)
```

### นโยบายการหมดอายุของแคช (Cache Eviction Policy)
* **Fresh Cache (< 24 ชั่วโมง)**: ถือเป็นข้อมูลสด ใช้งานได้ทันที
* **Stale Cache (24 ชม. - 7 วัน)**: แสดงผลพร้อมแจ้งเตือนว่าข้อมูลอาจไม่อัปเดต
* **Expired Cache (> 7 วัน)**: ระบบรัน Auto-Purge เคลียร์หน่วยความจำเพื่อประหยัดพื้นที่บนเครื่อง

---

## 🗄️ 4. สถาปัตยกรรมฐานข้อมูล SQLite ท้องถิ่น (Database Schema V6)

ฐานข้อมูล [`ChatDatabaseHelper`](file:///f:/flutter1/flutter1/lib/features/chat/services/chat_database_helper.dart) จัดเก็บข้อมูลออฟไลน์ถาวร ประกอบด้วย 5 ตารางหลัก:

1. **`messages`**: จัดเก็บประวัติการสนทนาทั้งสาธารณะและส่วนตัว พร้อมสถานะการส่ง (`SENDING`, `DELIVERED`, `READ`)
2. **`pending_messages`**: ฝากข้อความรอส่ง (Store-and-Forward) เมื่อโหนดปลายทางยังไม่ออนไลน์
3. **`processed_packets`**: บันทึกประวัติ Packet ID ป้องกันการส่งซ้ำข้ามเซสชัน (Replay Attack Protection)
4. **`mesh_notices`**: กระดานประกาศข่าวฉุกเฉินออฟไลน์ประจำหมู่บ้าน/พื้นที่
5. **`mule_envelopes`**: ซองจดหมายคนเดินสารรอการนำส่งข้ามพื้นที่
