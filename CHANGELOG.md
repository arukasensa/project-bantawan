# BANTAWAN - Change Log & Version History

เอกสารบันทึกประวัติการเปลี่ยนแปลงและการอัปเดตระบบของโครงการ **BANTAWAN**

## [1.8.0] - 2026-10-10

### 🌐 100% Full Bilingual Localization Parity (TH / EN)
- **Emergency Contact Screen (`EmergencyContactScreen`)**: ปรับปรุงหน้าจัดการรายชื่อผู้ติดต่อฉุกเฉินส่วนตัวเป็น 2 ภาษาอย่างสมบูรณ์ รองรับหมวดหมู่ความสัมพันธ์ (Family, Partner, Relative, Friend, Colleague, Other), แบบฟอร์มเพิ่ม/แก้ไขรายชื่อ, กล่องยืนยันการลบรายชื่อ, ข้อความสถานะ และเทมเพลต SMS ส่งพิกัดดาวเทียม
- **SOS Emergency Command Screen (`SosScreen`)**: ปรับปรุงข้อความแนะนำการกดค้าง (Hold Hints), ป้ายสถานะบนปุ่มส่งฉุกเฉิน, กล่องข้อความแจ้งเตือนข้อผิดพลาด (Error Dialogs) และเทมเพลตข้อความ SMS ฉุกเฉินแบบสองภาษาตามสถานะภาษาที่ผู้ใช้เลือกในแอปพลิเคชัน
- **Safety Check-in Background Service (`SafetyCheckService`)**: เชื่อมต่อการแจ้งเตือนสถานะเฝ้าระวังบนแถบแจ้งเตือน (Ongoing Status Notification), การแจ้งเตือนระยะวิกฤต (Critical Warning Phase Notification) และข้อความขอความช่วยเหลืออัตโนมัติ (Auto Check-in SMS) ให้ดึงค่าภาษาล่าสุดจาก `SharedPreferences` มาส่งข้อความภาษาไทยหรืออังกฤษอย่างถูกต้อง
- **ARB Parity Automated Testing**: ผ่านชุดทดสอบ `localization_coverage_test.dart` และ `language_provider_test.dart` 100% Parity

### 📻 Tactical Mesh Discovery & Connection Symmetry Optimization
- **Symmetric Endpoint Registration Fix**: แก้ไขเงื่อนไขใน `NearbyService._initiateConnection` ที่คัดกรองชื่อซ้ำผิดพลาด (ขัดขวางเครื่องที่ใช้ชื่อเริ่มต้น `Survivor`) ทำให้โหนดทั้ง 2 ฝั่งลงทะเบียน Endpoint และแสดงจำนวนโหนดที่เชื่อมต่ออย่างถูกต้องสมมาตร (Symmetric Direct Peer Registration)
- **Round-2 Handshake & Heartbeat Ping Burst**: เพิ่มกระบวนการยิง Handshake ยืนยันสองทางและ Ping Probe ทันทีที่เชื่อมต่อเสร็จสมบูรณ์ เพื่อยืนยันสถานะการเชื่อมต่อระหว่างโหนดค้นพบ (Discoverer) และโหนดโฆษณา (Advertiser)
- **Live Connected Node Subtitle**: ปรับปรุงหน้าจอ Survival Tools ให้แสดงผลจำนวนโหนดที่เชื่อมต่ออยู่จริงแบบเรียลไทม์ (`เชื่อมต่อแล้ว X โหนด • กำลังสแกนหาโหนดเพิ่ม`)

### 🎨 Tactical Slate Dark Theme Harmonization (Home Screen)
- **Emergency Hotline Cards Redesign (`_EmergencyHotlineCard`)**: ปรับดีไซน์บัตรสายด่วนฉุกเฉินบนหน้า Home จากสไตล์ Cyberpunk Neon เรืองแสง มาเป็น **Tactical Slate Dark (`#1E293B`)** ที่สุขุม สบายตา ลดแสงสะท้อนนีออนกวนสายตา เพิ่มความคมชัดและอ่านง่ายของตัวเลขฉุกเฉิน
- **Interactive Service Cards Redesign (`_InteractiveGlassCard`)**: เปลี่ยนจากการ์ดฝ้าขาวเดิม (`Colors.white`) มาเป็น Dark Slate Frosted Glass ให้เข้าธีม Tactical กับส่วนอื่นๆ ของหน้าจอ
- **Medical ID & ICE Mini Card Redesign**: ปรับปรุงการ์ดข้อมูลทางการแพทย์ ICE ID แสดงไอคอนเวชระเบียน กรุ๊ปเลือด และสถานะแจ้งเตือนประวัติแพ้ยา/โรคประจำตัวอย่างชัดเจน ควบคู่กับการ์ดโรงพยาบาลใกล้เคียงที่สมดุลกัน

