# บทที่ 3
# วิธีการดำเนินงานและการออกแบบสถาปัตยกรรมระบบ (Methodology & System Architecture)
## โครงงาน: ระบบสนับสนุนความปลอดภัยส่วนบุคคลบนสมาร์ตโฟน (Personal Safety Support for Smartphones)
### สาขาวิชาวิศวกรรมคอมพิวเตอร์ คณะวิศวกรรมศาสตร์ มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย
**ปีการศึกษา 2569 (Academic Year 2026)**

---

ในบทนี้จะอธิบายถึงระเบียบวิธีวิจัย ขั้นตอนการดำเนินงานตลอดภาคการศึกษา แผนการดำเนินงาน การออกแบบสถาปัตยกรรมระบบ 4 เลเยอร์หลัก การออกแบบฐานข้อมูลภายในอุปกรณ์พร้อมพจนานุกรมข้อมูล (Data Dictionary) ตลอดจนการออกแบบโปรโตคอลการสื่อสารไร้สายแบบเครือข่ายเมชและการเข้ารหัสลับข้อมูล เพื่อให้ระบบ BANTAWAN สามารถปฏิบัติการได้อย่างถูกต้อง มีความมั่นคงปลอดภัย และมีเสถียรภาพสูงสุดในสภาวะวิกฤต

---

## 3.1 แผนการดำเนินงานพัฒนาโครงงาน (Project Work Plan)

การดำเนินงานพัฒนาโครงงานระบบสนับสนุนความปลอดภัยส่วนบุคคลบนสมาร์ตโฟน ได้แบ่งขั้นตอนการทำงานออกเป็น 8 กิจกรรมหลัก ครอบคลุมระยะเวลา 17 สัปดาห์ตลอดภาคการศึกษา ดังแสดงในตารางที่ 3.1

### ตารางที่ 3.1: แผนการดำเนินงานพัฒนาโครงงานตลอดภาคการศึกษา (17 สัปดาห์)

| กิจกรรม / สัปดาห์ | แผน/ผล | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **3.1.1 ศึกษาและเข้าใจปัญหา (Problem Understanding)** | P<br>A | ■<br>■ | ■<br>■ | ■<br>■ | | | | | | | | | | | | | | |
| **3.1.2 การสืบค้นข้อมูลและทฤษฎี (Literature Review)** | P<br>A | | | ■<br>■ | ■<br>■ | ■<br>■ | ■<br>■ | | | | | | | | | | | |
| **3.1.3 การวิเคราะห์ความต้องการ (Requirements Analysis)** | P<br>A | | | | ■<br>■ | ■<br>■ | ■<br>■ | ■<br>■ | | | | | | | | | | |
| **3.1.4 การออกแบบสถาปัตยกรรมและฐานข้อมูล (System Design)**| P<br>A | | | | | | | ■<br>■ | ■<br>■ | ■<br>■ | ■<br>■ | | | | | | | |
| **3.1.5 การพัฒนาโปรแกรมประยุกต์ (Implementation)** | P<br>A | | | | | | | | | ■<br>■ | ■<br>■ | ■<br>■ | ■<br>■ | ■<br>■ | | | | |
| **3.1.6 การทดสอบและปรับปรุงระบบ (Testing & Optimization)** | P<br>A | | | | | | | | | | | | ■<br>■ | ■<br>■ | ■<br>■ | ■<br>■ | | |
| **3.1.7 การสอบประเมินโครงงาน (Project Defense Exam)** | P<br>A | | | | | | | | | | | | | | | ■<br>■ | ■<br>■ | |
| **3.1.8 การจัดทำเล่มปริญญานิพนธ์ฉบับสมบูรณ์ (Documentation)**| P<br>A | | | | | | | | | | | | | | | | ■<br>■ | ■<br>■ |

*(หมายเหตุ: P = แผนการดำเนินงานที่วางไว้ [Plan], A = การดำเนินงานจริงที่สำเร็จ [Actual])*

