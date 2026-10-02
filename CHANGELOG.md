# ประวัติการปรับปรุงแอปพลิเคชัน (Changelog)

บันทึกรายการเปลี่ยนแปลงการพัฒนาแอปพลิเคชัน **BANTAWAN** แยกย่อยตามรุ่นของซอฟต์แวร์:

## [1.5.0] - 2026-07-23 (รุ่นปรับปรุงระบบการจราจรแบบเรียลไทม์ และระบบบรรยายปฐมพยาบาล 2 ภาษา)
### เพิ่มฟังก์ชันการทำงาน (Added)
* **Bilingual First Aid TTS & Voice Guide**: รองรับระบบเสียงบรรยายขั้นตอนปฐมพยาบาล 2 ภาษา (สลับสำเนียงและเสียงพูดระหว่าง `th-TH` ภาษาไทย และ `en-US` ภาษาอังกฤษ อิงตาม Locale ของแอปพลิเคชัน)
* **Real-time Traffic Flow Layer**: ซ้อนทับเส้นสีจราจรสด (เขียว/เหลือง/แดง) จาก Longdo Tile API บนแผนที่ CartoDB Voyager เมื่อเปิดโหมด Traffic
* **3-Way Parallel POI Discovery Engine**: ขยายท่อค้นหาดึงข้อมูลพร้อมกัน 3 ช่องทาง (Longdo Tag Search + Longdo Thai Keyword Search + Overpass Race Condition)
* **High-Density Marker Rendering**: ปลดล็อกขีดจำกัดการแสดงหมุดบนแผนที่จาก 40 หมุด เพิ่มเป็น **300 หมุด** เพื่อความหนาแน่นสมจริง

### ปรับปรุง UI/UX & แก้ไขข้อบกพร่อง (Improved & Fixed)
* **Delivery ACK & Read Receipts**: เพิ่มใบยืนยันการรับส่งข้อความผ่าน Mesh Network แสดงสถานะ `⏳` (กำลังส่ง), `✓` (ส่งถึงนาย E แล้ว), และ `✓✓` (นาย E เปิดอ่านแล้ว)
* **Crypto Engine V2**: ระบบเข้ารหัส SHA-256 KDF + 16-byte Random IV + HMAC-SHA256 Anti-Tamper Signature (`ENC_V2::...`) ป้องกันการดัดแปลงข้อมูล
* **E2EE Private Direct Mesh Chat**: เพิ่มโหมดแชทส่วนตัวเข้ารหัสต้นทางถึงปลายทาง (End-to-End Encryption) รองรับการส่งแพ็กเก็ตผ่านโหนดรีเลย์ (B, C, D) โดยไม่ขึ้นข้อความบนหน้าจอเครื่องทางผ่าน มีเพียงเป้าหมาย (นาย E) เท่านั้นที่เห็นและอ่านข้อความได้
* **Profile Screen & Mesh Callsign Linkage**: เชื่อมโยงชื่อโปรไฟล์ผู้ใช้งานกับชื่ออุปกรณ์ (Device Callsign) ในระบบ Mesh Chat ออฟไลน์โดยอัตโนมัติ แสดง Badge ป้ายชื่อ **`CALLSIGN: [Name]`** สี Cyan ดีไซน์ Tactical และเพิ่ม Helper Text อธิบายการทำงานในหน้าแก้ไขข้อมูล
* **Interactive Map Search & GPS Precision Polish**: เพิ่มปุ่มลอย **"ค้นหาในบริเวณนี้"** เมื่อผู้ใช้ลากแผนที่ไปดูพิกัดอื่น, เพิ่มปุ่มสลับเปิดดูแผงคำแนะนำการเลี้ยวแบบ step-by-step บน HUD นำทาง, ปรับปรุงปุ่มล้างคำพิมพ์ `(X)` บน Search Bar ให้ตอบสนองเรียลไทม์ และเพิ่มระบบตรวจเช็กพร้อม Fallback ตำแหน่งพิกัด GPS อุปกรณ์
* **Animated Side Toolbar Reset**: แก้ไขตำแหน่งเมนูขวา (`MapControls`) ให้เช็คสถานะ `provider.showDetails` ร่วมกับ `AnimatedPositioned` เมื่อกดกากบาท (✕) ปิด Sheet เมนูขวาจะเลื่อนสไลด์กลับลงมาที่ตำแหน่งเดิม (`bottom: 120`) อย่างนุ่มนวล
* **Google Maps External Launcher**: เพิ่มปุ่มแคปซูล **`Google Maps`** บนหน้าต่างรายละเอียดสถานพยาบาล (`GoogleFacilitySheet`) สามารถแตะเปิดพิกัดเป้าหมายบนแอป Google Maps ภายนอกได้ทันที
* **Search Bar Layout Overlap Fix**: แก้ไขระยะขอบขวาของแถบค้นหาใน `google_map_header.dart` ให้เว้นระยะ 72px ป้องกันการชนกับเมนูเครื่องมือแนวตั้ง `MapControls` ด้านขวา
* **Functional Search Button & Map Pan Animation**: เปลี่ยนปุ่มโปรไฟล์รูปคนบนแถบค้นหาให้กลายเป็นปุ่มค้นหาแว่นขยาย (`Icons.search_rounded`) ที่กดค้นหาได้จริง พร้อมสั่งให้แผนที่เลื่อนไปยังพิกัดเป้าหมายที่ค้นพบทันที
* **APK GPS Location Centering Fix**: แก้ไขปัญหาสตรีมพิกัดและโฟกัสตำแหน่งบนไฟล์ APK ด้วยระบบ `getLastKnownPosition` instant fallback, ร้องขอสิทธิ์ `checkPermission`/`requestPermission` และใช้ `forceLocationManager: true` ป้องกันบริการ FusedLocation ค้าง
* **APK Compass & High-Sampling Sensors**: เพิ่มสิทธิ์ `<uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS" />` และ `<uses-feature android:name="android.hardware.sensor.compass" />` ใน `AndroidManifest.xml` พร้อมอัปเดตสตรีมเข็มทิศในแผนที่ให้รับค่าองศาและหมุนทำมุมได้อย่างถูกต้อง
* **Bilingual First Aid UI**: หน้าจอคู่มือปฐมพยาบาลแสดงผลชื่อหัวข้อ คำเตือน และขั้นตอนการช่วยเหลือสลับภาษาไทย/อังกฤษโดยอัตโนมัติ
* **Fixed Close Button & Sheet Dismissal**: แก้ไขเงื่อนไข `provider.showDetails` ใน `map_screen.dart` ทำให้ปุ่มกากบาท (✕) ทำหน้าที่พับเก็บ Sheet ได้สมบูรณ์ โดยรักษาสภาพเส้นทางนำทาง (Route Line) บนแผนที่ไว้
* **Overpass Timeout & Error Fix**: แก้ไขปัญหาสอบถามข้อมูล Overpass API ล้มเหลวด้วยการเปลี่ยนเป็นระบบ Race Condition ยิงทุก Mirror Server พร้อมกันและปรับ Timeout การรอเป็น 25 วินาที