---

## [1.7.0] - 2026-09-03

### 🛡️ Critical Security & Cryptography Upgrade
- **E2EE V4 Industrial Engine (X25519 ECDH + HKDF-SHA256 + AES-256 FIPS 197)**: อัปเกรดเอนจินเข้ารหัสเป็นมาตรฐานอุตสาหกรรม **AES-256 Block Cipher Engine (FIPS 197 14-Rounds)** แทนระบบ Custom XOR เดิม ร่วมกับการแลกเปลี่ยนคีย์ด้วย **Curve25519 (X25519 ECDH)** และ **HKDF-SHA256 (RFC 5869)**
- **NIST Standard AEAD Integrity Protection**: ตรวจสอบความถูกต้องและป้องกันการดัดแปลงข้อมูลด้วย HMAC-SHA256 AEAD Tag over 96-bit Nonce/IV + AES-256 Ciphertext (`ENC_V4::ephemeralPubHex::iv::aesCipher::mac`)
- **Ephemeral-Static Perfect Forward Secrecy**: สุ่มสร้าง Ephemeral Key Pair สำหรับการส่งข้อความส่วนตัว ป้องกันโหนดกลางทาง (Silent Relay) ดักจับคำนวณหา Session Key
- **Pure Dart Cryptography**: เขียนอัลกอริทึม AES-256 Block Cipher, X25519 Montgomery Ladder ($y^2 = x^3 + 486662x^2 + x \pmod{2^{255}-19}$) และ HKDF-SHA256 แบบ Pure Dart 100% ประมวลผลรวดเร็ว ทำงานออฟไลน์โดยไม่ต้องพึ่งพา Native External Libraries
- **Fail-Closed Security Guard Policy**: ยกเลิกการตกกลับเป็น Plaintext เมื่อการเข้ารหัสล้มเหลว หากระบบเข้ารหัสขัดข้อง ระบบจะโยน `CryptoException` และระงับการส่งแพ็กเก็ตทันที ห้ามส่งข้อความแบบ Plaintext ลงคลื่นวิทยุเด็ดขาด (Security-by-Default / Fail-Closed Pattern)
- **Zero-Knowledge Encrypted Private Location Payload**: แพ็กรวมพิกัด GPS (`latitude`, `longitude`), ชื่อผู้ส่ง และเนื้อหาลงใน **Inner Private Payload** แล้วเข้ารหัสด้วย AES-256-GCM ทั้งชุด โดยกำหนดค่าพิกัดบน Header ที่จะส่งผ่าน Silent Relay Node ให้เป็น `null` โหนดรีเลย์ตรงกลางจะมองเห็นเฉพาะข้อมูล Routing ที่จำเป็น (`id`, `senderId`, `recipientId`, `ttl`) เท่านั้น
- **Multi-Layer Anti-Replay Protection Engine**: เพิ่มระบบป้องกันการส่งข้อความย้อนรอย (Replay Attack) 3 ชั้น ได้แก่ 1) ตรวจสอบเวลา Freshness Window (ปฏิเสธแพ็กเก็ตที่หมดอายุเกิน 10 นาที) 2) ติดตาม Unique Nonce/Ephemeral Key (`_usedNonces`) ปฏิเสธการแอบอ้างคีย์ซ้ำ 3) ติดตาม Unique Message UUID (`_processedMessageIds`)
- **RFC 4122 Standard UUID v4 Message ID**: อัปเกรดระบบสร้างไอดีประจำข้อความ (`NearbyMessage.id`) จากเดิมรูปแบบ `senderId_timestamp` เปลี่ยนเป็น **128-bit RFC 4122 UUID v4** (`550e8400-e29b-41d4-a716-446655440000`) ป้องกันปัญหาไอดีชนกัน (Collision) 100% แม้จะส่งข้อความรวดเร็วในระดับมิลลิวินาทีเดียวกัน
- **LRU + TTL Bounded Cache Memory Safety**: เปลี่ยนโครงสร้างการเก็บ `_processedMessageIds` และ `_usedNonces` จากเดิม Set ปล่อยโตไม่จำกัด เป็น **LruMessageIdCache Engine** จำกัดขนาดแคชสูงสุด 1,000–2,000 รายการ (LRU Eviction) พร้อมระบบล้างข้อมูลเก่าอายุเกิน 15 นาทีอัตโนมัติ (TTL Purge) การันตีขนาดหน่วยความจำคงที่ ไม่เกิด Memory Leak ตลอดการใช้งาน
- **Dynamic Reverse Path Routing Table (RPRT) & Unicast ACK Routing**: สร้างตารางเส้นทางย้อนกลับแบบไดนามิก (`_reversePathTable`) บันทึก `messageId / senderId -> endpointId` เพื่อส่งแพ็กเก็ต ACK ย้อนกลับตรงไปยังท่อทางเข้าแบบ **Unicast Direct Routing** ส่องตรงข้ามโหนดโดยไม่เปลืองแบนด์วิดท์คลื่นวิทยุ พร้อมระบบ **Controlled Flooding Fallback** กรณีเส้นทางหลุด
- **Feature-First Architecture Restructuring**: ปรับปรุงโครงสร้างไดเรกทอรีของซอร์สโค้ดใหม่ทั้งหมดเข้าสู่ **Feature-First Architecture** แบ่งแยกโฟลเดอร์ตามฟีเจอร์อย่างเป็นระเบียบ (`lib/features/chat/`, `map/`, `first_aid/`, `emergency/`, `weather/`, `survival/`, `home/` และ `lib/core/`) พร้อมโฟลเดอร์ย่อย `screens/`, `services/`, `widgets/` ชัดเจน อัปเดตพิกัด `import` ทั้งหมดในแอปพลิเคชัน 100%
- **Backward Compatibility**: รองรับการถอดรหัสแพ็กเก็ต V3, V2 และ V1 ย้อนหลังอย่างปลอดภัย