**รายละเอียดกิจกรรมการดำเนินงาน:**
* **3.1.1 ศึกษาและเข้าใจปัญหา:** สำรวจปัญหาความล้มเหลวของการสื่อสารในพื้นที่ประสบภัยพิบัติ และข้อจำกัดของแอปพลิเคชันความปลอดภัยทั่วไปที่พึ่งพาอินเทอร์เน็ต
* **3.1.2 การสืบค้นข้อมูลและทฤษฎี:** ศึกษาเอกสารและงานวิจัยที่เกี่ยวข้องกับ Mobile Ad-hoc Networks (MANET), Delay-Tolerant Networking (DTN), Cryptography (X25519, AES, HMAC), และ Geographic Information Systems (GIS)
* **3.1.3 การวิเคราะห์ความต้องการ:** กำหนดข้อกำหนดเชิงหน้าที่ (Functional Requirements) 10 ระบบ และข้อกำหนดด้านความปลอดภัยและประสิทธิภาพ
* **3.1.4 การออกแบบสถาปัตยกรรมและฐานข้อมูล:** ออกแบบสถาปัตยกรรม 4 เลเยอร์ สคีมาฐานข้อมูล SQLite V6 และโครงสร้างแพ็กเก็ต Nearby Connections
* **3.1.5 การพัฒนาโปรแกรมประยุกต์:** พัฒนาส่วนติดต่อผู้ใช้ด้วย Flutter และพัฒนาระบบแบ็กเอนด์ในเครื่อง (Local Services)
* **3.1.6 การทดสอบและปรับปรุงระบบ:** ดำเนินการทดสอบ Automated Test Suites 7 ชุด และการทดสอบภาคสนามจำลองด้วยเครื่อง Android 3–5 เครื่อง
* **3.1.7 การสอบประเมินโครงงาน:** นำเสนอระบบและสาธิตการทำงานต่อหน้าคณะกรรมการสอบปริญญานิพนธ์
* **3.1.8 การจัดทำเล่มปริญญานิพนธ์:** จัดทำรูปเล่มรายงานฉบับสมบูรณ์ตามระเบียบของสาขาวิชาวิศวกรรมคอมพิวเตอร์ มทร.ศรีวิชัย

---

## 3.2 ภาพรวมสถาปัตยกรรมแอปพลิเคชัน 4 เลเยอร์หลัก (4-Layer System Architecture)

เพื่อให้ระบบมีความเป็นโมดูล (Modularity) รองรับการทดสอบ (Testability) และง่ายต่อการบำรุงรักษา สถาปัตยกรรมของแอปพลิเคชัน BANTAWAN ถูกออกแบบแบ่งออกเป็น **4 เลเยอร์หลัก (4-Layer Architecture)** สอดคล้องกับผังภาพสถาปัตยกรรมของโครงงาน ดังแสดงในรูปที่ 3.1:

```mermaid
graph TD
    subgraph Layer1["1. PRESENTATION LAYER (ส่วนแสดงผลส่วนต่อประสานผู้ใช้)"]
        direction TB
        UI_Home["Home Dashboard\n(สรุปสถานะเครื่อง/โหนดเพื่อนบ้าน)"]
        UI_Map["Map Screen\n(แสดงผลแผนที่/POI/เส้นทางนำทาง)"]
        UI_SOS["SOS Interface\n(ปุ่มกู้ภัยฉุกเฉินกดค้าง 3 วินาที)"]
        UI_Chat["Nearby Chat Screen\n(การสื่อสารแชตออฟไลน์)"]
        UI_Aid["First Aid Screen\n(คู่มือปฐมพยาบาล 12 สถานการณ์)"]
    end

    subgraph Layer2["2. STATE MANAGEMENT LAYER (ส่วนบริหารจัดการสถานะข้อมูล)"]
        direction TB
        SM_Map["MapProvider\n(จัดการสถานะแผนที่และพิกัด)"]
        SM_SOS["SOSProvider\n(จัดการสถานะการแจ้งเตือนภัย)"]
        SM_Nearby["NearbyProvider\n(จัดการสถานะการเชื่อมต่อเมช)"]
        SM_Profile["ProfileProvider\n(จัดการข้อมูลผู้ใช้และ Medical ID)"]
    end

    subgraph Layer3["3. BUSINESS LOGIC / FEATURE LOGIC (ส่วนตรรกะการทำงานของฟังก์ชัน)"]
        direction TB
        BL_SOS["SOS Logic\n(การนับเวลาถอยหลัง/สร้างสัญญาณฉุกเฉิน)"]
        BL_Mesh["Nearby Mesh P2P Logic\n(Flooding Relay/TTL/Unicast ACK/Mule)"]
        BL_Navi["Map & Navi Logic\n(Haversine Distance/Initial Bearing/OSRM)"]
        BL_Crypto["CryptoMeshService\n(X25519 ECDH/AES-CTR/HMAC-SHA256)"]
    end

    subgraph Layer4["4. DATA SOURCE / INFRASTRUCTURE (ส่วนแหล่งข้อมูลและฮาร์ดแวร์พื้นฐาน)"]
        direction TB
        DS_Local["Local Storage\n(SQLite V6 Database / SharedPreferences)"]
        DS_Ext["External Web APIs (On-Grid)\n(Overpass, Longdo, OSRM, Open-Meteo, SerpApi)"]
        DS_HW["Device Hardware APIs\n(BLE, Wi-Fi Direct, GPS, Compass, Flash, TTS)"]
    end

    Layer1 --> Layer2
    Layer2 --> Layer3
    Layer3 --> Layer4
```
<div align="center"><b>รูปที่ 3.1: ภาพแสดงสถาปัตยกรรม 4 เลเยอร์หลักของแอปพลิเคชัน BANTAWAN</b></div>