---

## [1.0.3] - 2026-07-13 (รุ่นปรับปรุงเสถียรภาพระดับบริการและล้างตัวเตือนคอมไพเลอร์)
### เพิ่มฟังก์ชันการทำงาน (Added)
*   เพิ่มคำสั่งเริ่มต้นระบบ (`initialize`) ของปลั๊กอินส่งการแจ้งเตือนพิกัดในเครื่อง (`FlutterLocalNotificationsPlugin`) ของคลาส `NearbyService` เมื่อเริ่มระบบ เพื่อเปิดให้แจ้งเตือนข้อความ SOS และ Proximity Alert ได้จริงบน Android/iOS

### การปรับเปลี่ยน (Changed)
*   ปรับเปลี่ยนโครงสร้างการลงทะเบียน Providers ของ Singleton Services (`NearbyService`, `EmergencyToolService`, `ConnectivityService`) ไปใช้คอนสตรัคเตอร์แบบ `.value` เพื่อป้องกันปัญหาระบบ Provider เรียกทำลายทรัพยากรภายใน Singleton โดยอัตโนมัติ
*   ปรับเปลี่ยนชื่อฟังก์ชันตัวช่วย `_TacticalCircularButton` ใน `home_screen.dart` ให้เป็นตัวพิมพ์เล็กแบบ CamelCase (`_tacticalCircularButton`) ตามมาตรฐานโค้ด Dart

### การแก้ไขข้อบกพร่อง (Fixed)
*   แก้ไขข้อบกพร่องทาง lifecycle ที่เกิดจากการ dispose ทรัพยากรภายใน singleton ส่งผลให้ตัวเล่นเสียงไซเรนเตือนภัย เครื่องมือแชท และตัวจับระดับสัญญาณสามารถเปิดใช้ซ้ำได้ถาวรโดยไม่ล่ม
*   แก้ไขปัญหาการเขียนทับชื่อของอุปกรณ์ฝ่ายแชทออฟไลน์ใน Mesh Network ให้เก็บบันทึกชื่อเครื่องจริง (`endpointName`) ที่ส่งผ่านกระบวนการ handshake ตั้งแต่แรกแทนการระบุทับด้วยคำว่า `"Nearby Peer"` ตลอดเวลา
*   แก้ไขคำแจ้งเตือน `use_build_context_synchronously` เมื่อมีการเรียกใช้ BuildContext ข้ามผ่าน async gap ใน `home_screen.dart` และ `survival_tools_screen.dart` โดยการสกัดการทำงานของ ScaffoldMessenger ออกมา และหันไปใช้ `context.mounted` ในการเช็คสถานะการเกาะหน้าจอ
*   แก้ไขข้อความเตือนของลินเตอร์เกี่ยวกับตัวแปรที่ไม่ได้ใช้งาน (unused variable `paint`) ในระบบ Painter สภาพอากาศ
*   แก้ไขตัวแปรที่มีการเขียนขีดล่างซ้ำซ้อน (`unnecessary_underscores` ใน `errorBuilder`) ของรูปปฐมพยาบาลโดยระบุตัวแปรแบบเป็นคำเต็มตัวแทน
*   แก้ไขและครอบวงเล็บปีกกา `{ }` ให้กับ if-statements ในคลาสการนำทางแผนที่และ map_provider

