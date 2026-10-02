# สถาปัตยกรรมระบบ (System Architecture & Flows) - BANTAWAN

เอกสารนี้แสดงรายละเอียดโครงสร้างสถาปัตยกรรมทางซอฟต์แวร์ โครงสร้างของข้อมูล และแผนภาพลำดับการทำงาน (Sequence/Data Flow) ของแต่ละระบบย่อยในแอปพลิเคชัน BANTAWAN/SOS Premier ทั้งหมด

---

## 🏛️ 1. สถาปัตยกรรมซอฟต์แวร์ (Software Architecture)

BANTAWAN พัฒนาขึ้นโดยอ้างอิงสถาปัตยกรรมแบบ **Clean MVVM-Service Pattern** ซึ่งแบ่งขอบเขตหน้าที่การทำงาน (Separation of Concerns) ออกเป็นชั้นชั้นอย่างชัดเจน เพื่อประสิทธิภาพการทำงานสูงสุดและการป้องกันข้อบกพร่องเรื่องวงจรชีวิตหน่วยความจำ (Memory Lifecycle Bugs)

### แผนภาพสถาปัตยกรรมภาพรวม (System Architecture Layers)

```mermaid
graph TD
    subgraph UI_Presentation_Layer [Presentation Layer]
        Screens[Screens - UI Layouts]
        Widgets[Custom Widgets - Visualizers / Painters]
    end

    subgraph State_Management_Layer [State Management Layer]
        Provider[Providers - ChangeNotifier ViewModels]
    end

    subgraph Business_Service_Layer [Business & Hardware Service Layer]
        Services[Singleton Services - Shared Instances]
    end

    subgraph Infrastructure_Layer [Infrastructure & Device Layer]
        APIs[External Web APIs - OSRM / Overpass / Meteo]
        Sensors[Device HW - GPS / Bluetooth / Flashlight]
        Storage[Local Storage - Shared Preferences]
    end

    Screens -->|Listen / Watch| Provider
    Widgets -->|Trigger Action| Provider
    Provider -->|Invoke Methods| Services
    Services -->|Fetch Data| APIs
    Services -->|Read/Write| Storage
    Services -->|Control Sensors| Sensors
```

---

## 📂 2. โครงสร้างโฟลเดอร์โครงการ (Folder Structure)

ซอร์สโค้ดในไดเรกทอรี `lib/` มีการจัดโครงสร้างอย่างเป็นระบบตามขอบเขตการทำงานของสถาปัตยกรรม MVVM-Service:

```mermaid
graph TD
    lib[lib/] --> main[main.dart - App Entrypoint]
    lib --> l10n[l10n/ - ภาษาของระบบ]
    lib --> navigation[navigation/ - การนำทางหลัก]
    lib --> providers[providers/ - ตัวจัดการสถานะ ViewModels]
    lib --> screens[screens/ - หน้าจอ UI ฟีเจอร์]
    lib --> services[services/ - ตรรกะบริการระดับล่าง]
    lib --> widgets[widgets/ - คอมโพเนนต์และ Painters]

    providers --> map_p[map_provider.dart]
    providers --> prof_p[profile_provider.dart]

    widgets --> map_w[map/ - วิดเจ็ตแผนที่]
```

---

## ⚡ 3. การจัดการสถานะ (State Management)

แอปพลิเคชันนี้ใช้ **Provider Pattern** ในการบริหารจัดการสถานะและการไหลของข้อมูลแบบ Reactive เมื่อ State ใน ViewModels เปลี่ยนแปลง จะเกิดกระบวนการ Rebuild UI ทันทีผ่านตัวฟัง (`Consumer` หรือ `context.watch`) และคำสั่งแจ้งเตือน (`notifyListeners`)

### แผนภาพวงจรการจัดการสถานะ (State Lifecycle Loop)

```mermaid
sequenceDiagram
    autonumber
    Widget/Screen UI->>Provider ViewModel: 1. ผู้ใช้เรียกใช้คำสั่งผ่าน UI (e.g. กดปุ่ม)
    Provider ViewModel->>Singleton Service: 2. เรียกประมวลผลคำสั่งทางตรรกะหรือฮาร์ดแวร์
    Singleton Service-->>Provider ViewModel: 3. ส่งข้อมูลผลลัพธ์กลับมายัง ViewModel
    Provider ViewModel->>Provider ViewModel: 4. ปรับปรุงตัวแปรภายใน (Internal States)
    Provider ViewModel->>Widget/Screen UI: 5. เรียก notifyListeners() สั่ง Rebuild Widgets ที่คอยฟังอยู่
```

---

## ⚙️ 4. บริการระดับล่าง (Services)

คลาสในชั้น **Services** ทั้งหมดถูกออกแบบในลักษณะ **Singleton Pattern** (ใช้งานผ่านคีย์เวิร์ดคอนสตรัคเตอร์แบบ `static final`) เพื่อทำหน้าที่เป็นจุดประสานงานร่วมชิ้นเดียวตลอดอายุการใช้งานของแอป ป้องกันปัญหาการล้างทำลายหน่วยความจำจาก Provider เผลอเรียก `dispose` 

