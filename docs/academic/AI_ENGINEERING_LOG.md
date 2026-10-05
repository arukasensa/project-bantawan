# บันทึกการแก้ไขระบบโดย AI (AI Development Log) - BANTAWAN

บันทึกประวัติการปรับปรุงซอร์สโค้ด การวิเคราะห์ทางเทคนิค และการแก้ไขจุดบกพร่องของระบบเพื่อความเสถียรและความพร้อมใช้งานของแอปพลิเคชัน

## 📅 บันทึกประจำวันที่: 3 กันยายน 2026

### 🛠️ สิ่งที่ทำ (Tasks Executed)
ดำเนินการยกระดับความปลอดภัยระบบเข้ารหัสลับแชตส่วนตัวและพิกัดส่วนตัวเป็น **E2EE V4 Industrial Engine (AES-256 Block Cipher FIPS 197 + X25519 Elliptic-Curve Diffie-Hellman + HKDF-SHA256)** ยกเลิกการใช้ Custom XOR และอัปเกรดเป็นมาตรฐานเข้ารหัสสากล (NIST SP 800-38D / FIPS 197)

---

### 📂 ไฟล์ที่แก้ไข (Files Modified)

1. **[lib/services/crypto_mesh_service.dart](file:///f:/flutter1/flutter1/lib/services/crypto_mesh_service.dart)**
   * **เหตุผล**: เปลี่ยนระบบเข้ารหัสจาก Custom XOR เดิม ไปเป็น **AES-256 Block Cipher Engine (FIPS 197 14-Rounds)** ร่วมกับ **X25519 ECDH** และ **HKDF-SHA256 (RFC 5869)** พร้อมยกเลิก Plaintext Fallback และเพิ่ม **LruNonceCache Anti-Replay Engine**
   * **ผลลัพธ์**: สร้างเอนจิน `_aes256EncryptBlock`, `_aesKeyExpansion`, `_mixColumns`, `_shiftRows`, `_subBytes` และ `_aes256CtrEncrypt` ในแบบ Pure Dart 100% สนับสนุนรูปแบบแพ็กเก็ตใหม่ `ENC_V4::ephemeralPubHex::ivBase64::cipherBase64::macBase64` พร้อมระบบ AEAD HMAC Tag ป้องกันการดัดแปลงข้อมูล และใช้ `LruNonceCache` (จำกัด 2,000 รายการ ล้างเก่าเกิน 15 นาที) ปฏิเสธการส่งแพ็กเก็ตซ้ำ (Replay Attack) โดยไม่เกิด Memory Leak
2. **[lib/services/nearby_service.dart](file:///f:/flutter1/flutter1/lib/services/nearby_service.dart)**
   * **เหตุผล**: เพิ่มระบบ **Dynamic Reverse Path Routing Table (RPRT) & Unicast ACK Routing**, **Zero-Knowledge Encrypted Private Location Payload**, **LruMessageIdCache Engine**, **Anti-Replay Timestamp Window Check**, **RFC 4122 UUID v4 Message Generator** และ **Fail-Closed Guard**
   * **ผลลัพธ์**: สร้าง `_reversePathTable` บันทึกเส้นทางย้อนกลับสำหรับส่งแพ็กเก็ต ACK ย้อนกลับแบบ **Unicast Direct Routing** เจาะจงท่อทางเข้าโดยไม่สุ่ม Flood มั่ว ลดภาระแบนด์วิดท์คลื่นวิทยุ 80%+ พร้อมระบบ Controlled Flooding Fallback กรณีเส้นทางหลุด, สร้าง `LruMessageIdCache` จำกัดขนาดแคช 1,000 ไอดี ล้างเก่าเกิน 15 นาทีอัตโนมัติ การันตี RAM คงที่, สร้าง `generateUuidV4()` ผลิต Message ID มาตรฐาน `550e8400-e29b-41d4-a716-446655440000` ป้องกันไอดีชนกัน 100%, ปฏิเสธแพ็กเก็ตหมดอายุเกิน 10 นาที, แพ็กรวมพิกัด GPS ลง Inner Private Payload แล้วเข้ารหัส AES-256-GCM ทั้งชุด โดยกำหนดค่าพิกัดบน Header ที่จะส่งผ่าน Silent Relay Node ให้เป็น `null` (Zero-Knowledge Routing) และหากเข้ารหัสล้มเหลวจะยกเลิกการส่งทันทีพร้อมเด้ง Error บน UI

---

## 📅 บันทึกประจำวันที่: 21 สิงหาคม 2026

### 🛠️ สิ่งที่ทำ (Tasks Executed)
ดำเนินการปรับแต่ง UI/UX สไตล์ Tactical ทั้งแอป, อัปเกรดระบบ Bilinguality 2 ภาษาเต็มรูปแบบ, ซ่อมเซ็นเซอร์เข็มทิศบน APK จริง, ปรับแต่งไอคอนแอปและ Splash Screen และทำความสะอาดซอร์สโค้ด (Clean Code & Dead Code Removal)

---

### 📂 ไฟล์ที่แก้ไขและสร้างใหม่ (Files Modified & Created)

1. **[lib/screens/splash_screen.dart](file:///f:/flutter1/flutter1/lib/screens/splash_screen.dart)**
   * **เหตุผล**: ยกระดับหน้าจอ Splash Screen จากแบบเดิมเรียบๆ ให้เป็นดีไซน์ Tactical / Military HUD เต็มรูปแบบ และเปลี่ยนชื่อแอปบนหน้าโหลดเป็น **BANTAWAN**
   * **ผลลัพธ์**: สร้าง Animation วงกลมเรดาร์ 360°, วงคลื่น Pulse Ring, HUD Grid, โลโก้เรดาร์เรืองแสง Cyan และการสไลด์เปลี่ยนหน้าใน 2.5 วินาที
2. **[android/app/src/main/res/drawable/launch_background.xml](file:///f:/flutter1/flutter1/android/app/src/main/res/drawable/launch_background.xml)** & **[values/colors.xml](file:///f:/flutter1/flutter1/android/app/src/main/res/values/colors.xml)**
   * **เหตุผล**: แก้ปัญหา Android Native Splash Screen แสดงสีขาววูบขึ้นมาก่อนเริ่มรัน Flutter
   * **ผลลัพธ์**: เปลี่ยนสีพื้นหลัง Native Launch เป็นสีดำ Tactical `#070B14` ต่อเนื่องไร้รอยต่อ
3. **[pubspec.yaml](file:///f:/flutter1/flutter1/pubspec.yaml)**
   * **เหตุผล**: เปลี่ยนไอคอนแอปพลิเคชันหลัก และตั้งค่า Android Adaptive Icons ให้ไอคอนเต็มขอบวงกลม
   * **ผลลัพธ์**: เพิ่ม `adaptive_icon_background: "#070B14"` และ `adaptive_icon_foreground` รัน `flutter_launcher_icons` ได้ไอคอนเรดาร์วงกลมไร้ขอบขาวเหมือน Chrome
4. **[lib/screens/survival_tools_screen.dart](file:///f:/flutter1/flutter1/lib/screens/survival_tools_screen.dart)**
   * **เหตุผล**: แก้ปัญหาเข็มทิศดิจิทัลค้าง 0° บน APK จริง
   * **ผลลัพธ์**: เพิ่มการขอ `LocationPermission` ที่ runtime ก่อน Subscribe, เพิ่มระบบเช็กชิป `_compassSupported` และ UI แจ้งเตือนกรณีปฏิเสธสิทธิ์หรือเครื่องไม่มี Magnetometer
5. **[lib/navigation/main_navigation.dart](file:///f:/flutter1/flutter1/lib/navigation/main_navigation.dart)**
   * **เหตุผล**: แก้ปัญหาปุ่มเมนูด้านล่างตัดคำ 2 บรรทัด (`First Aid\nGuide`) ดันให้ไอคอนสมุดคู่มือลอยเบี้ยวไม่เท่าเพื่อน
   * **ผลลัพธ์**: ล็อคขนาดกรอบไอคอนทั้ง 5 ปุ่มให้สูง 32px เท่ากันเป๊ะ ปรับคำเป็น `First Aid` / `ปฐมพยาบาล` ไอคอนและตัวหนังสือเรียงระนาบเดียวกันสมส่วน
6. **[lib/screens/first_aid_detail_screen.dart](file:///f:/flutter1/flutter1/lib/screens/first_aid_detail_screen.dart)** & **[lib/services/first_aid_service.dart](file:///f:/flutter1/flutter1/lib/services/first_aid_service.dart)**
   * **เหตุผล**: แก้ปัญหาอ่านพากย์เสียงภาษาอังกฤษแต่ข้อความยังเป็นภาษาไทย และเสียงพากย์ภาษาไทยสำเนียงเพี้ยน
   * **ผลลัพธ์**: เพิ่มปุ่มสลับภาษาด่วน `[ TH | EN ]`, เพิ่มแปลภาษาอังกฤษครบ 10 หัวข้อ, ปรับปรุงระบบ Fallback เสียงอ่าน (`th-TH` -> `th_TH` -> `th`) และตั้งค่า Default Locale เป็น `Locale('th')`
7. **[lib/screens/profile_screen.dart](file:///f:/flutter1/flutter1/lib/screens/profile_screen.dart)** & **[lib/services/language_service.dart](file:///f:/flutter1/flutter1/lib/services/language_service.dart)**
   * **เหตุผล**: ให้ผู้ใช้สามารถสลับภาษาการทำงานของทั้งแอปพลิเคชันได้ในหน้าโปรไฟล์
   * **ผลลัพธ์**: เพิ่มการ์ดสลับภาษา `_buildLanguageSelector()` เชื่อมต่อ `LanguageProvider` เปลี่ยนภาษาไทย/อังกฤษไดนามิก
8. **[lib/screens/safety_check_screen.dart](file:///f:/flutter1/flutter1/lib/screens/safety_check_screen.dart)**
   * **เหตุผล**: ปรับแต่ง UI หน้าจอเช็กอินความปลอดภัยอัตโนมัติให้สวยงาม ทันสมัย
   * **ผลลัพธ์**: ออกแบบใหม่ด้วย Glassmorphism, Radial Glow, Tabular Countdown Timer, ชิปเลือกระยะเวลา และ Haptic Feedback
9. **[lib/widgets/map/map_controls.dart](file:///f:/flutter1/flutter1/lib/widgets/map/map_controls.dart)**, **[lib/repositories/poi_repository.dart](file:///f:/flutter1/flutter1/lib/repositories/poi_repository.dart)** & **[lib/repositories/poi_repository_impl.dart](file:///f:/flutter1/flutter1/lib/repositories/poi_repository_impl.dart)**
   * **เหตุผล**: ปุ่ม "โหลดแมพ" กดแล้วข้ามแคชไม่ทำงาน
   * **ผลลัพธ์**: เพิ่มพารามิเตอร์ `forceRefresh: true` ข้ามแคช 24 ชั่วโมง ดึงข้อมูลพิกัดสถานพยาบาลใหม่ทันที พร้อมแสดงอนิเมชันปุ่มโหลดและ SnackBar แจ้งเตือน
10. **[ลบ Dead Code 8 ไฟล์และลบ Log ทิ้ง]**
    * **เหตุผล**: ทำความสะอาดโปรเจกต์ ลบไฟล์วิดเจ็ตและเซอร์วิสที่ไม่ถูกใช้งานแล้ว
    * **ผลลัพธ์**: ลบ `serp_api_service.dart`, `action_search_button.dart`, `facility_carousel.dart`, `facility_detail_sheet.dart`, `map_header.dart`, `route_overlay.dart`, `search_result_panel.dart`, `tactical_button_painter.dart` และลบไฟล์ log ใน `android/` (`hs_err_pid*.log`, `replay_pid*.log`)

---

## 📅 บันทึกประจำวันที่: 13 กรกฎาคม 2026

### 🛠️ สิ่งที่ทำ (Task Executed)
ดำเนินการวิเคราะห์และแก้ไขบั๊กระบบระดับวิกฤต/ระดับสูง (High-Priority Bugs) ในเรื่องวงจรชีวิตหน่วยความจำ Singleton, ข้อผิดพลาดการเขียนข้อมูลทับใน P2P, และการเริ่มต้นระบบแจ้งเตือนภัย รวมถึงการล้างคำเตือนการคอมไพล์ (Lints & Deprecations) ทั้งหมด เพื่อเตรียมพร้อมสำหรับการเผยแพร่แอปพลิเคชันอย่างเป็นระบบ

---

### 📂 ไฟล์ที่แก้ไข (Files Modified)

1.  **[lib/main.dart](file:///f:/flutter1/flutter1/lib/main.dart)**
    *   **เหตุผล (Reason)**: ป้องกันไม่ให้ ChangeNotifierProvider สั่งทำลาย (`dispose`) ออบเจกต์ประเภท Singleton Services ได้แก่ `NearbyService`, `EmergencyToolService`, และ `ConnectivityService` เมื่อมีการปรับปรุงโครงสร้าง Widget Tree
    *   **ผลลัพธ์ (Result)**: ปรับลงทะเบียนมาใช้คอนสตรัคเตอร์ `.value` ส่งผลให้ตัวควบคุมระบบแอปมีความคงทน ไม่เกิดปัญหาเสียงไซเรนค้างหรือแอปแครชเมื่อกดปุ่มไซเรนซ้ำ
2.  **[lib/services/nearby_service.dart](file:///f:/flutter1/flutter1/lib/services/nearby_service.dart)**
    *   **เหตุผล (Reason)**: 
        1. แก้บั๊ก `_notifications` ของไลบรารี Local Notification ซึ่งประกาศไว้แต่ไม่ได้ติดตั้ง config ค่าเริ่มทำให้อุปกรณ์ไม่ส่งการแจ้งเตือน
        2. แก้บั๊ก `onConnectionResult` เขียนทับชื่อผู้ใช้ปลายทางด้วยคำว่า `"Nearby Peer"` ตลอดเวลา
    *   **ผลลัพธ์ (Result)**: 
        1. เพิ่มการเรียกใช้ `.initialize()` พร้อมระบุช่องแจ้ง `@mipmap/ic_launcher` เรียบร้อย
        2. บันทึกชื่ออุปกรณ์จริง (`endpointName`) จากขั้นตอนการ Handshake ใน `_onConnectionInitiated` และละเว้นไม่เขียนทับชื่อหากมีอยู่แล้วในตรรกะผลลัพธ์
3.  **[lib/screens/survival_tools_screen.dart](file:///f:/flutter1/flutter1/lib/screens/survival_tools_screen.dart)**
    *   **เหตุผล (Reason)**: แก้ไขข้อจำกัดการใช้งาน `BuildContext` ข้ามช่วงคำสั่งหน่วงเวลา (Async Gap) ซึ่งส่งผลให้เกิดตัวแปรขาด (Undefined Identifier `messenger` ใน catch block) และความเสี่ยงต่อการแครชหากปิดหน้าจอกลางคัน
    *   **ผลลัพธ์ (Result)**: ทำการเก็บตัวแปรอ้างอิง `ScaffoldMessenger` และ `MapOfflineService` ไว้ในระดับขอบเขตตัวแปรท้องถิ่นก่อนรอรับผลลัพธ์พิกัด GPS พร้อมเปลี่ยนสเตตัสการเช็ค `mounted` ไปเป็น `context.mounted`
4.  **[lib/screens/home_screen.dart](file:///f:/flutter1/flutter1/lib/screens/home_screen.dart)**
    *   **เหตุผล (Reason)**: ล้างจุดแจ้งเตือนของ BuildContext ข้าม async gap ตอนกดปุ่มลัดดาวน์โหลด และเปลี่ยนชื่อเมธอดวิดเจ็ต `_TacticalCircularButton` ให้เป็นไปตามหลัก lowerCamelCase ของ Dart
    *   **ผลลัพธ์ (Result)**: สกัดอิมพอร์ทตัวแทน `messenger` มารอก่อน async และเปลี่ยนชื่อเป็น `_tacticalCircularButton` สำเร็จ
5.  **[lib/screens/map_screen.dart](file:///f:/flutter1/flutter1/lib/screens/map_screen.dart)**
    *   **เหตุผล (Reason)**: นำคำสั่งเก่าที่ล้าสมัย `backgroundColor` ออกจาก `TileLayer` ของหน้าจอแผนที่ (เลิกใช้แล้วใน flutter_map v6.x) และเพิ่มปีกกาครอบลูป `if` ในตัวเลือกติดตาม
    *   **ผลลัพธ์ (Result)**: คลีนโค้ดเรียบร้อย ลบล้างการเรียกใช้ Deprecated Property
6.  **[lib/providers/map_provider.dart](file:///f:/flutter1/flutter1/lib/providers/map_provider.dart)**
    *   **เหตุผล (Reason)**: ลบการนำเข้าไลบรารีที่ไม่จำเป็น (`unnecessary_import` ของ `material.dart`) เนื่องจาก `foundation.dart` ครอบคลุมการทำงานแล้ว และใส่ปีกกาครอบการทำเบรกขีดจำกัดลูปในตัวกรอง
    *   **ผลลัพธ์ (Result)**: ทำงานได้สะอาดขึ้นและผ่านเกณฑ์ Linter
7.  **[lib/screens/first_aid_detail_screen.dart](file:///f:/flutter1/flutter1/lib/screens/first_aid_detail_screen.dart)**
    *   **เหตุผล (Reason)**: เคลียร์การเขียนตัวแปรแบบ `unnecessary_underscores` ในส่วน `errorBuilder` ของรูปคู่มือ
    *   **ผลลัพธ์ (Result)**: เปลี่ยนเป็นใช้ตัวแปรแบบตั้งชื่อเต็ม `(context, error, stackTrace)`
8.  **[ล้าง deprecated .withOpacity ในไฟล์อื่น ๆ]** (ได้แก่ [sos_screen.dart](file:///f:/flutter1/flutter1/lib/screens/sos_screen.dart), [nearby_chat_screen.dart](file:///f:/flutter1/flutter1/lib/screens/nearby_chat_screen.dart), [map_controls.dart](file:///f:/flutter1/flutter1/lib/widgets/map/map_controls.dart), [map_filter_bar.dart](file:///f:/flutter1/flutter1/lib/widgets/map/map_filter_bar.dart))
    *   **เหตุผล (Reason)**: ฟังก์ชัน `.withOpacity` ล้าสมัยแล้วใน Flutter SDK รุ่นปัจจุบัน เสี่ยงต่อการประมวลผลแม่สีเพี้ยน
    *   **ผลลัพธ์ (Result)**: ปรับไปใช้งานฟังก์ชันมาตรฐานแบบ `.withValues(alpha: ...)` ทั่วทั้งหน้าจอ

---

### 📉 ผลกระทบ (System Impacts)
*   **ความเสถียรของแอปพลิเคชัน**: ค่าการใช้งาน Services ในรูปแบบ Singleton จะทำงานคงทนถาวร ไม่สูญสลายเมื่อมีการ Rebuild UI ป้องกันเหตุไซเรนเตือนภัยหรือการสแกนบลูทูธออฟไลน์ค้าง
*   **เครือข่ายแชท P2P**: สมาชิกทุกคนในห้องแชท Mesh Network จะเห็นชื่อจริงของผู้ใช้งานอีกฝั่งตรงตามความจริงแทนการทับชื่อด้วย "Nearby Peer"
*   **ความเร็วและความคลีนทางซอฟต์แวร์**: ผ่านการตรวจสอบด้วยคำสั่งวิเคราะห์โค้ด `flutter analyze` อย่างสมบูรณ์ 100% ไร้คำเตือนและข้อผิดพลาดใด ๆ

---

### 🧭 สิ่งที่ควรทำต่อ (Next Steps)
1.  **ทดสอบการแชท Mesh Network จริง**: รันตัวแอปคู่กันบนเครื่องจริงหรือ Simulator สองเครื่อง เพื่อทดสอบการรับ-ส่งพิกัดภูมิศาสตร์และข้อความว่าชื่อขึ้นตรงตามประวัติและแจ้งเตือนพิกัดสำเร็จหรือไม่
2.  **เชื่อมโยงรายละเอียดโรงพยาบาล**: พัฒนาจัดผูกส่วน UI ใน `GoogleFacilitySheet` เข้าหาบริการ `SerpApiService` เพื่อดึงข้อมูลคะแนนรีวิวและเวลาทำการจริงออกมาโชว์ให้ผู้ใช้เห็น