---

## [1.6.0] - 2026-08-21

### 🌟 Added & Enhanced (ฟีเจอร์ใหม่และการปรับปรุง)
- **Full Tactical Splash Screen & Modern UI**: ปรับปรุงหน้าจอโหลดเข้าแอป (`SplashScreen`) ใหม่ทั้งหมดในสไตล์ Tactical / Military HUD ด้วยวงกลมเรดาร์หมุน 360°, วงคลื่น Pulse Ring, ตาราง HUD Grid, โลโก้เรดาร์เรืองแสง Cyan และการเปลี่ยนผ่านแบบสไลด์เนียนใน 2.5 วินาที
- **Full-Bleed Circular Radar App Icon**: เปลี่ยนไอคอนแอปพลิเคชันบน Android และ iOS เป็นโลโก้เรดาร์ Tactical แบบวงกลมเต็มใบ (Edge-to-Edge Circular Icon) โดยไม่มีขอบขาวรอบนอกผ่าน Android Adaptive Icons (`adaptive_icon_background` และ `adaptive_icon_foreground`)
- **Native Android Launch Background Color Fix**: เปลี่ยนพื้นหลังช่วงเริ่มรัน Android Native Splash Screen (`launch_background.xml`, `drawable-v21`, `colors.xml`) จากสีขาวเดิมเป็นสีดำ Tactical `#070B14` ต่อเนื่องกับหน้า Splash Screen อย่างสมบูรณ์
- **App-Wide Language Switcher Card**: เพิ่มการ์ดตั้งค่าภาษาทั้งแอป (`_buildLanguageSelector()`) ในหน้าโปรไฟล์ (`profile_screen.dart`) เชื่อมต่อกับ `LanguageProvider` รองรับการสลับภาษาแบบไดนามิก `[ 🇹🇭 ภาษาไทย ]` และ `[ 🇺🇸 English ]`
- **Bilingual First Aid & Robust TTS Fallback**: เพิ่มระบบสลับภาษาด่วน `[ TH | EN ]` ในหน้าคู่มือปฐมพยาบาล (`first_aid_detail_screen.dart`), ปุ่มปรับระดับความเร็วเสียงอ่าน TTS (0.7x, 1.0x, 1.3x), สัญญาณชีพ CPR pulse 110 BPM, คำแปลภาษาอังกฤษครบทั้ง 10 หัวข้อ และระบบ Fallback ภาษาพากย์สังเคราะห์ (`th-TH` -> `th_TH` -> `th`) ป้องกันปัญหาสำเนียงภาษาเพี้ยน
- **Compass Hardware & Runtime Permission Handling**: เพิ่มระบบตรวจขอสิทธิ์ Location Permission ที่ runtime ก่อน Subscribe เข็มทิศดิจิทัลใน `survival_tools_screen.dart`, เพิ่มระบบตรวจสอบ Magnetometer บนชิปฮาร์ดแวร์จริง (`_compassSupported`), และเพิ่มการ์ดแจ้งเตือน UI หากเครื่องไม่รองรับหรือยังไม่อนุญาตสิทธิ์

