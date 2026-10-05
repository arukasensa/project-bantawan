# BANTAWAN - Map & Navigation Module Documentation

**มอดูล**: ระบบแผนที่นำทางและค้นหาพิกัดสถานพยาบาลยุทธศาสตร์  
**ไฟล์หลัก**: `lib/features/map/screens/map_screen.dart`, `lib/providers/map_provider.dart`, `lib/features/map/services/map_offline_service.dart`, `lib/features/map/widgets/`  

---

## 1. ภาพรวมของมอดูล (Module Overview)

มอดูลแผนที่ของ **BANTAWAN** ออกแบบมาเพื่อให้ผู้ประสบภัยและทีมกู้ภัยสามารถระบุตำแหน่ง ค้นหาจุดพยาบาล และคำนวณเส้นทางนำทางได้ทั้งในภาวะปกติและภาวะอินเทอร์เน็ตล่ม โดยทำงานร่วมกับเอ็นจิน `flutter_map` (OpenStreetMap Vector/Raster Renderer) พร้อมระบบแคชแผ่นแผนที่ออฟไลน์ในตัว

---

## 2. กลยุทธ์การเปลี่ยนชั้นแผนที่ (Tile Layer Strategy)

ระบบรองรับการสลับรูปแบบแผนที่ฐาน (Base Map Tiles) 3 รูปแบบตามสถานการณ์:

```text
               ┌─────────────────────────────────────────┐
               │           Map Style Selector            │
               └────────────────────┬────────────────────┘
                                     │
         ┌──────────────────────────┼──────────────────────────┐
         ▼                          ▼                          ▼
    'dark' Mode               'satellite' Mode           'traffic' Mode
OSM Standard / Offline Cache   ArcGIS World Imagery     OSM Standard Map
(แผนที่ออฟไลน์จากเครื่อง)     (ภาพถ่ายดาวเทียมความละเอียดสูง)  + Longdo Real-time Traffic Overlay
```

| สไตล์แผนที่ | แหล่งข้อมูล | วัตถุประสงค์การใช้งาน |
|---|---|---|
| **Dark / Standard Mode** | `OfflineFallbackTileProvider`<br>(แคชในเครื่อง `${directory.path}/map_tiles/{z}/{x}/{y}.png` สลับเป็น OSM Network) | แสดงผลได้ 100% แม้ไร้เน็ต สบายตา ถนอมแบตเตอรี่ |
| **Satellite Mode** | `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}` | ภาพถ่ายดาวเทียมสำหรับดูสภาพภูมิประเทศจริง |
| **Traffic Mode** | `https://tile.openstreetmap.org/{z}/{x}/{y}.png`<br>+ `https://ms.longdo.com/mmmap/tile.php?zoom={z}&x={x}&y={y}&key=...&layer=traffic` | แผนที่ซ้อนทับด้วยเส้นสีการจราจรเรียลไทม์ (เขียว/เหลือง/แดง) |

### 2.1 ระบบแสดงผลแผนที่ออฟไลน์อัตโนมัติ (OfflineFallbackTileProvider Engine)
* **กลไกการทำงาน**:
  1. ตัว Provider จะค้นหาว่ามีไฟล์ไทล์พิกัด `(z, x, y)` เก็บอยู่ในเครื่องจากที่เคยดาวน์โหลดไว้ผ่าน `MapOfflineService` หรือไม่
  2. **กรณีมีไฟล์**: โหลดภาพจาก Local Disk ด้วย `FileImage` ทันที 0ms ไร้เน็ต 100%
  3. **กรณีไม่มีไฟล์**: สลับไปดึงภาพจาก OpenStreetMap ผ่าน `NetworkImage` อัตโนมัติเมื่อมีสัญญาณอินเทอร์เน็ต

---

## 3. ท่อลำเลียงข้อมูลพิกัด (POI Data Pipeline)

การดึงพิกัดโรงพยาบาล คลินิก และร้านขายยา ทำงานผ่าน `PoiRepositoryImpl` ด้วยระบบ 3-Way Parallel Fetching (ดึงข้อมูล 3 ช่องทางพร้อมกัน) และระบบแคช:

```text
                                 [ getNearbyFacilities() ]
                                             │
                                             ▼
                                 มีสัญญาณเน็ตหรือไม่?
                                             │
                       ┌─────────────────────┴─────────────────────┐
                    มีเน็ต                                       ไม่มีเน็ต
                       │                                           │
                       ▼                                           ▼
          แคชยังไม่หมดอายุ (ไม่เกิน 24 ชม.)?                  ดึงพิกัดจากเครื่อง
                       │                                    (PoiCacheService)
             ┌─────────┴─────────┐                                 │
          ยังไม่หมดอายุ         หมดอายุ                              │
             │                   │                                 │
             ▼                   ▼                                 ▼
      ดึงจากแคชในเครื่อง    ยิง 3 API คู่ขนาน                  กรองตามรัศมี & ประเภท
      (ประหยัด Data)       ├──► Longdo Search API (Tag Search)     │
                           ├──► Longdo Search API (Thai Keywords)  │
                           └──► OSM Overpass (Race Condition Mirrors)
                                 │                                 │
                                 ▼                                 ▼
                          บันทึกอัปเดตลงแคช ────────────────► แสดงผลบนแผนที่ (สูงสุด 300 จุด)
```

