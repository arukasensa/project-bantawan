# คู่มือการติดตั้งและเริ่มต้นใช้งาน (Installation Guide)

คู่มือนี้แนะนำขั้นตอนการเตรียมสภาพแวดล้อมทางเทคนิค ติดตั้งไลบรารี และรันแอปพลิเคชัน **BANTAWAN** บนเครื่องคอมพิวเตอร์สำหรับการพัฒนา

---

## 1. ความต้องการของระบบ (Prerequisites)

ก่อนเริ่มพัฒนาหรือรันแอปพลิเคชัน โปรดตรวจสอบว่าเครื่องคอมพิวเตอร์ของคุณติดตั้งซอฟต์แวร์ดังต่อไปนี้ครบถ้วน:

*   **Flutter SDK**: เวอร์ชั่น `^3.10.4` (แนะนำเวอร์ชั่น 3.10.x หรือ 3.13.x ในเสถียรภาพการคอมไพล์)
*   **Dart SDK**: จัดเตรียมมาพร้อมกับ Flutter SDK
*   **Java Development Kit (JDK)**: เวอร์ชั่น `17` (โปรเจกต์นี้มีโฟลเดอร์ `jdk-17` แนบอยู่ในโฟลเดอร์หลักของโปรเจกต์สำหรับใช้งานฝั่ง Android)
*   **Android Studio / Android SDK**: สำหรับสร้างและรันแอปพลิเคชันฝั่ง Android
*   **Xcode**: (สำหรับ macOS เท่านั้น) หากต้องการรันหรือทดสอบฝั่ง iOS

---

## 2. ขั้นตอนการติดตั้งและตั้งค่าโปรเจกต์ (Project Setup)

เปิดโปรแกรม Terminal หรือ PowerShell ในที่ตั้งโฟลเดอร์หลักของโปรเจกต์ (`f:/flutter1/flutter1/`) จากนั้นรันคำสั่งตามลำดับดังนี้:

### ขั้นที่ 1: ดึงไลบรารีและ Dependencies ทั้งหมด
รันคำสั่งดาวน์โหลดแพ็คเกจที่กำหนดไว้ใน [pubspec.yaml](file:///f:/flutter1/flutter1/pubspec.yaml):
```bash
flutter pub get
```

### ขั้นที่ 2: ตรวจสอบความถูกต้องของสภาวะการทำงาน
ตรวจดูสภาพแวดล้อมและโปรแกรมจำลองที่เชื่อมต่ออยู่:
```bash
flutter doctor
```

### ขั้นที่ 3: ตรวจสอบอุปกรณ์ที่พร้อมเชื่อมต่อ
แสดงรายชื่อของโปรแกรมจำลอง (Emulator) หรืออุปกรณ์เครื่องจริงที่เชื่อมต่ออยู่:
```bash
flutter devices
```

---

## 3. การรันแอปพลิเคชัน (Running the Application)

### การรันในโหมดพัฒนา (Debug Mode)
รันคำสั่งโดยระบบจะค้นหาอุปกรณ์ที่เหมาะสมโดยอัตโนมัติ:
```bash
flutter run
```

### การรันโดยระบุอุปกรณ์เจาะจง
หากมีอุปกรณ์เชื่อมต่อหลายเครื่อง ให้คัดลอกรหัสประจำเครื่องจากคำสั่ง `flutter devices` แล้วใช้งานคำสั่งนี้:
```bash
flutter run -d <DEVICE_ID>
```

### การเปิดระบบ Hot Reload
ขณะแก้ไขโค้ดและรันในโหมด Debug:
*   กด **`r`** ใน Terminal เพื่อทำการ **Hot Reload** (อัปเดตโค้ดอย่างรวดเร็วโดยไม่เสีย State)
*   กด **`R`** ใน Terminal เพื่อทำการ **Hot Restart** (เริ่มระบบ State ใหม่ทั้งหมด)

---

## 4. การจัดการสิทธิ์การเข้าถึงอุปกรณ์ (OS Permissions Setup)

แอปพลิเคชันช่วยเหลือฉุกเฉินต้องการการเข้าถึงเซ็นเซอร์ระดับต่ำของอุปกรณ์หลายชิ้น ซึ่งได้รับการตั้งค่าแล้วในระบบและต้องระบุให้ชัดเจน:

### ฝั่ง Android (ระบุใน `android/app/src/main/AndroidManifest.xml`)
ความต้องการสิทธิ์ในการใช้งานฟังก์ชันต่าง ๆ:
1.  **การระบุพิกัดนำทาง (GPS)**:
    *   `android.permission.ACCESS_FINE_LOCATION` (ระบุพิกัดความละเอียดสูง)
    *   `android.permission.ACCESS_COARSE_LOCATION` (ระบุพิกัดหยาบ)
    *   `android.permission.ACCESS_BACKGROUND_LOCATION` (สำหรับนับเวลาเช็คอินกรณีอยู่นอกแอป)
2.  **การสื่อสารแบบไร้เน็ต (Mesh Nearby)**:
    *   `android.permission.BLUETOOTH`
    *   `android.permission.BLUETOOTH_ADMIN`
    *   `android.permission.ACCESS_WIFI_STATE`
    *   `android.permission.CHANGE_WIFI_STATE`
    *   *สิทธิ์พิเศษสำหรับ Android 12 ขึ้นไป*:
        *   `android.permission.BLUETOOTH_SCAN` (สแกนหาเครื่องรอบตัว)
        *   `android.permission.BLUETOOTH_ADVERTISE` (กระจายสัญญาณแจ้งโหนดตัวเอง)
        *   `android.permission.BLUETOOTH_CONNECT` (เชื่อมต่อคุยแชทและแชร์พิกัด)
3.  **เครื่องมือฉุกเฉิน (Flashlight & Camera)**:
    *   `android.permission.CAMERA`
    *   `android.permission.FLASHLIGHT`

### ฝั่ง iOS (ระบุใน `ios/Runner/Info.plist`)
การขออนุมัติใช้งานในฝั่งของ Apple:
*   **พิกัดตำแหน่ง**:
    *   `NSLocationWhenInUseUsageDescription`
    *   `NSLocationAlwaysAndWhenInUseUsageDescription`
*   **ระบบบลูทูธ (Nearby Connections P2P)**:
    *   `NSBluetoothAlwaysUsageDescription`
    *   `NSBluetoothPeripheralUsageDescription`
*   **ควบคุมไฟฉายขอความช่วยเหลือ**:
    *   `NSCameraUsageDescription` (จำเป็นสำหรับการควบคุม Flashlight บน iOS)