### รายละเอียดการทำงานของแต่ละเลเยอร์:
1. **1. Presentation Layer (ส่วนติดต่อผู้ใช้งาน):** พัฒนาด้วยวิดเจ็ตของ Flutter ประกอบด้วยหน้าจอหลัก (Home Dashboard), หน้าจอแผนที่นำทาง (Map Screen), หน้าจอสั่งการขอความช่วยเหลือฉุกเฉิน (SOS Interface), หน้าจอแชตเมชออฟไลน์ (Nearby Chat) และหน้าจอคู่มือปฐมพยาบาล (First Aid)
2. **2. State Management Layer (ส่วนบริหารจัดการสถานะ):** ประยุกต์ใช้ **Provider Pattern (`ChangeNotifier`)** ทำหน้าที่เป็นตัวกลางในการกระจายข้อมูล (Data Bus) และอัปเดต UI เมื่อข้อมูลสถานะเปลี่ยนแปลง ได้แก่ `MapProvider`, `SOSProvider`, `NearbyProvider` และ `ProfileProvider`
3. **3. Business Logic Layer (ส่วนตรรกะการทำงาน):** แกนประมวลผลทางวิศวกรรม ประกอบด้วย:
   * **SOS Logic:** การควบคุมเวลานับถอยหลัง 3 วินาที และการจัดโครงสร้างแพ็กเก็ตฉุกเฉิน
   * **Nearby Mesh P2P Logic:** การควบคุมการส่งต่อแพ็กเก็ต (Controlled Flooding Relay), การลดทอนค่า TTL, การบันทึกเส้นทาง RPRT เพื่อส่ง Unicast ACK และระบบคนเดินสาร Data Mule
   * **Map & Navi Logic:** การคำนวณระยะขจัดด้วยสูตร Haversine, การหมุนลูกศรตาม Initial Bearing, และการถอดรหัส Encoded Polyline
   * **CryptoMeshService:** การเข้ารหัสลับแบบ E2EE V5 (X25519, AES-256-CTR, HMAC-SHA256)
4. **4. Data Source / Infrastructure Layer (ส่วนแหล่งข้อมูลและฮาร์ดแวร์):**
   * **Local Storage:** ฐานข้อมูล SQLite V6 (`bantawan_chat.db`) และหน่วยความจำ `SharedPreferences`
   * **External Web APIs:** บริการออนไลน์ภายนอก (Overpass, Longdo, OSRM, Open-Meteo, SerpApi)
   * **Device Hardware APIs:** การควบคุมฮาร์ดแวร์ระดับเนทีฟผ่าน Platform Channels (บลูทูธ BLE, Wi-Fi Direct, GPS, เข็มทิศ, ไฟฉาย และลำโพง)

---

## 3.3 การออกแบบฐานข้อมูลภายในอุปกรณ์และพจนานุกรมข้อมูล (Database Design & Data Dictionary)

เพื่อตอบสนองสถาปัตยกรรมแบบ Offline-First ข้อมูลทั้งหมดถูกจัดเก็บไว้ในฐานข้อมูล **SQLite เวอร์ชัน 6 (`bantawan_chat.db`)** โดยไม่มีการพึ่งพาเซิร์ฟเวอร์ภายนอก ประกอบด้วย 5 ตารางหลัก รายละเอียดพจนานุกรมข้อมูล (Data Dictionary) แสดงดังตารางที่ 3.2 ถึง 3.6:

### ตารางที่ 3.2: พจนานุกรมข้อมูลตารางข้อความการสนทนาและสัญญาณฉุกเฉิน (`messages`)

