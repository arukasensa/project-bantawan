# BANTAWAN - Map & Navigation Module Documentation

> เอกสารฉบับนี้จัดเก็บอย่างเป็นทางการในโฟลเดอร์ **[`docs/MAP_MODULE.md`](file:///f:/flutter1/flutter1/docs/MAP_MODULE.md)**

---

## 1. ภาพรวมมอดูลแผนที่

มอดูลแผนที่ของ **BANTAWAN** ออกแบบมาเพื่อให้ผู้ประสบภัยและทีมกู้ภัยสามารถระบุตำแหน่ง ค้นหาจุดพยาบาล และคำนวณเส้นทางนำทางได้ทั้งในภาวะปกติและภาวะอินเทอร์เน็ตล่ม โดยทำงานร่วมกับเอ็นจิน `flutter_map`

---

## 2. ชั้นแผนที่ 3 สไตล์ (Tile Layer Strategy)

- **Dark Mode**: CartoDB Dark Matter (`https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png`)
- **Satellite Mode**: ArcGIS World Imagery (`https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}`)
- **Traffic Mode**: CartoDB Voyager Map + Longdo Real-time Traffic Flow Tile Overlay (`https://ms.longdo.com/mmmap/tile.php?zoom={z}&x={x}&y={y}&key=...&proj=epsg3857&HD=1&layer=traffic`)

---

## 3. ท่อลำเลียงข้อมูลพิกัด (POI Pipeline) และแคช

- **ออนไลน์**: ดึงข้อมูล 3 ทางขนานกัน (**Longdo Tag Search** + **Longdo Thai Keyword Search** + **OSM Overpass Race Condition**)
- **จำนวนหมุดสูงสุด**: ขยายการแสดงผลเป็น **300 หมุด** เพื่อความหนาแน่นและครอบคลุม
- **ออฟไลน์**: ดึงจาก **PoiCacheService** ตามพิกัดและรัศมี
- **Cache Metadata**: ตรวจสอบอายุแคชไม่เกิน 24 ชั่วโมง และลบแคชเก่าเกิน 7 วัน

---

## 4. เอ็นจินนำทาง (Routing Engine)

- **ออนไลน์**: OSRM Driving Polyline API
- **ออฟไลน์**: Direct-Line Bearing Navigation พร้อมคำนวณเวลาเดินเท้า 5 กม./ชม.

---

## 5. แผ่นรายละเอียดสถานที่ (GoogleFacilitySheet UX)

- **ปุ่มกากบาทคงที่ (Fixed Close Button)**: ปุ่ม ✕ อยู่ตำแหน่งคงที่มุมขวาบน ไม่เลื่อนตามเนื้อหา
- **ปิดแบบรักษาสภาพเส้นทาง**: กด ✕ เพื่อซ่อน Sheet โดยไม่ล้างเส้นทางนำทาง
- **ยกเลิกนำทาง**: ปุ่มแคปซูลสีแดง "สิ้นสุดนำทาง" แยกต่างหากเพื่อล้างเส้นทางเมื่อต้องการ

*ดูเอกสารฉบับสมบูรณ์ที่ [docs/MAP_MODULE.md](file:///f:/flutter1/flutter1/docs/MAP_MODULE.md)*
