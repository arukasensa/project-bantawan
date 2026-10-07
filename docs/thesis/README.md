# โครงสร้างเล่มปริญญานิพนธ์ฉบับสมบูรณ์ (Complete Senior Project Thesis Package)
## ระบบสนับสนุนความปลอดภัยส่วนบุคคลบนสมาร์ตโฟน (Personal Safety Support for Smartphones)
### สาขาวิชาวิศวกรรมคอมพิวเตอร์ คณะวิศวกรรมศาสตร์ มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย
**ปีการศึกษา 2569 (Academic Year 2026)**

---

เอกสารในโฟลเดอร์นี้จัดทำขึ้นตามแบบฟอร์มและมาตรฐานวิชาการของสาขาวิชาวิศวกรรมคอมพิวเตอร์ มทร.ศรีวิชัย (อิงตามเล่มตัวอย่างของรุ่นพี่ที่ผ่านการประเมินจากคณะกรรมการสอบชุดเดียวกัน) โดยจัดแบ่งเป็นไฟล์ Markdown ที่สมบูรณ์แบบ เพื่อให้ง่ายต่อการคัดลอก (Copy-Paste) ลงในโปรแกรมประมวลผลคำ Microsoft Word หรือ LaTeX สำหรับส่งตรวจและเข้าเล่ม:

---

## 📑 สารบัญแฟ้มเอกสารเล่มปริญญานิพนธ์ (Thesis File Directory)