| TABLE NAME | ATTRIBUTE NAME | CONTENTS | TYPE | EXAMPLE | REQUIRED | PK / FK | FK REFERENCED COLUMN | FK REFERENCED TABLE |
|:---|:---|:---|:---:|:---|:---:|:---:|:---:|:---:|
| `messages` | `id` | รหัสประจำข้อความ (UUIDv4) | TEXT | `e4b2d3c1-7f8a...` | Y | PK | - | - |
| | `senderId` | รหัสโหนดผู้ส่ง | TEXT | `NODE_78F2A` | Y | - | - | - |
| | `senderName` | ชื่อของผู้ส่งข้อความ | TEXT | `สมชาย กู้ภัย` | Y | - | - | - |
| | `recipientId` | รหัสโหนดผู้รับปลายทาง | TEXT | `NODE_99E1B` | Y | - | - | - |
| | `recipientName` | ชื่อของผู้รับปลายทาง | TEXT | `ศูนย์ประสานงาน` | Y | - | - | - |
| | `content` | เนื้อหาข้อความ (หรือ Ciphertext) | TEXT | `ขอความช่วยเหลือด่วน` | Y | - | - | - |
| | `timestamp` | วันและเวลาที่สร้างข้อความ | TEXT | `2026-10-06T14:30:00Z` | Y | - | - | - |
| | `latitude` | พิกัดละติจูดแนบ | REAL | `7.198823` | N | - | - | - |
| | `longitude` | พิกัดลองจิจูดแนบ | REAL | `100.595412` | N | - | - | - |
| | `isLocation` | สถานะการแนบพิกัด (0=ไม่แนบ, 1=แนบ) | INTEGER | `1` | Y | - | - | - |
| | `isSOS` | สถานะข้อความฉุกเฉิน (0=ปกติ, 1=SOS) | INTEGER | `1` | Y | - | - | - |
| | `isEncrypted` | สถานะการเข้ารหัสลับ (0=ไม่เข้ารหัส, 1=E2EE) | INTEGER | `1` | Y | - | - | - |
| | `ttl` | จำนวน Hop คงเหลือสูงสุด | INTEGER | `5` | Y | - | - | - |
| | `status` | สถานะการส่ง (SENDING, MULE_CARRIED, DELIVERED, READ) | TEXT | `DELIVERED` | Y | - | - | - |
| | `conversationId`| รหัสกลุ่มการสนทนา | TEXT | `CONV_78F2_99E1` | Y | - | - | - |
| | `mediaPath` | ที่อยู่ไฟล์สื่อแนบในเครื่อง | TEXT | `/data/user/0/.../rec.m4a`| N | - | - | - |
| | `mediaType` | ประเภทไฟล์แนบ (NONE, AUDIO, IMAGE) | TEXT | `AUDIO` | Y | - | - | - |

---

### ตารางที่ 3.3: พจนานุกรมข้อมูลตารางแพ็กเก็ตที่รอการส่งต่อ (`pending_messages`)

| TABLE NAME | ATTRIBUTE NAME | CONTENTS | TYPE | EXAMPLE | REQUIRED | PK / FK | FK REFERENCED COLUMN | FK REFERENCED TABLE |
|:---|:---|:---|:---:|:---|:---:|:---:|:---:|:---:|
| `pending_messages` | `id` | รหัสประจำแพ็กเก็ต | TEXT | `e4b2d3c1-7f8a...` | Y | PK | `id` | `messages` |
| | `rawJson` | ข้อมูลแพ็กเก็ตดิบรูปแบบ JSON | TEXT | `{"id":"e4b2...","ttl":4}` | Y | - | - | - |
| | `createdAt` | เวลาที่บรรจุเข้าสู่คิวรอส่ง | TEXT | `2026-10-06T14:30:05Z` | Y | - | - | - |
| | `retryCount` | จำนวนครั้งที่พยายามส่งซ้ำ | INTEGER | `2` | Y | - | - | - |

---

### ตารางที่ 3.4: พจนานุกรมข้อมูลตารางแพ็กเก็ตที่ผ่านการประมวลผลแล้ว (`processed_packets`)

| TABLE NAME | ATTRIBUTE NAME | CONTENTS | TYPE | EXAMPLE | REQUIRED | PK / FK | FK REFERENCED COLUMN | FK REFERENCED TABLE |
|:---|:---|:---|:---:|:---|:---:|:---:|:---:|:---:|
| `processed_packets` | `packetId` | รหัสแพ็กเก็ตที่เคยรับหรือส่งต่อ | TEXT | `e4b2d3c1-7f8a...` | Y | PK | - | - |
| | `receivedAt` | เวลาที่รับแพ็กเก็ตครั้งแรก (Epoch ms) | INTEGER | `1728225008000` | Y | - | - | - |

---

### ตารางที่ 3.5: พจนานุกรมข้อมูลตารางกระดานประกาศเตือนภัยเครือข่ายเมช (`mesh_notices`)