### 🛠️ UI/UX & Codebase Maintenance
- **Bottom Navigation Bar Proportions Fix**: ปรับสมดุลปุ่มเมนูด้านล่าง (`main_navigation.dart`) โดยล็อคขนาดกรอบไอคอนทั้ง 5 ปุ่ม (`Home`, `First Aid`, `SOS`, `Map`, `Profile`) ให้สูง 32px เท่ากันเป๊ะ วางเรียงในระนาบเดียวกัน ปรับคำปุ่มปฐมพยาบาลเป็น `First Aid` / `ปฐมพยาบาล` บนบรรทัดเดียว ป้องกันการตัดคำทำให้ไอคอนเบี้ยว
- **Map Force Cache Refresh**: เพิ่มตัวเลือก `forceRefresh: true` ใน `IPoiRepository` และ `PoiRepositoryImpl` เมื่อผู้ใช้กดปุ่ม "โหลดแมพ" (`MapControls`) เพื่อข้ามแคช 24 ชั่วโมงและดึงข้อมูลพิกัดสถานพยาบาลใหม่ทันที
- **Auto Check-In Screen Redesign**: ปรับปรุงหน้าจอเช็กอินความปลอดภัยอัตโนมัติ (`SafetyCheckScreen`) ในสไตล์ Glassmorphism, วงแหวนเรืองแสง Radial Glow, ตัวเลขจับเวลาแบบ Tabular, ปุ่มลัดเลือกระยะเวลา และ Haptic Feedback
- **Dead Code Cleanup & Optimization**: ดำเนินการตรวจสอบซอร์สโค้ด ลบไฟล์ที่ไม่ได้ใช้งาน 8 ไฟล์ (ได้แก่ `serp_api_service.dart`, `action_search_button.dart`, `facility_carousel.dart`, `facility_detail_sheet.dart`, `map_header.dart`, `route_overlay.dart`, `search_result_panel.dart`, `tactical_button_painter.dart`), ลบตัวแปรที่ไม่ใช้ใน `map_provider.dart` และลบไฟล์ log ตระกูล `hs_err_pid*.log` / `replay_pid*.log` ออกจากโฟลเดอร์ `android/`

---

## [1.5.0] - 2026-07-23