### ความสัมพันธ์ระหว่าง Singleton Services

```mermaid
classDiagram
    class NearbyService {
        +static instance
        +init()
        +startEmergencyNetwork()
        +sendSOSBroadcast()
    }
    class EmergencyToolService {
        +static instance
        +playSiren()
        +stopSiren()
        +startMorseSOS()
    }
    class MapOfflineService {
        +static instance
        +downloadAreaTiles()
        +cancelDownload()
    }
    class HikeService {
        +static instance
        +startHike()
        +stopHike()
    }
    class ConnectivityService {
        +static instance
        +checkConnectivity()
    }

    NearbyService ..> ConnectivityService : "แชร์ข้อมูลเน็ต"
    MapOfflineService ..> HikeService : "บันทึกพิกัดดาวน์โหลด"
```

---

## 📊 5. ตัวจัดการสถานะระดับบน (Providers)

ทำหน้าที่เป็นตัวกลางระหว่าง UI และ Services โดยเก็บตัวแปรที่ใช้เรนเดอร์ UI และควบคุมขั้นตอนการอัปเดตหน้าจอ

*   **MapProvider**: ทำการดึงและประมวลผลเส้นทาง GPS, นำทาง OSRM, ข้อมูลโรงพยาบาล Overpass และวาดมาร์กเกอร์ (Markers) บนแผนที่
*   **ProfileProvider**: จัดเก็บข้อมูล Medical ID (หมู่โลหิต โรคประจำตัว) และประสานงานส่งข้อมูลอัปเดตไปที่ระบบแชท P2P เมื่อมีการแก้ไขข้อมูลผู้ใช้

### การผูกการทำงานของ Providers และ Services

```mermaid
graph LR
    UI[หน้าจอแอป] -->|ดึงข้อมูลมาแสดง| MapProvider
    MapProvider -->|ประมวลผลเส้นทาง/พิกัด| MapOfflineService
    MapProvider -->|ค้นหาระบุตำแหน่งโรงพยาบาล| OverpassService
    MapProvider -->|เรียกภาพแผนที่ประเทศไทย| LongdoService
```

---

## 🎨 6. วิดเจ็ตพิเศษและ Custom Painters (Widgets)

เพื่อส่งมอบประสบการณ์ผู้ใช้สไตล์ Tactical UI แอปพลิเคชันใช้ Custom Canvas Drawing ในการวาดแอนิเมชันระดับพิกเซล

*   **WeatherParticlePainter**: จัดทำละอองฝน/ละอองหิมะตามสภาพอากาศด้วยอนุภาคเคลื่อนไหวคณิตศาสตร์ฟังก์ชันไซน์
*   **TacticalButtonPainter**: วาดปุ่มชีพจรเรืองแสงนีออนไล่เฉดสี
*   **FirstAidVisualizer**: ทำแอนิเมชันวงแหวนจังหวะการกดหน้าอก CPR อ้างอิงตามจังหวะเวลาสากล

### แผนภาพการประมวลผลกราฟิก (Painter Repaint Flow)

```mermaid
graph TD
    WidgetState[Widget State / AnimationController] -->|ส่งค่าความคืบหน้า 0.0 - 1.0| CustomPaint[CustomPaint Widget]
    CustomPaint -->|สั่งวาดเฟรมถัดไป| CustomPainter[Canvas DrawCircle / DrawArc]
    CustomPainter -->|ประมวลผลตำแหน่งพิกัดใหม่| RenderTarget[แสดงผลทางจอภาพ]
```

---

## 🔄 7. ลำดับการไหลของข้อมูล (Data Flow)

เมื่อมีการแก้ไขโปรไฟล์ข้อมูลสุขภาพของผู้ใช้ การเปลี่ยนแปลงจะถูกส่งผ่านชั้นสถาปัตยกรรมเพื่ออัปเดตหน่วยความจำและแจ้งระบบแชท

```mermaid
graph TD
    A[หน้าจอแก้ไข Profile Screen] -->|กดบันทึก updateProfile| B[ProfileProvider]
    B -->|เขียนข้อมูลดิบลงดิสก์| C[ProfileService - SharedPreferences]
    B -->|แจ้งส่งสัญญาณเปลี่ยนข้อมูลคู่แชท| D[NearbyService - updateProfileInfo]
    D -->|ส่งสัญญาณแจ้ง listeners| E[UI ทุกหน้าจออัปเดตข้อมูลชีพจรใหม่]
```

---

## 🌐 8. ลำดับการทำงานของ API เครือข่าย (API Flow)

กระบวนการประมวลผลแผนที่และประเมินสภาพอากาศเมื่อผู้ใช้เชื่อมต่ออินเทอร์เน็ตปกติ:

```mermaid
sequenceDiagram
    autonumber
    Client App->>Open-Meteo Server: 1. ร้องขอสภาพอากาศ PM 2.5 อิงจากละติจูด/ลองจิจูด
    Open-Meteo Server-->>Client App: 2. ส่งข้อมูลอุณหภูมิและดัชนี UV (JSON Response)
    Client App->>Overpass API Server: 3. ร้องขอพิกัดโรงพยาบาลรอบตัวในระยะรัศมี
    Overpass API Server-->>Client App: 4. ส่งข้อมูลพิกัดละติจูด/ลองจิจูดของสถานที่ (OSM Format)
    Client App->>OSRM Route Server: 5. ส่งพิกัดต้นทางและปลายทางเพื่อสร้างเส้นทาง
    OSRM Route Server-->>Client App: 6. ส่งอาร์เรย์พิกัดจำแนกพิกัดสำหรับวาด Polyline เรืองแสง
```

---

## 💾 9. ลำดับการดาวน์โหลดแผนที่ออฟไลน์ (Offline Map Flow)

แอปพลิเคชันมีกลไกตรวจสอบพื้นที่จัดเก็บแผนที่ออฟไลน์ก่อนดึงข้อมูลภายนอกทุกครั้ง เพื่อประหยัดพลังงานและการเชื่อมต่อ:

```mermaid
graph TD
    Request[แอปเรียกใช้แผ่นแผนที่ Tile x/y/z] --> CheckLocal{มีไฟล์เก็บไว้ในเครื่อง?}
    CheckLocal -->|มีในดิสก์| ReadLocal[ดึงภาพ PNG จากเครื่องมาแสดงบนแผนที่ทันที]
    CheckLocal -->|ไม่มีในดิสก์| CheckNet{เชื่อมต่อเน็ตอยู่?}
    CheckNet -->|มีเน็ต| Download[ดาวน์โหลดแผ่นภาพผ่าน Server Longdo/OSM]
    Download --> SaveDisk[เซฟไฟล์บันทึกลงในเครื่อง]
    SaveDisk --> Show[นำภาพมาแสดงบนหน้าจอ]
    CheckNet -->|ออฟไลน์/ไม่มีเน็ต| DrawGrid[แสดงแผ่นตารางกริดจำลองเปล่า]
```

---

## 🚨 10. ลำดับการขอความช่วยเหลือฉุกเฉิน (SOS Flow)

สเตตแมชชีนและกระบวนการทำงานของปุ่มขอความช่วยเหลือฉุกเฉิน (SOS):

```mermaid
stateDiagram-v2
    [*] --> Idle : สภาพปกติ
    Idle --> Holding : ผู้ใช้กดปุ่ม SOS ค้างไว้
    Holding --> Countdown : กดค้างครบ 3 วินาทีสำเร็จ (กระตุ้นตัวนับ 5 วิ)
    Holding --> Idle : ปล่อยนิ้วมือกลางคัน (ยกเลิก)
    Countdown --> FinalSOS : นับถอยหลังเสร็จสิ้น 0 วินาที
    Countdown --> Idle : ผู้ใช้กดปุ่ม Cancel บนหน้าจอ
    FinalSOS --> [*] : ยิงสัญญาณไซเรน + อ่านออกเสียงภาษาไทย (TTS) + เปิดหน้าต่าง SMS ส่งพิกัด
```

---

## 📶 11. โครงสร้างเครือข่ายไร้อินเทอร์เน็ต (Mesh Network Handshake Flow)

กระบวนการสร้างเส้นทางแชทแบบจุดต่อจุด (Peer-to-Peer) ระหว่างสองอุปกรณ์เมื่อขาดการติดต่อจากโลกภายนอก:

```mermaid
sequenceDiagram
    autonumber
    actor NodeA as โหนดผู้ประสบภัย A (สแกน)
    actor NodeB as โหนดค้นหา B (กระจายสัญญาณ)

    NodeB->>NodeB: เปิดระบบกระจายสัญญาณ (Nearby Advertising)
    NodeA->>NodeA: เริ่มระบบสแกนคลื่นความถี่ (Nearby Discovery)
    NodeA->>NodeB: 1. ตรวจเจอสัญญาณ B ส่งคำขอเชื่อมต่อ (Connection Request)
    Note over NodeA, NodeB: มีข้อมูลชื่อเครื่องแฝงมา (Endpoint Name)
    NodeB-->>NodeA: 2. ตอบยอมรับการเชื่อมต่ออัตโนมัติ (Accept Connection)
    Note over NodeA, NodeB: สร้างท่อส่งข้อมูล P2P สำเร็จ
    NodeA->>NodeB: 3. ส่งข้อความหรือพิกัดปัจจุบัน (Bytes Payload - JSON)
    NodeB->>NodeB: 4. ประมวลผลพิกัด และกระตุ้นสั่นเตือนในเครื่อง (Local Alert)
```

---

## 📄 สัญญาอนุญาต (License)

*   ขณะนี้โปรเจกต์ **BANTAWAN** ยังไม่ได้มีการกำหนดประเภทของสัญญาอนุญาต (License) อย่างเป็นทางการเพื่อวัตถุประสงค์เชิงพาณิชย์ หรือการเผยแพร่แบบ Open-Source