| TABLE NAME | ATTRIBUTE NAME | CONTENTS | TYPE | EXAMPLE | REQUIRED | PK / FK | FK REFERENCED COLUMN | FK REFERENCED TABLE |
|:---|:---|:---|:---:|:---|:---:|:---:|:---:|:---:|
| `mesh_notices` | `id` | รหัสประกาศเตือนภัย (UUIDv4) | TEXT | `NOTICE_001_88AF` | Y | PK | - | - |
| | `authorId` | รหัสโหนดผู้ประกาศ | TEXT | `NODE_78F2A` | Y | - | - | - |
| | `authorName` | ชื่อของผู้ประกาศ | TEXT | `ศูนย์กู้ภัยหาดใหญ่` | Y | - | - | - |
| | `content` | เนื้อหาประกาศแจ้งเตือนภัย | TEXT | `แจ้งเตือนระดับน้ำคลองอู่ตะเภา`| Y | - | - | - |
| | `createdAt` | เวลาที่สร้างประกาศ | TEXT | `2026-10-06T14:00:00Z` | Y | - | - | - |
| | `expiresAt` | เวลาหมดอายุของประกาศ | TEXT | `2026-10-07T14:00:00Z` | Y | - | - | - |
| | `isUrgent` | ความด่วนฉุกเฉิน (0=ปกติ, 1=ด่วนมาก) | INTEGER | `1` | Y | - | - | - |
| | `latitude` | พิกัดละติจูดของเหตุการณ์ | REAL | `7.008231` | N | - | - | - |
| | `longitude` | พิกัดลองจิจูดของเหตุการณ์ | REAL | `100.478912` | N | - | - | - |
| | `hopCount` | จำนวนทอดที่ประกาศถูกส่งต่อ | INTEGER | `1` | Y | - | - | - |

---

### ตารางที่ 3.6: พจนานุกรมข้อมูลตารางซองจดหมายคนเดินสาร (`mule_envelopes`)

| TABLE NAME | ATTRIBUTE NAME | CONTENTS | TYPE | EXAMPLE | REQUIRED | PK / FK | FK REFERENCED COLUMN | FK REFERENCED TABLE |
|:---|:---|:---|:---:|:---|:---:|:---:|:---:|:---:|
| `mule_envelopes` | `envelopeId` | รหัสประจำซองจดหมาย (UUIDv4) | TEXT | `e5a1b2c3-9d8e...` | Y | PK | - | - |
| | `senderNodeId` | รหัสโหนดต้นทางผู้สร้างซอง | TEXT | `NODE_78F2A` | Y | - | - | - |
| | `senderCallsign` | นามเรียกขานผู้ส่ง (Callsign) | TEXT | `Survivor Alpha` | Y | - | - | - |
| | `recipientNodeId` | รหัสโหนดเป้าหมายปลายทาง | TEXT | `NODE_99E1B` | Y | - | - | - |
| | `encryptedPayload`| ข้อมูลเพย์โหลดที่เข้ารหัสลับ E2EE | TEXT | `CIPHER_AES_GCM_B64...`| Y | - | - | - |
| | `payloadIv` | เวกเตอร์เริ่มต้น (IV / Nonce) | TEXT | `iv_random_hex` | Y | - | - | - |
| | `payloadAuthTag` | แท็กตรวจพิสูจน์ความถูกต้อง (Auth Tag) | TEXT | `tag_gcm_hex` | Y | - | - | - |
| | `senderSignature` | ลายเซ็นดิจิทัลยืนยันตัวตนผู้ส่ง | TEXT | `sig_ed25519_hex` | Y | - | - | - |
| | `isUrgentSOS` | สถานะซองด่วนฉุกเฉิน (0=ปกติ, 1=SOS) | INTEGER | `0` | Y | - | - | - |
| | `createdAt` | วันและเวลาที่สร้างซองจดหมาย | TEXT | `2026-10-06T12:00:00Z` | Y | - | - | - |
| | `expiresAt` | เวลาหมดอายุของซอง (ค่าเริ่มต้น 48 ชม.)| TEXT | `2026-10-08T12:00:00Z` | Y | - | - | - |
| | `hopCarryCount` | จำนวนครั้งที่ซองถูกส่งต่อข้ามเครื่อง | INTEGER | `1` | Y | - | - | - |
| | `status` | สถานะซอง (`CARRIED`, `DELIVERED`) | TEXT | `CARRIED` | Y | - | - | - |

---

## 3.4 ขั้นตอนการทำงานของโปรโตคอลสื่อสารเมชและการเข้ารหัสลับข้อมูล

เพื่อให้ระบบ BANTAWAN สามารถปฏิบัติการได้อย่างสมบูรณ์แบบ ทั้งในกรณีที่เครือข่ายเชื่อมต่อถึงกันแบบเรียลไทม์ และกรณีที่เกิดภาวะเครือข่ายแยกส่วน (Network Partition) ทางวิศวกรรมจึงได้แบ่งกลไกการส่งผ่านข้อมูลออกเป็น 3 โหมดหลัก โดยไม่มีการทับซ้อนหรือกระทบต่อเสถียรภาพของการทำงานเดิม:

### 3.4.1 โปรโตคอลการส่งต่อแบบ Multi-Hop Relay และ Reverse-Path Unicast ACK

```mermaid
sequenceDiagram
    autonumber
    participant NodeA as โหนด A (ผู้ส่ง)
    participant NodeB as โหนด B (รีเลย์คนกลาง)
    participant NodeC as โหนด C (ผู้รับปลายทาง)

    Note over NodeA: 1. สร้างแพ็กเก็ตฉุกเฉิน (TTL=3 หรือ 5)<br/>เข้ารหัสลับ E2EE ด้วยกุญแจสาธารณะของ Node C
    NodeA->>NodeB: กระจายสัญญาณ BLE / Wi-Fi Direct (Hop 1)
    Note over NodeB: 2. ตรวจสอบ UUID ในแคชป้องกันส่งซ้ำ<br/>บันทึก RPRT: [MessageId -> Endpoint Node A]<br/>ลดทอนค่า TTL: 3 -> 2
    NodeB->>NodeC: รีเลย์แพ็กเก็ตต่อรอบตัว (Hop 2)
    Note over NodeC: 3. ตรวจพบ Recipient ID คือตนเอง<br/>ถอดรหัสลับ E2EE สำเร็จ (Verified Signature)<br/>แสดงผลข้อความ/พิกัดบนหน้าจอทันที
    Note over NodeC: 4. สร้างแพ็กเก็ตยืนยันใบเสร็จ (ACK_DELIVERED)
    NodeC-->>NodeB: ส่ง Unicast ACK ย้อนกลับตามตาราง RPRT
    NodeB-->>NodeA: ส่ง Unicast ACK ย้อนกลับตามตาราง RPRT
    Note over NodeA: 5. ปรับปรุงสถานะข้อความจาก SENDING เป็น DELIVERED (✓✓)
```
<div align="center"><b>รูปที่ 3.2: แผนผังการส่งต่อข้อมูลแบบ Multi-Hop Relay และการตอบรับใบเสร็จแบบ Smart Unicast ACK</b></div>

---

### 3.4.2 โปรโตคอลคนเดินสาร (Data Mule: Store-Carry-and-Forward Protocol)

ในกรณีที่ผู้รับเป้าหมายอยู่นอกระยะการเชื่อมต่อทั้งแบบ 1-hop และ Multi-hop ระบบ BANTAWAN นำเสนอสถาปัตยกรรม **Data Mule (Courier Carrier)** ซึ่งแยกขาดจากคิวรอส่งในเครื่องตนเอง (`pending_messages`) เพื่อให้บุคคลภายนอกที่กำลังเคลื่อนที่ทำหน้าที่เป็น "คนเดินสาร" นำส่งข้อความให้โดยอัตโนมัติ:

```mermaid
sequenceDiagram
    autonumber
    actor A as ผู้ส่ง (Node A)
    actor B as คนเดินสาร (Node B / Mule)
    actor C as ผู้รับปลายทาง (Node C)

    Note over A,C: โหนด C ออฟไลน์อยู่นอกรัศมีวิทยุ (ติดต่อตรงไม่ได้)
    Note over A,B: โหนด A เชื่อมต่อบลูทูธอยู่กับโหนด B
    
    A->>A: ตรวจพบ C ออฟไลน์ -> แสดง Modal ให้เลือกระหว่าง<br/>[ฝากคนเดินสาร (Data Mule)] หรือ [รอส่งเอง (Store & Forward)]
    A->>A: ผู้ใช้เลือกฝากคนเดินสาร -> เข้ารหัสลับ E2EE สำหรับ C<br/>สร้างซองจดหมาย MuleEnvelope (Zero-Knowledge)
    A->>B: DISPATCH Packet (ส่งซองจดหมายให้ B ผ่าน Nearby BYTES)
    Note over B: ตรวจสอบความถูกต้อง บันทึกลงตาราง mule_envelopes<br/>อัปเดตไอคอนกระเป๋า 🎒 และแจ้งเตือนในเครื่อง B
    B-->>A: DISPATCH_ACK Packet
    Note over A: ปรับปรุงสถานะข้อความเป็น MULE_CARRIED (🎒)

    Note over B: โหนด B เดินทางข้ามพื้นที่ทางกายภาพ (Physical Mobility)...
    Note over B,C: โหนด B เข้าสู่รัศมีของโหนด C (ตรวจพบผ่าน Nearby Connection / PEER_ANNOUNCE)

    Note over B: Auto-Handover Trigger:<br/>ตรวจพบซองในกระเป๋าที่มี recipientNodeId ตรงกับ C
    B->>C: DELIVER Packet (ส่งมอบซองจดหมายให้ C โดยอัตโนมัติ)
    Note over C: ตรวจสอบความถูกต้อง ถอดรหัสลับ E2EE ด้วยกุญแจของตน<br/>แสดงข้อความและเด้งการแจ้งเตือนบนหน้าจอ C ทันที
    C-->>B: DELIVER_ACK Packet (ส่งใบเสร็จยืนยันถึง C แล้ว)
    Note over B: B ลบซองจดหมายออกจาก SQLite (Purge Envelope)<br/>อัปเดตตัวเลขบนกระเป๋า 🎒 และแจ้งเตือนส่งมอบสำเร็จ
```
<div align="center"><b>รูปที่ 3.3: แผนผังลำดับการทำงานของโปรโตคอลคนเดินสาร (Data Mule End-to-End Workflow)</b></div>

