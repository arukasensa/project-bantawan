# คู่มือการเตรียมแอปสำหรับจำหน่ายและปล่อยขึ้นสโตร์ (Deployment Guide)

คู่มือนี้แนะนำขั้นตอนการสร้างไฟล์ Release สำหรับติดตั้งบนเครื่องเป้าหมายและขึ้นบัญชี App Store / Google Play Store สำหรับแอปพลิเคชัน **BANTAWAN**

---

## 1. การเตรียมส่งออกสำหรับระบบปฏิบัติการ Android

ฝั่ง Android ต้องการการลงลายมือชื่อดิจิทัล (Application Signing) เพื่อยืนยันตัวตนเจ้าของสิทธิ์แอปก่อนเปิดใช้งานจริง

### ขั้นตอนที่ 1: สร้างไฟล์กุญแจเข้ารหัส (Keystore)
เปิด Terminal และใช้คำสั่ง `keytool` (ต้องติดตั้ง Java SDK ล่วงหน้า) เพื่อสร้างกุญแจลายมือชื่อ:
```bash
keytool -genkey -v -keystore android/app/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```
*(ระบบจะให้ป้อนข้อมูลยืนยันตัวตนและตั้งรหัสผ่าน กรุณาจำรหัสผ่านนี้ไว้)*

### ขั้นตอนที่ 2: ตั้งค่ากุญแจเข้ารหัสในแอปพลิเคชัน
สร้างไฟล์ความลับตัวแปรชื่อ `key.properties` ไว้ในโฟลเดอร์ `android/` ของโปรเจกต์ และป้อนข้อมูลดังนี้:
```properties
storePassword=รหัสผ่านที่คุณตั้งตอนสร้าง
keyPassword=รหัสผ่านที่คุณตั้งตอนสร้าง
keyAlias=key
storeFile=key.jks
```

### ขั้นตอนที่ 3: ปรับแก้โครงสร้าง Gradle การลงชื่อ (android/app/build.gradle)
เปิดไฟล์ [android/app/build.gradle](file:///f:/flutter1/flutter1/android/app/build.gradle) และปรับโครงสร้างการลงชื่อ Release:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true // ช่วยย่อขนาดโค้ดและลบโค้ดไม่ได้ใช้
            shrinkResources true
        }
    }
}
```

### ขั้นตอนที่ 4: คอมไพล์โปรเจกต์
รันคำสั่งส่งออกแอปพลิเคชันในรูปแบบที่ต้องการ:
*   **สำหรับแจกแจงไฟล์ตรงติดตั้งลงเครื่องทั่วไป (APK)**:
    ```bash
    flutter build apk --release
    ```
    *(ไฟล์ติดตั้งจะอยู่ที่ `build/app/outputs/flutter-apk/app-release.apk`)*
*   **สำหรับอัปโหลดขึ้น Google Play Console (AAB)**:
    ```bash
    flutter build appbundle --release
    ```
    *(ไฟล์ติดตั้งจะอยู่ที่ `build/app/outputs/bundle/release/app-release.aab`)*

---

## 2. การเตรียมส่งออกสำหรับระบบปฏิบัติการ iOS

การปล่อยฝั่ง iOS จำเป็นต้องทำงานบนระบบ macOS และผ่านบัญชี Apple Developer Account

### ขั้นตอนที่ 1: ตั้งชื่อ Bundle Identifier และทีมพัฒนา
1.  เปิดเครื่องมือ Xcode และนำเข้าโฟลเดอร์ `ios/Runner.xcworkspace`
2.  ไปที่แท็บ **Runner** -> แท็บ **Signing & Capabilities**
3.  เลือกบัญชี **Team** และแก้ไขค่า **Bundle Identifier** ของคุณให้เป็นเอกลักษณ์เฉพาะ

### ขั้นตอนที่ 2: คอมไพล์และเปิดใช้งานหน้าคอนโซล App Store Connect
รันคำสั่งในโฟลเดอร์โปรเจกต์หลัก:
```bash
flutter build ipa --release
```
เมื่อคำสั่งรันเสร็จสิ้น ให้ใช้ **Xcode Organizer** เพื่อตรวจสอบรายละเอียดความเรียบร้อย แล้วจึงคลิกปุ่ม **Distribute App** เพื่อส่งแอปขึ้นสโตร์

---

## 3. ระบบแนบภาพแผนที่ล่วงหน้า (Pre-bundled Offline Map Tiles)

เพื่อแก้ปัญหาผู้ใช้งานดาวน์โหลดแอปเสร็จในที่ไม่มีเน็ต แล้วไม่สามารถดึงภาพแผนที่ตอนแรกสุดขึ้นมาแสดงได้ (เนื่องจากเครื่องยังไม่มีการเก็บรูปแผนที่ล่วงหน้า) ผู้พัฒนาสามารถทำระบบแนบภาพ (Pre-bundling) ได้ตามขั้นตอนดังนี้:

### ลำดับขั้นการทำงาน:
1.  ดาวน์โหลดภาพแผ่นแผนที่ (Tile png/webp) ของเมืองเป้าหมาย เช่น หาดใหญ่ หรือเชียงใหม่ ระดับความซูม 13 ถึง 15 (โครงสร้างโฟลเดอร์ย่อย: `{zoom}/{x}/{y}.png`)
2.  นำโฟลเดอร์ทั้งหมดไปจัดวางไว้ที่พาร์ท `assets/map_tiles/`
3.  ลงทะเบียนการเข้าถึงโฟลเดอร์ใน [pubspec.yaml](file:///f:/flutter1/flutter1/pubspec.yaml):
    ```yaml
    flutter:
      assets:
        - assets/map_tiles/
    ```
4.  ตั้งค่าให้ระบบเลือกแผนที่จาก Asset ท้องถิ่นแทนการโหลดจากอินเทอร์เน็ตเมื่อแอปตรวจสอบพบว่าเครือข่ายออฟไลน์:
    ```dart
    TileLayer(
      urlTemplate: isOffline
          ? 'assets/map_tiles/{z}/{x}/{y}.png'
          : 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      assetPrefix: isOffline ? '' : null,
    )
    ```