### 🌟 Added (ฟีเจอร์ใหม่)
- **Bilingual First Aid TTS & Voice Guide**: เพิ่มระบบบรรยายเสียงปฐมพยาบาล 2 ภาษาแบบไดนามิก (สลับเสียงอ่านระหว่าง `th-TH` ภาษาไทย และ `en-US` ภาษาอังกฤษ พร้อมเนื้อหาขั้นตอนแปลภาษาตาม Locale ของแอป)
- **Real-time Traffic Flow Tile Overlay**: เพิ่มชั้นแผนที่ซ้อนทับเส้นสีความหนาแน่นจราจรสด (เขียว/เหลือง/แดง) จาก Longdo Map Tile API (`/mmmap/tile.php?layer=traffic`) บนสไตล์แผนที่แบบ Traffic
- **3-Way Parallel POI Discovery**: ขยายท่อลำเลียงข้อมูลพิกัดสถานพยาบาลยิงคู่ขนาน 3 ทาง (Longdo Tag Search + Longdo Thai Keyword Search + OSM Overpass Race Condition)
- **Overpass Race Condition Engine**: ยิงขอข้อมูลจาก Overpass Mirror Servers ทุกตัวพร้อมกัน (`Future.wait`) เอาผลลัพธ์แรกที่เร็วที่สุด ป้องกันปัญหา Timeout
- **High-Density Marker Rendering**: ขยายการรองรับแสดงผลหมุดพิกัดบนแผนที่สูงสุดจาก 40 หมุดเป็น **300 หมุด**

### 🎨 UI/UX Polish & Bug Fixes
- **Delivery ACK & Read Receipts (ใบยืนยันส่งถึง & ใบอ่านแล้ว)**: เพิ่มระบบติดตามสถานะข้อความเรียลไทม์ผ่าน Mesh Reverse Routing แสดงสัญลักษณ์สถานะบนกล่องข้อความผู้ส่ง:
  - `⏳` (`SENDING`): กำลังส่งแพ็กเก็ตผ่าน Mesh Network
  - `✓` (`DELIVERED`): ส่งถึงเครื่องเป้าหมาย (นาย E) สำเร็จแล้ว
  - `✓✓` (`READ`): ผู้รับ (นาย E) เปิดอ่านข้อความแชทส่วนตัวแล้ว
- **Crypto Engine V2 (SHA-256 + HMAC-SHA256)**: อัปเกรดระบบเข้ารหัส `CryptoMeshService` ด้วยการถอดรหัสผ่าน SHA-256 Key Derivation, 16-byte Random IV, และลายเซ็นดิจิทัล HMAC-SHA256 (`ENC_V2::...`) ป้องกันโหนดรีเลย์ตรงกลางแอบแก้ไขหรือดัดแปลงแพ็กเก็ตข้อมูล
- **E2EE Private Direct Mesh Chat**: เพิ่มโหมดแชทส่วนตัวเข้ารหัสต้นทางถึงปลายทาง (End-to-End Encryption) โดยข้อความส่วนตัวจะเดินทางผ่านโหนดรีเลย์ (B, C, D) ในฉากหลังอย่างเงียบๆ โดยไม่แสดงผลและไม่อ่านข้อความบนเครื่องทางผ่าน มีเพียงเครื่องเป้าหมาย (นาย E) เท่านั้นที่สามารถถอดรหัสและเห็นข้อความบนหน้าจอ
- **Silent Multi-Hop Relay Engine**: ปรับแต่ง `NearbyService` ให้ตรวจสอบ `recipientId` หากไม่ใช่เป้าหมาย เครื่องจะทำหน้าที่ลดค่า TTL และรีเลย์ส่งต่อแพ็กเก็ตไปยังเพื่อนโหนดถัดไปโดยอัตโนมัติ
- **Profile Screen & Mesh Callsign Linkage**: เชื่อมโยงชื่อ-นามสกุลในหน้าโปรไฟล์เข้ากับชื่ออุปกรณ์ (Device Callsign) ในเครือข่ายออฟไลน์ Mesh Network โดยอัตโนมัติ แสดง Badge ป้ายชื่อ **`CALLSIGN: [Name]`** สี Cyan ดีไซน์ Tactical ใต้รูปโปรไฟล์ เพิ่มช่องข้อมูลในแท็บส่วนตัว และ helper text คำแนะนำในหน้าแก้ไขฟอร์ม พร้อมนำส่วน QR Code Placeholder ออกจากหน้า Medical ID ให้กระชับสะอาดตา
- **Interactive Map Search & GPS Precision Polish**:
  - เพิ่ม **ปุ่มลอย "ค้นหาในบริเวณนี้" (Search This Area)** ลอยขึ้นมาให้อย่างนุ่มนวลเมื่อผู้ใช้ลากแผนที่ไปดูโซนอื่น กดค้นหารพ./ร้านยาในพิกัดใหม่ได้ทันที
  - เพิ่มปุ่มดู **รายละเอียดคำแนะนำการเลี้ยว (Step-by-Step Navigation Panel)** บนแถบ HUD นำทาง สามารถเปิด/ปิดรายการเส้นทางเลี้ยวทีละแยกได้อย่างสะดวก
  - ปรับปรุงแถบค้นหา **Search Bar** ใช้ `ValueListenableBuilder` แสดงปุ่มล้างคำพิมพ์ `(X)` แบบเรียลไทม์ขณะพิมพ์ พร้อมสั่งโหลดรายการรอบตัวคืนเมื่อกดลบ
  - เพิ่มระบบตรวจเช็กบริการ GPS (`isLocationServiceEnabled`) แจ้งเตือนเมื่อลืมเปิดตำแหน่ง พร้อมกลไก Fallback พิกัดสองระดับ ป้องกัน FusedLocation ค้าง