---

### 3.4.3 วงจรชีวิตของสถานะข้อความ (Message & Delivery State Lifecycle)

เพื่อให้ผู้ใช้งานทราบสถานะการเดินทางของข้อความได้อย่างแม่นยำ ระบบได้ออกแบบวงจรชีวิตของสถานะข้อความ (Message State Machine) ดังแสดงในรูปที่ 3.4:

```mermaid
stateDiagram-v2
    [*] --> SENDING: ผู้ใช้กดส่งข้อความ / บันทึกลงฐานข้อมูล SQLite
    
    SENDING --> DELIVERED: กรณีปลายทางออนไลน์ (Direct/Multi-Hop)<br/>ได้รับ Unicast ACK กลับมา
    
    SENDING --> MULE_CARRIED: กรณีปลายทางออฟไลน์ และเลือกฝากคนเดินสาร<br/>คนเดินสารส่ง DISPATCH_ACK ยืนยันการรับฝาก (🎒)
    
    MULE_CARRIED --> DELIVERED: คนเดินสารเดินไปพบปลายทาง และส่งมอบสำเร็จ<br/>ปลายทางส่ง DELIVER_ACK ตอบรับ
    
    DELIVERED --> READ: ผู้รับปลายทางเปิดอ่านข้อความในห้องแชท (Read Receipt)
    
    SENDING --> SENDING: กรณีเลือก 'รอส่งเองเมื่อพบกัน'<br/>ข้อความค้างใน pending_messages จนกว่าจะพบกันเอง
```
<div align="center"><b>รูปที่ 3.4: แผนภาพสถานะวงจรชีวิตของข้อความ (Message Delivery State Lifecycle)</b></div>

---

### 3.4.4 สถาปัตยกรรมความปลอดภัย Zero-Knowledge E2EE สำหรับคนเดินสาร

```mermaid
flowchart TD
    subgraph SenderNode["โหนด A (ผู้ส่งต้นทาง)"]
        Plaintext["เนื้อหาข้อความ: 'ขอความช่วยเหลือฉุกเฉิน'"]
        PubKeyC["กุญแจสาธารณะ X25519 ของ C"]
        ECDH_A["X25519 ECDH Key Exchange\n+ HKDF Key Derivation"]
        AES_GCM_A["เข้ารหัสลับข้อมูล\nAES-256-GCM + IV + AuthTag"]
        Sign_A["เซ็นลายเซ็นดิจิทัล\nDigital Signature (Ed25519)"]
        Envelope["ประกอบซองจดหมาย MuleEnvelope\n[Ciphertext + Nonce + Signature]"]
        
        Plaintext & PubKeyC --> ECDH_A --> AES_GCM_A --> Sign_A --> Envelope
    end

    subgraph CarrierNode["โหนด B (คนเดินสาร: Zero-Knowledge Carrier)"]
        CarrierBag["กระเป๋าเก็บซองจดหมาย (SQLite mule_envelopes)\n⚠️ มองเห็นเฉพาะ Ciphertext ข้อมูลที่ถูกเข้ารหัส\n❌ ไม่สามารถถอดรหัสหรือแอบอ่านข้อความได้"]
    end

    subgraph RecipientNode["โหนด C (ผู้รับปลายทาง)"]
        PrivKeyC["กุญแจส่วนตัว X25519 ของ C"]
        Verify_C["ตรวจสอบลายเซ็นผู้ส่ง (Verify Signature)"]
        ECDH_C["X25519 ECDH คำนวณ Shared Secret"]
        AES_GCM_C["ถอดรหัสลับ AES-256-GCM\nตรวจสอบความถูกต้องของ Auth Tag"]
        Decrypted["ข้อความต้นฉบับแสดงบนหน้าจอ:\n'ขอความช่วยเหลือฉุกเฉิน'"]
        
        PrivKeyC --> ECDH_C
        CarrierBag -- "ส่งมอบซอง (Auto-Handover)" --> Verify_C --> ECDH_C --> AES_GCM_C --> Decrypted
    end

    Envelope -- "DISPATCH Packet" --> CarrierBag
```
<div align="center"><b>รูปที่ 3.5: สถาปัตยกรรมความปลอดภัย Zero-Knowledge E2EE ในระบบคนเดินสาร Data Mule</b></div>

