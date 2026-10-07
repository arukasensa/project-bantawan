# ภาคผนวกและประวัติผู้จัดทำปริญญานิพนธ์
## โครงงาน: ระบบสนับสนุนความปลอดภัยส่วนบุคคลบนสมาร์ตโฟน (Personal Safety Support for Smartphones)
### สาขาวิชาวิศวกรรมคอมพิวเตอร์ คณะวิศวกรรมศาสตร์ มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย
**ปีการศึกษา 2569 (Academic Year 2026)**

---

## ภาคผนวก ก
### การเตรียมสภาพแวดล้อมการพัฒนาและคู่มือการติดตั้ง (Environment Setup Guide)

#### ก.1 การติดตั้งและกำหนดค่า Flutter SDK และ Dart SDK
1. ทำการดาวน์โหลด Flutter SDK เวอร์ชัน `^3.10.4` จากเว็บไซต์ทางการ [https://flutter.dev](https://flutter.dev)
2. แตกไฟล์ซิปไปยังไดเรกทอรีที่ต้องการ เช่น `C:\src\flutter`
3. เพิ่มตัวแปรสภาพแวดล้อม (Environment Variables) ของระบบในส่วน `PATH`:
   ```bash
   set PATH=%PATH%;C:\src\flutter\bin
   ```
4. ตรวจสอบความสมบูรณ์ของการติดตั้งและเครื่องมือที่จำเป็นด้วยคำสั่ง:
   ```bash
   flutter doctor -v
   ```

#### ก.2 การกำหนดค่า Android Studio และ Android SDK
1. ติดตั้งโปรแกรม Android Studio พร้อมชุดเครื่องมือ Android SDK Platform-Tools และ Android SDK Build-Tools
2. กำหนดระดับ API Level ในไฟล์ `android/app/build.gradle`:
   * `minSdkVersion 21` (Android 5.0 Lollipop)
   * `compileSdkVersion 34` (Android 14 UpsideDownCake)
   * `targetSdkVersion 34`
3. กำหนดสิทธิ์การเข้าถึงอุปกรณ์ (Hardware Permissions) ในไฟล์ `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <!-- สิทธิ์บลูทูธและเครือข่ายไร้สายระยะใกล้สำหรับ Nearby Connections -->
   <uses-permission android:name="android.permission.BLUETOOTH" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
   <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
   <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />

   <!-- สิทธิ์พิกัดดาวเทียม GNSS และเซนเซอร์ -->
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

   <!-- สิทธิ์ฮาร์ดแวร์ฉุกเฉินและไฟฉาย -->
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.FLASHLIGHT" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.VIBRATE" />
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
   ```

---

## ภาคผนวก ข
### คู่มือชุดคำสั่งการทดสอบระบบและสร้างไฟล์ติดตั้ง (Test & Build Execution Guide)

#### ข.1 คำสั่งการวิเคราะห์คุณภาพโค้ดและการทดสอบอัตโนมัติ
ก่อนทำการคอมไพล์ระบบเพื่อนำไปใช้งาน ผู้พัฒนาสามารถรันชุดคำสั่งทดสอบอัตโนมัติผ่านเทอร์มินัล:

1. **คำสั่งตรวจสอบคุณภาพโค้ดตามมาตรฐาน lints:**
   ```bash
   flutter analyze
   ```
2. **คำสั่งรันชุดทดสอบอัตโนมัติ Unit & Service Tests ทั้งหมด 7 ชุด:**
   ```bash
   flutter test
   ```
3. **คำสั่งรันชุดทดสอบเฉพาะโมดูลการเข้ารหัสลับ (CryptoMeshService Test):**
   ```bash
   flutter test test/features/chat/domain/services/crypto_mesh_service_test.dart
   ```
4. **คำสั่งรันชุดทดสอบโมดูลการจำแนกสถานพยาบาล (Classifier Test):**
   ```bash
   flutter test test/core/utils/medical_facility_classifier_test.dart
   ```

#### ข.2 คำสั่งสร้างไฟล์แพ็กเกจติดตั้งสำหรับอุปกรณ์ Android (Release Build)
สร้างไฟล์ติดตั้งแบบ APK (Android Application Package) ที่ผ่านการเพิ่มประสิทธิภาพด้วย R8:
```bash
flutter build apk --release --split-per-abi
```
ผลลัพธ์ไฟล์ติดตั้งจะถูกสร้างไว้ที่ไดเรกทอรี `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` พร้อมสำหรับนำไปติดตั้งบนสมาร์ตโฟนเพื่อใช้งานจริง

---

## ภาคผนวก ค
### คู่มือการใช้งานแอปพลิเคชัน BANTAWAN (User Manual)

#### ค.1 ขั้นตอนการเปิดใช้งานระบบครั้งแรก
1. เปิดแอปพลิเคชัน BANTAWAN ระบบจะร้องขอสิทธิ์การเข้าถึงบลูทูธ (Bluetooth), พิกัดตำแหน่ง (Location) และการแจ้งเตือน ให้ผู้ใช้กด **"อนุญาตตลอดเวลา"** หรือ **"ขณะใช้แอป"**
2. บันทึกข้อมูลส่วนบุคคลในหน้าต่าง **Medical ID** (กรุ๊ปเลือด โรคประจำตัว เบอร์ติดต่อญาติ) เพื่อความปลอดภัยในภาวะฉุกเฉิน

#### ค.2 ขั้นตอนการส่งสัญญาณขอความช่วยเหลือฉุกเฉิน (SOS Activation)
1. เมื่อเกิดเหตุคับขัน แตะปุ่มวงกลมสีแดง **"SOS ฉุกเฉิน"** บนหน้าจอหลักค้างไว้ต่อเนื่องเป็นเวลา **3 วินาที**
2. ระบบจะเริ่มนับถอยหลังพร้อมแถบความคืบหน้า เมื่อครบ 3 วินาที ระบบจะส่งสัญญาณฉุกเฉินผ่าน 3 ช่องทางพร้อมกันทันที:
   * ยิงแพ็กเก็ตฉุกเฉินกระจายผ่านเครือข่ายเมช (Mesh Broadcast) ไปยังสมาร์ตโฟนทุกคนในบริเวณใกล้เคียง
   * เปิดระบบไฟฉายแฟลชกะพริบรหัสมอร์ส SOS (`... --- ...`)
   * ส่งเสียงไซเรนเตือนภัยความถี่สูง และเตรียมข้อความ SMS พิกัดดาวเทียมเพื่อส่งหาเบอร์ติดต่อฉุกเฉิน

#### ค.3 ขั้นตอนการใช้งานแผนที่และค้นหาสถานพยาบาลแบบออฟไลน์
1. เข้าสู่เมนู **"แผนที่" (Map)** จากแถบนำทางด้านล่าง
2. ระบบจะระบุพิกัดปัจจุบันของผู้ใช้ และแสดงหมุดสถานพยาบาล โรงพยาบาล และคลินิกที่ใกล้ที่สุดโดยอัตโนมัติ
3. หากอยู่ในสภาวะไม่มีอินเทอร์เน็ต ระบบจะคำนวณระยะทางตรง (Haversine) พร้อมแสดงลูกศรเข็มทิศชี้ตรงไปยังสถานพยาบาลเป้าหมาย (Bearing Arrow) และประมาณเวลาเดินเท้าให้ทราบทันที

<br>
<div align="center">

```
             ┌────────────────────────────────────────┐
             │                                        │
             │         [ภาพจำลอง QR Code]             │
             │   สแกนเพื่อดาวน์โหลดคู่มือการใช้งาน      │
             │         และวิดีโอสาธิตระบบ             │
             │                                        │
             └────────────────────────────────────────┘
```
**รูปที่ ค.1: รหัสคิวอาร์สำหรับเข้าถึงคู่มือการใช้งานระบบและวิดีโอสาธิตการทำงาน**

</div>

---

## ประวัติผู้จัดทำปริญญานิพนธ์ (Curriculum Vitae)

<br>

<div align="center">

```
                       ┌─────────────────────────┐
                       │                         │
                       │       รูปถ่ายขนาด       │
                       │        1.5 นิ้ว         │
                       │     (นายตะวัน ระเหม)     │
                       │                         │
                       └─────────────────────────┘
```

</div>

**ชื่อ-สกุล:** นายตะวัน ระเหม  
**รหัสนักศึกษา:** 166404140064  
**สาขาวิชา:** วิศวกรรมคอมพิวเตอร์  
**คณะ:** วิศวกรรมศาสตร์  
**สถาบัน:** มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย  
**ประวัติการศึกษา:**  
* พ.ศ. 2565: สำเร็จการศึกษาระดับประกาศนียบัตรวิชาชีพชั้นสูง (ปวส.) หรือมัธยมศึกษาตอนปลาย  
* พ.ศ. 2566–2569: ศึกษาหลักสูตรวิศวกรรมศาสตรบัณฑิต สาขาวิชาวิศวกรรมคอมพิวเตอร์ คณะวิศวกรรมศาสตร์ มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย  

<br>
<hr style="border: 1px dashed #ccc;">
<br>

<div align="center">

```
                       ┌─────────────────────────┐
                       │                         │
                       │       รูปถ่ายขนาด       │
                       │        1.5 นิ้ว         │
                       │     (นายฟารุก เส็นส๊ะ)    │
                       │                         │
                       └─────────────────────────┘
```

</div>

**ชื่อ-สกุล:** นายฟารุก เส็นส๊ะ  
**รหัสนักศึกษา:** 166404140074  
**สาขาวิชา:** วิศวกรรมคอมพิวเตอร์  
**คณะ:** วิศวกรรมศาสตร์  
**สถาบัน:** มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย  
**ประวัติการศึกษา:**  
* พ.ศ. 2565: สำเร็จการศึกษาระดับประกาศนียบัตรวิชาชีพชั้นสูง (ปวส.) หรือมัธยมศึกษาตอนปลาย  
* พ.ศ. 2566–2569: ศึกษาหลักสูตรวิศวกรรมศาสตรบัณฑิต สาขาวิชาวิศวกรรมคอมพิวเตอร์ คณะวิศวกรรมศาสตร์ มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย  