### การเอาออก (Removed)
*   นำการนำเข้าไลบรารีที่ซ้ำซ้อน (`material.dart` ที่ทับซ้อนกับ `foundation.dart`) ออกจาก `map_provider.dart`

### ล้าสมัย (Deprecated)
*   เปลี่ยนคำสั่งทำสีโปร่งแสงเก่า `.withOpacity(...)` ไปใช้งานคำสั่งใหม่ที่ป้องกันการสูญเสียคุณภาพสีอย่าง `.withValues(alpha: ...)` ทั่วทั้งหน้าจอSOS, แชทออฟไลน์ และแถบแผนที่
*   ลบพารามิเตอร์เก่า `backgroundColor` ออกจาก `TileLayer` ของหน้าแผนที่เพื่อรองรับสเปกใน flutter_map v6.x

---

## [1.0.2] - 2026-07-04 (รุ่นแก้ไขเพื่อความเสถียรแผนที่)
### เพิ่มฟังก์ชันการทำงาน (Added)
*   เพิ่มหน้าต่างเบลออัจฉริยะ **Glassmorphic Loading Overlay** แจ้งเตือนสถานะเมื่อทำการโหลดพิกัดหรือดึงเส้นทางบนแผนที่
*   เพิ่มการแจ้งเตือนปัญหาดึงเส้นทางล้มเหลวผ่านทาง **SnackBar** แจ้งเหตุผลให้ผู้ใช้งานทราบแทนการผิดพลาดแบบเงียบ
*   เพิ่มคลาสระบบควบคุมเวลาขัดข้องในการดึงเส้นทาง (Timeout) สูงสุด 8 วินาทีป้องกันแอปหยุดชะงัก

### ปรับปรุงประสิทธิภาพ (Improved)
*   ปรับปรุงสัญญาณชีพจรตำแหน่ง (Pulsing Glow) ของโหนดสาธารณสุขให้กระพริบระยิบระยับตลอดเวลาด้วยคลาส `PulsingGlow` แบบวนซ้ำต่อเนื่อง (Infinite Loop)

---

## [1.0.1] - 2026-06-21 (รุ่นตกแต่งสไตล์ Tactical & จูนความลื่นไหล)
### เพิ่มฟังก์ชันการทำงาน (Added)
*   เพิ่มวิดเจ็ตแผงควบคุม **Device Health Dashboard** บนหน้าหลัก แสดงระดับแบตเตอรี่, สถานะ GPS และจำนวนโหนดเพื่อนบ้านในระยะบลูทูธ (Mesh nodes)
*   เพิ่มหน้าจอคู่มือปฐมพยาบาลเบื้องต้น (First Aid Guide) พร้อมคู่มือ CPR, การช่วยชีวิตจากสิ่งอุดตัน, และห้ามเลือด
*   ปรับการทำงานหน้าแชทออฟไลน์ให้สามารถคลิก "ดูบนแผนที่" จากพิกัดที่เพื่อนแชร์เพื่อกระโดดปักหมุดนำทางทันที

### ปรับปรุงประสิทธิภาพ (Improved)
*   แก้ปัญหากราฟิกฉากหลังกินทรัพยากรเครื่องโดยการนำ **`RepaintBoundary`** มาครอบ Custom Paint และ Grid เพื่อจำกัดการวาดใหม่รักษาความเร็วการเลื่อนหน้าจอระดับ 60+ FPS
*   ปรับสไตล์ของกลุ่มปุ่ม Survival Tools ให้เป็นแบบ Tactical Dark Glassmorphism ใช้นีออนส้ม/น้ำเงิน

---

## [1.0.0] - 2026-06-14 (รุ่นเปิดตัวต้นแบบแรกสุด - First Beta Ready)
### เพิ่มฟังก์ชันการทำงาน (Added)
*   พัฒนาโครงสร้างแอปหลายหน้า (Multi-screen) ด้วย Flutter และตัวจัดการสถานะ Provider
*   สร้างระบบ **SOS ด่วน** รวบรวมข้อมูลส่วนตัวทางการแพทย์ (Medical ID) และสแกนพิกัดปัจจุบันเพื่อส่งออกสายด่วนทันที
*   สร้างระบบแชทเครือข่ายออฟไลน์จำลองแบบใยแมงมุม (P2P Mesh Chat) ผ่านแพ็คเกจ `nearby_connections`
*   สร้างระบบแผนที่แบบ Offline-first ผ่านไลบรารี `flutter_map` รองรับการดาวน์โหลดแผ่นแผนที่เก็บล่วงหน้าลงฮาร์ดดิสก์
*   สร้างระบบเช็คอินตรวจจับการเคลื่อนไหวเพื่อส่ง SOS อัตโนมัติ (Safety Check-in Timer)
*   สร้างตัวชี้วัดความกดอากาศ สภาพอากาศ และระดับฝุ่น PM 2.5 ร่วมกับ Open-Meteo API