---

### 3.4.5 กลไกการตรวจวัดสถานะโหนดแบบพลวัต (Dynamic Topology Adaptation & Anti-Ghosting)

เพื่อป้องกันปัญหาโหนดค้าง (Ghost Node) อันเนื่องมาจากการปิดบลูทูธกะทันหัน หรือการเดินหลุดจากระยะโดยที่ระบบปฏิบัติการไม่ส่งเหตุการณ์แจ้งเตือนตัดการเชื่อมต่อ ระบบ BANTAWAN ได้ใช้กลไกการตรวจสอบสถานะการมีอยู่จริงของโหนด (Liveness Verification Engine) ดังแสดงในรูปที่ 3.6:

```mermaid
flowchart TD
    Start["ตรวจสอบสถานะโหนด (getPeerConnectionStatus)"] --> CheckConnected{"ตาราง connectedDevices<br/>ของเครื่องเราว่างเปล่าหรือไม่?"}
    
    CheckConnected -- "ว่างเปล่า (ไม่มีใครต่ออยู่เลย)" --> Offline1["โหนดทั้งหมดในระบบเป็น Offline ทันที"]
    
    CheckConnected -- "มีอุปกรณ์เชื่อมต่ออยู่" --> CheckHop{"โหนดเป้าหมายเป็นระยะกี่ Hop?"}
    
    CheckHop -- "Hop 1 (Direct BLE)" --> CheckHeartbeat1{"เวลา lastSeen เกิน 20 วินาที<br/>หรือไม่มี endpointId ตรงในตาราง?"}
    CheckHeartbeat1 -- "ใช่ (เงียบหายเกินเกณฑ์)" --> Offline2["ตั้งสถานะเป็น Offline (แก้ปัญหาปิดบลูทูธค้าง)"]
    CheckHeartbeat1 -- "ไม่ใช่ (ยังได้รับสัญญาณต่อเนื่อง)" --> DirectOnline["สถานะ: Direct Online (1-Hop)"]
    
    CheckHop -- "Hop 2+ (Multi-Hop Mesh)" --> CheckReachable{"isReachable == true<br/>และ lastSeen ไม่เกิน 45 วินาที?"}
    CheckReachable -- "ไม่ผ่านเงื่อนไข" --> Offline3["ตั้งสถานะเป็น Offline"]
    CheckReachable -- "ผ่านเงื่อนไข" --> CheckReverse{"Reverse Path Endpoint<br/>ยังเชื่อมต่ออยู่กับเครื่องเราหรือไม่?"}
    CheckReverse -- "หลุดไปแล้ว" --> Offline4["ตั้งสถานะเป็น Offline (สะพานทางผ่านขาด)"]
    CheckReverse -- "ยังต่ออยู่สมบูรณ์" --> RelayedOnline["สถานะ: Relayed Online (Multi-Hop)"]
```
<div align="center"><b>รูปที่ 3.6: โฟลว์ชาร์ตการประเมินสถานะการเชื่อมต่อโหนดแบบพลวัตเพื่อป้องกันปัญหา Ghost Node</b></div>

---

## 3.5 สรุปบทที่ 3

ในบทนี้ได้นำเสนอระเบียบวิธีวิจัย แผนการดำเนินงานตลอด 17 สัปดาห์ การออกแบบสถาปัตยกรรมระบบ 4 เลเยอร์หลักตามมาตรฐานวิศวกรรมซอฟต์แวร์ การออกแบบโครงสร้างฐานข้อมูล SQLite V6 พร้อมพจนานุกรมข้อมูล (Data Dictionary) ครบทั้ง 5 ตารางหลัก รวมถึงการลงลึกในรายละเอียดทางเทคนิคของโปรโตคอลการสื่อสารไร้สายทั้ง 3 มิติ: (1) Multi-Hop Relay ควบคุมด้วย TTL และ Unicast ACK, (2) ระบบคนเดินสาร Data Mule แบบ Store-Carry-and-Forward พร้อมกลไกส่งมอบอัตโนมัติ (Auto-Handover), และ (3) สถาปัตยกรรมความมั่นคงปลอดภัยแบบ Zero-Knowledge E2EE V5 ตลอดจนกลไกขจัด Ghost Node เชิงพลวัต ซึ่งเป็นรากฐานสำคัญในการทดสอบและวัดผลสัมฤทธิ์ใน **บทที่ 4** ต่อไป