### 3.1 การขยายขีดความสามารถการค้นหา (POI Expansion)
- **Longdo Tag + Thai Keyword**: ค้นหาด้วยแท็กครอบคลุม (`hospital`, `clinic`, `pharmacy`, `health_post`, `nursing_home`, `dispensary`) ร่วมกับคีย์เวิร์ดภาษาไทย (`โรงพยาบาล`, `คลินิก`, `อนามัย`, `สุขศาลา`, `ร้านขายยา`) เพื่อดักสถานที่ที่ลืมระบุแท็ก
- **Overpass Race Condition**: ยิงขอข้อมูลจาก Overpass Mirror Servers ทุกตัวพร้อมกัน (`Future.wait`) ตัวไหนตอบกลับเร็วสุดนำมาใช้งานทันที ป้องกันปัญหา Timeout
- **เพิ่มขีดจำกัดหมุด**: ขยายจำนวนหมุดที่เรนเดอร์สูงสุดจาก 40 หมุดขึ้นเป็น **300 หมุด** เพื่อความหนาแน่นและสมจริง

---

## 4. ระบบคำนวณเส้นทางนำทาง (Routing Engine)

ระบบนำทางบริหารโดย `RoutingRepositoryImpl` ซึ่งรองรับ 2 สภาวะ:

### 4.1 โหมดออนไลน์ (OSRM Driving Engine)
- **API Endpoint**: `https://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2}`
- **ผลลัพธ์**: คืนค่า Polyline แบบบีบอัด นำมาถอดรหัสผ่าน `PolylinePoints.decodePolyline()` เพื่อวาดเส้นทางนีออนเรืองแสงซ้อนทับบนแผนที่ พร้อมเวลาคำนวณการขับขี่แบบเรียลไทม์

### 4.2 โหมดออฟไลน์ (Direct-Line Bearing Fallback)
- **หลักการ**: เมื่อไม่มีสัญญาณเน็ต ระบบจะคำนวณระยะห่างแนวตรงระหว่างพิกัดผู้ใช้กับเป้าหมายด้วยสูตร **Haversine Formula**
- **เวลาเดินทาง (ETA)**: คำนวณประเมินเวลาเดินทางจากการเดินเท้าด้วยความเร็วเฉลี่ย 5 กม./ชม. (`minutes = (distanceKm / 5.0 * 60)`)
- **ผลลัพธ์**: วาดเส้นนำร่องแนวตรงเพื่อชี้ทิศทางเป้าหมายให้ผู้ใช้ไม่หลงทิศ

---

## 5. การบริหารจัดการแคชและความถูกต้อง (Cache Management & Eviction)

ระบบใช้องค์ประกอบ `CacheMetadata` ใน `PoiCacheService` เพื่อควบคุมคุณภาพข้อมูล:

```dart
class CacheMetadata {
  final DateTime lastUpdated;
  final double latitude;
  final double longitude;
  final double radiusKm;
}
```

1. **Cache Expiration Check (`isCacheValid`)**: หากพิกัดศูนย์กลางเดิมอยู่ในระยะ และดาวน์โหลดมาไม่เกิน **24 ชั่วโมง** ระบบจะไม่ยิง API ซ้ำซ้อน
2. **Automated Cache Eviction**: ทุกครั้งที่มีการบันทึกแคชใหม่ ระบบจะตรวจสอบและลบประวัติแคชที่เก่าเกิน **7 วัน** ทิ้งทันที เพื่อป้องกันขยะสะสมในดิสก์

---

## 6. รายละเอียด UI/UX แผ่นรายละเอียดสถานที่ (GoogleFacilitySheet)

- **ปุ่มกากบาทคงที่ (Fixed Close Button)**: ออกแบบโครงสร้างแบบ `Stack` ยึดตำแหน่งปุ่มกากบาท (✕) ไว้ที่มุมขวาบนอย่างถาวร ไม่เลื่อนหายเมื่อผู้ใช้เลื่อนลงอ่านข้อมูล
- **รักษาสภาพเส้นทาง (Keep Route on Dismiss)**: เมื่อกดปุ่มกากบาท (✕) ระบบจะทำการซ่อนเฉพาะตัว Sheet (`setShowDetails(false)`) โดยไม่ล้างเส้นทางนำทางหรือสถานที่ที่เลือกไว้
- **ปุ่มสิ้นสุดนำทาง (Stop Navigation)**: ปุ่มแคปซูลสีแดงแยกต่างหากสำหรับล้างเส้นทาง (`clearRoute()`) และรีเซ็ตสถานที่เมื่อต้องการหยุดนำทางจริงๆ