| ส่วนที่ / บทที่ | ชื่อเอกสาร (Document Title) | ลิงก์ไฟล์เอกสาร | รายละเอียดและองค์ประกอบสำคัญ |
| :---: | :--- | :---: | :--- |
| **ส่วนนำ** | **ส่วนประกอบตอนต้น (Preliminary Pages)** | [`00_FRONT_MATTER.md`](file:///f:/flutter1/flutter1/docs/thesis/00_FRONT_MATTER.md) | ปกนอก, ปกใน (ไทย/อังกฤษ), ใบอนุมัติ (กรรมการ 4 ท่าน), บทคัดย่อไทย (หน้า ข), ABSTRACT (หน้า ค), กิตติกรรมประกาศ (หน้า ง), สารบัญเนื้อหา (หน้า จ), สารบัญตาราง (หน้า ซ), สารบัญรูป (หน้า ฌ) |
| **บทที่ 1** | **บทนำ (Introduction)** | [`CHAPTER_1_INTRODUCTION.md`](file:///f:/flutter1/flutter1/docs/thesis/CHAPTER_1_INTRODUCTION.md) | ความเป็นมาและปัญหา, วัตถุประสงค์ 3 ข้อ, **ขอบเขตฟังก์ชันการทำงาน 10 ประการ**, ขอบเขตแพลตฟอร์ม (Android 5.0+), ข้อจำกัดของระบบ, และประโยชน์ที่คาดว่าจะได้รับ 5 ประการ |
| **บทที่ 2** | **ทฤษฎีและงานวิจัยที่เกี่ยวข้อง (Theoretical Background)** | [`CHAPTER_2_THEORETICAL_BACKGROUND.md`](file:///f:/flutter1/flutter1/docs/thesis/CHAPTER_2_THEORETICAL_BACKGROUND.md) | ทฤษฎีวิศวกรรม **8 หมวดหมู่ใหญ่ (2.1–2.8) + สรุป (2.9)**: Dart/Flutter, Android Studio, Mesh/DTN/Nearby, E2EE V5 Cryptography, GIS/Slippy Tiles/Haversine, **External APIs ทั้ง 6 ตัว (Overpass, Longdo, OSRM, Open-Meteo, SerpApi, Photon)**, เซนเซอร์ฮาร์ดแวร์/SQLite V6, การแพทย์ฉุกเฉิน/งานวิจัยที่เกี่ยวข้อง, ตารางเปรียบเทียบ 13 มิติ, และ **บรรณานุกรม IEEE [1]–[58]** |
| **บทที่ 3** | **วิธีการดำเนินงานและสถาปัตยกรรมระบบ (Methodology)** | [`CHAPTER_3_METHODOLOGY.md`](file:///f:/flutter1/flutter1/docs/thesis/CHAPTER_3_METHODOLOGY.md) | **ตารางแผนงาน 17 สัปดาห์ (Gantt Chart)** สไตล์รุ่นพี่, **สถาปัตยกรรม 4 เลเยอร์หลัก** (Presentation, State Management, Business Logic, Data Source), **พจนานุกรมข้อมูล (Data Dictionary) SQLite V6 ครบทั้ง 5 ตาราง**, และผังโปรโตคอลเมช |
| **บทที่ 4** | **ผลการทดลองและการทดสอบระบบ (Experimental Results)** | [`CHAPTER_4_RESULTS_AND_TESTING.md`](file:///f:/flutter1/flutter1/docs/thesis/CHAPTER_4_RESULTS_AND_TESTING.md) | ผลการทดสอบการสื่อสารแบบเมชไร้เน็ต (อัตราส่งสำเร็จ 94.50%, Latency 1.42s ที่ 3 Hops, Unicast ACK ประหยัดแบนด์วิดท์ 81.50%), ผลการทดสอบ E2EE, แผนที่ออฟไลน์, การประหยัดแบตเตอรี่ด้วยจอภาพ OLED 63.80%, และชุดทดสอบอัตโนมัติ 7 รายการ |
| **บทที่ 5** | **สรุปผลการวิจัยและข้อเสนอแนะ (Conclusion & Future Work)** | [`CHAPTER_5_CONCLUSION_AND_FUTURE_WORK.md`](file:///f:/flutter1/flutter1/docs/thesis/CHAPTER_5_CONCLUSION_AND_FUTURE_WORK.md) | สรุปผลสัมฤทธิ์ของโครงงานทั้ง 10 ฟังก์ชัน, ข้อจำกัดทางวิศวกรรม (BLE Range, Android Platform), และข้อเสนอแนะทิศทางการพัฒนาต่อยอดในอนาคต |
| **ส่วนท้าย** | **ภาคผนวกและประวัติผู้จัดทำ (Appendices & CV)** | [`06_APPENDIX_AND_CV.md`](file:///f:/flutter1/flutter1/docs/thesis/06_APPENDIX_AND_CV.md) | ภาคผนวก ก: คู่มือติดตั้ง Flutter SDK & Android Studio, ภาคผนวก ข: คู่มือคำสั่งทดสอบระบบและสร้าง APK, ภาคผนวก ค: คู่มือการใช้งานแอปพลิเคชันและ QR Code, และ **ประวัติผู้จัดทำปริญญานิพนธ์ 2 ท่าน (นายตะวัน ระเหม และ นายฟารุก เส็นส๊ะ)** ตามแบบฟอร์ม มทร.ศรีวิชัย |

---

### 💡 คำแนะนำสำหรับการจัดพิมพ์เล่มรายงาน (Thesis Formatting Instructions):
1. **แบบอักษรและขนาดตัวอักษร:** แนะนำให้ใช้ฟอนต์มาตรฐานภาษาไทยเชิงวิชาการ เช่น `TH Sarabun PSK` หรือ `Angsana New`
   * ชื่อบท: ขนาด 18 pt ตัวหนา จัดกึ่งกลางหน้ากระดาษ
   * หัวข้อใหญ่ (1.1, 2.1, etc.): ขนาด 16 pt ตัวหนา ชิดซ้าย
   * หัวข้อย่อย (2.1.1, etc.): ขนาด 16 pt ตัวหนา ย่อหน้า 0.5 นิ้ว
   * เนื้อหาทั่วไป: ขนาด 16 pt ตัวปกติ ชิดขอบซ้าย-ขวา (Justify)
2. **การจัดวางรูปภาพและตาราง:** 
   * ทุกรูปภาพและตารางมีหมายเลขและชื่อกำกับ สอดคล้องกับสารบัญรูป (หน้า ฌ) และสารบัญตาราง (หน้า ซ)
   * สามารถส่งออกแผนภาพ Mermaid เป็นภาพความละเอียดสูง (PNG/SVG) ผ่าน [Mermaid Live Editor](https://mermaid.live) แล้วนำมาแทรกในเอกสาร
3. **การอ้างอิงเอกสาร:** รายการบรรณานุกรมในเนื้อหาใช้ระบบตัวเลข `[1]` ถึง `[58]` ตามมาตรฐานสากลของ **IEEE Citation Style** ถูกต้องครบถ้วนทั้งหมด