- **Animated Side Toolbar Reset**: แก้ไขเงื่อนไขตำแหน่งของเมนูขวา (`MapControls`) ใน `map_screen.dart` ให้ตรวจสอบทั้ง `selectedFacility != null` และ `provider.showDetails` ร่วมกับ `AnimatedPositioned` (250ms) ทำให้เมื่อกดกากบาท (✕) ปิด Sheet เมนูขวาจะเลื่อนสไลด์กลับลงมาที่ตำแหน่งเดิมล่างสุด (`bottom: 120`) อย่างนุ่มนวล
- **Google Maps External Launcher**: เพิ่มปุ่มแคปซูลสีแดง **`Google Maps`** บน `GoogleFacilitySheet` และทำให้รายการที่อยู่สามารถแตะเพื่อกระโดดเปิดพิกัดเป้าหมายบนแอปพลิเคชัน Google Maps ภายนอกได้ทันที
- **Search Bar Layout Overlap Fix**: แก้ไขระยะขอบขวาของแถบค้นหา (`google_map_header.dart`) ด้วย `padding: EdgeInsets.fromLTRB(16, 12, 72, 8)` เพื่อป้องกันไม่ให้ทับซ้อนกับแถบเครื่องมือแนวตั้ง (`MapControls`) ทางด้านขวา
- **Functional Search Action Button**: เปลี่ยนไอคอนรูปโปรไฟล์บนแถบค้นหาเป็นปุ่มค้นหาแว่นขยาย (`Icons.search_rounded`) ที่สามารถกดเพื่อค้นหาได้จริง พร้อมสั่งการให้แผนที่เลื่อนอนิเมชันไปยังพิกัดเป้าหมายทันที
- **APK GPS Location Centering Fix**: แก้ไขปัญหาสตรีมพิกัดและโฟกัสตำแหน่งบนไฟล์ APK ด้วยระบบ `getLastKnownPosition` instant fallback, ร้องขอสิทธิ์ `checkPermission`/`requestPermission` และใช้ `forceLocationManager: true` ป้องกันบริการ FusedLocation ค้าง
- **APK Compass & High-Sampling Sensors**: เพิ่มสิทธิ์ `<uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS" />` และ `<uses-feature android:name="android.hardware.sensor.compass" />` ใน `AndroidManifest.xml` พร้อมอัปเดตสตรีมเข็มทิศให้หมุนทำมุมบนแผนที่ได้สมบูรณ์ใน APK
- **Bilingual First Aid UI**: แสดงชื่อหัวข้อ ขั้นตอนการช่วยเหลือ คำเตือน และปุ่มโทร 1669 ในหน้าปฐมพยาบาลตามภาษาของแอป (ไทย/อังกฤษ)
- **Fixed Close Button Stack & Dismissal**: แก้ไขการเช็คสถานะ `provider.showDetails` ใน `map_screen.dart` ทำให้ปุ่มกากบาท (✕) ทำหน้าที่พับเก็บ Sheet ได้อย่างถูกต้องโดยไม่ล้างเส้นทางนำทาง
- **Explicit Stop Navigation Pill**: แยกปุ่ม "สิ้นสุดนำทาง" สีแดงสำหรับล้างเส้นทางเมื่อต้องการยกเลิกการเดินทางอย่างเป็นทางการ

---

## [1.4.0] - 2026-07-21 (Current Stable Release)

### 🌟 Added (ฟีเจอร์ใหม่)
- **Multi-hop Mesh Relay**: อัปเกรดระบบ Nearby P2P Chat ให้สามารถส่งต่อข้อความขอความช่วยเหลือ SOS และพิกัดข้ามอุปกรณ์หลายทอดแบบอัตโนมัติ (TTL=3 สำหรับแชททั่วไป, TTL=5 สำหรับ SOS)
- **Message Deduplication**: ระบบป้องกันการรับข้อความวนลูปในเครือข่ายตาข่าย (Loop Prevention via UUID Set)
- **Mesh Relay Visual Badge**: แสดงป้ายสัญลักษณ์ `[🔗 Mesh Relay]` บนหน้าจอแชทสำหรับข้อความที่เดินทางผ่านโหนดกลางทาง
- **Traffic Incidents Layer**: เพิ่มเลเยอร์หมุดรายงานอุบัติเหตุ/การจราจรติดขัด/งานก่อสร้างเรียลไทม์จาก Longdo REST API
- **CartoDB Voyager Map Style**: เพิ่มสไตล์แผนที่สว่างอำนวยความสะดวกการดูการจราจร

### 🛠️ Architecture & Refactoring
- สลับสถาปัตยกรรมมอดูลแผนที่เข้าสู่ **Repository Pattern** (`IPoiRepository`, `IRoutingRepository`, `PoiRepositoryImpl`, `RoutingRepositoryImpl`)
- ย้าย Data Model `MedicalFacility` ออกจาก `services/` ไปยัง `models/` อย่างถูกต้องตามหลัก Clean Architecture
- เพิ่มระบบ Cache Metadata (`CacheMetadata`) เพื่อควบคุมอายุแคชพิกัดในเครื่อง (หมดอายุใน 24 ชั่วโมง และทำลายแคชเก่าเกิน 7 วัน)
- ผ่านการวิเคราะห์คุณภาพโค้ด `flutter analyze` สะอาด 100% (No issues found!)

---

## [1.3.0] - 2026-07-13

### 🌟 Added (ฟีเจอร์ใหม่)
- **Hike Dashboard Contrast Polish**: ปรับแต่ง UI หน้าสถิติเดินป่าด้วยธีม Slate Blue (`#0F172A`) โปร่งแสง 85% พร้อมสีสัญลักษณ์เด่นชัด (Cyan, Orange, Emerald)
- **Offline Haversine Bearing Route**: เพิ่มระบบคำนวณเส้นทางและเวลาเดินเท้าแนวตรงยามออฟไลน์ความเร็ว 5 กม./ชม.

---

## [1.2.0] - 2026-06-21

### 🌟 Added (ฟีเจอร์ใหม่)
- **P2P Nearby Connections Chat Room**: เปิดใช้งานห้องแชทไร้เน็ตผ่านสัญญาณ Bluetooth และ WiFi Direct
- **High-Priority SOS Push Notification**: เพิ่มช่องทางแจ้งเตือนข้ามหน้าจอล็อกเมื่อได้รับข้อความ SOS

---

## [1.1.0] - 2026-06-14

### 🌟 Added (ฟีเจอร์ใหม่)
- **Open-Meteo Weather & Air Quality Integration**: เพิ่มการตรวจเช็คอุณหภูมิ ดัชนี UV และฝุ่น PM 2.5
- **CPR First Aid Visualizer**: แอนิเมชันประกอบเสียงสังเคราะห์ช่วยกำกับจังหวะเวลาทำ CPR

---

## [1.0.0] - 2026-06-01

### 🌟 Added (ฟีเจอร์แรกเริ่ม)
- เปิดตัวโครงการ **BANTAWAN (SOS Premier)** เวอร์ชันแรก
- ระบบ SOS ปุ่มกดค้าง 3 วินาที สั่งเปิดไซเรนสังเคราะห์เสียงและส่ง SMS
- ชุดเครื่องมือเอาชีวิตรอด (ไฟฉายรหัสมอร์ส, เข็มทิศดิจิทัล, เสียงนกหวีด)
