# รายละเอียดและสถานะฟีเจอร์ของระบบ (Feature Roadmap & Status) - BANTAWAN

เอกสารนี้ระบุรายละเอียดโครงสร้างของแต่ละฟีเจอร์ในระบบ หน้าจอที่เกี่ยวข้อง บริการเบื้องหลัง และสถานะการดำเนินการจริงในปัจจุบัน เพื่อติดตามแผนงานของแอปพลิเคชันอย่างเป็นระบบ

---

## ✅ 1. ฟีเจอร์ที่พัฒนาเสร็จสมบูรณ์แล้ว (Completed Features)

### 1.1 ระบบขอความช่วยเหลือฉุกเฉินบูรณาการ (Integrated SOS Command)
*   **คำอธิบาย (Description)**: ระบบช่วยเหลือในยามฉุกเฉินระดับวิกฤต โดยคุมความปลอดภัยผ่านการกดค้างปุ่ม SOS 3 วินาที จากนั้นจะมีตัวเลขนับถอยหลัง 5 วินาทีควบคู่เสียงไซเรนเตือนภัยสลับการอ่านออกเสียงช่วยเหลือด้วยภาษาไทย (TTS) และส่งข้อความ SMS พิกัดพิกัดละติจูด/ลองจิจูดพร้อมลิงก์ Google Maps นำวิถีหาเบอร์ติดต่อฉุกเฉินอัตโนมัติ
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [sos_screen.dart](file:///f:/flutter1/flutter1/lib/screens/sos_screen.dart), [emergency_contact_screen.dart](file:///f:/flutter1/flutter1/lib/screens/emergency_contact_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [emergency_tool_service.dart](file:///f:/flutter1/flutter1/lib/services/emergency_tool_service.dart), [emergency_contact_service.dart](file:///f:/flutter1/flutter1/lib/services/emergency_contact_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: ไม่มี (ควบคุมผ่าน State ภายใน StatefulWidget ร่วมกับ Services)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์ (ผ่านการล้างบั๊ก Provider Lifecycle และการทดสอบเสียง/สั่นครบถ้วน)
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: พัฒนาให้รองรับระบบส่งข้อความฉุกเฉินผ่านระบบสัญญาณวิทยุกู้ภัยข้ามย่านความถี่ (Ham Radio Integration)

### 1.2 ระบบแชทระบุพิกัดเครือข่ายบลูทูธปิด (Mesh P2P Chat & Offline Sharing)
*   **คำอธิบาย (Description)**: เครือข่ายการแชทส่งข้อความตัวหนังสือและแชร์ตำแหน่งภูมิศาสตร์ระหว่างผู้ประสบภัยหรือนักท่องเที่ยวในระยะ 100 เมตร โดยใช้สัญญาณ Bluetooth และ Wi-Fi Direct ไม่ผ่านอินเทอร์เน็ต สามารถนำตำแหน่งพิกัดของเพื่อนในช่องแชทไปแสดงผลนำทางบนแผนที่ได้ทันที
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [nearby_chat_screen.dart](file:///f:/flutter1/flutter1/lib/screens/nearby_chat_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [nearby_service.dart](file:///f:/flutter1/flutter1/lib/services/nearby_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: [profile_provider.dart](file:///f:/flutter1/flutter1/lib/providers/profile_provider.dart) (สำหรับการซิงค์ข้อมูล Medical ID)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์ (ผ่านการแก้ไขบั๊กจัดเก็บชื่อคู่แชทไม่ขึ้น และติดตั้ง Local Notification ประสานงานเมื่อพบโหนดใหม่)
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: พัฒนาระบบแชร์ไฟล์ภาพถ่ายพยานหลักฐานเหตุออฟไลน์ หรือข้อความเสียงสั้น (Voice Notes)

### 1.3 ระบบแผนที่ออฟไลน์และค้นหาโรงพยาบาล (Offline Map Tile Engine & Clinic Search)
*   **คำอธิบาย (Description)**: โหมดนำทางอัจฉริยะที่ใช้ข้อมูลจาก OpenStreetMap โดยออนไลน์จะทำการสแกนหาที่ตั้งสถานพยาบาลรอบตัวด้วย Overpass API และ OSRM เพื่อลากเส้น Polyline นำทาง ส่วนระบบออฟไลน์สามารถดาวน์โหลดรูปแผนที่พื้นที่ 10 ตร.กม. ลงหน่วยความจำเครื่อง และดึงมาสลับเรนเดอร์ได้แบบออฟไลน์
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [map_screen.dart](file:///f:/flutter1/flutter1/lib/screens/map_screen.dart), [hospital_detail_screen.dart](file:///f:/flutter1/flutter1/lib/screens/hospital_detail_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [map_offline_service.dart](file:///f:/flutter1/flutter1/lib/services/map_offline_service.dart), [hospital_service.dart](file:///f:/flutter1/flutter1/lib/services/hospital_service.dart), [overpass_service.dart](file:///f:/flutter1/flutter1/lib/services/overpass_service.dart), [longdo_service.dart](file:///f:/flutter1/flutter1/lib/services/longdo_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: [map_provider.dart](file:///f:/flutter1/flutter1/lib/providers/map_provider.dart)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์ (ผ่านการแก้ไขบั๊ก Deprecated Property ของ TileLayer และล้างจุด BuildContext Async Warnings)
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: จัดทำระบบลบแผนที่ที่เก่าเกินกำหนด หรือระบบขยายพื้นที่แบบปรับระดับด้วยตนเอง

### 1.4 ชุดอุปกรณ์ช่วยชีวิตยามวิกฤต (Survival Tools Suite)
*   **คำอธิบาย (Description)**: เครื่องมือรวมอุปกรณ์ฉุกเฉินเบื้องต้น ประกอบด้วยเข็มทิศดิจิทัลบอกพิกัดความสูง, ไฟฉายกระพริบสัญญาณแสงขอความช่วยเหลือแบบ Morse Code SOS สากล และไซเรนกู้ภัยขับคลื่นเสียงความถี่สูงออกลำโพงตัวเครื่อง
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [survival_tools_screen.dart](file:///f:/flutter1/flutter1/lib/screens/survival_tools_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [emergency_tool_service.dart](file:///f:/flutter1/flutter1/lib/services/emergency_tool_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: ไม่มี (จัดการข้อมูลและสั่งงานฮาร์ดแวร์โดยตรงผ่าน Service)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: ปรับจังหวะระดับความเข้มแสงและความถี่เสียงของไซเรนกู้ภัยเพื่อการเจาะสัญญาณเสียงท่ามกลางสภาพป่าฝน

### 1.5 ระบบเช็คอินอัตโนมัติ (Safety Check Timer)
*   **คำอธิบาย (Description)**: ระบบนับเวลาถอยหลังเพื่อยืนยันความปลอดภัย เหมาะสำหรับกรณีเดินทางไปจุดอันตราย หากผู้ใช้งานขาดการติดต่อและปล่อยให้เวลานับหมดลง ระบบจะถือว่าผู้ใช้กำลังเกิดอันตรายและกระตุ้นการเตือนภัย SOS ทันที
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [safety_check_screen.dart](file:///f:/flutter1/flutter1/lib/screens/safety_check_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [safety_check_service.dart](file:///f:/flutter1/flutter1/lib/services/safety_check_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: ไม่มี
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: จัดส่งสัญญาณพิกัดถอยหลังความปลอดภัยผ่านบลูทูธให้เครื่องรอบข้างทราบข้อมูลล่วงหน้า

### 1.6 ระบบบันทึกเส้นทางเดินป่า (Hike Tracker & Breadcrumb Trails)
*   **คำอธิบาย (Description)**: ตัวดักบันทึกความคืบหน้าการเดินทางพิกัด GPS ระยะทาง ความเร็วความเร่ง และความสูงชัน เพื่อสร้างประวัติและระบุจุดปลอดภัยสุดท้าย (**Last Safe Point**) คอยพาผู้ใช้เดินย้อนรอยนำกลับกรณีหลงป่า
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [hike_dashboard_screen.dart](file:///f:/flutter1/flutter1/lib/screens/hike_dashboard_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [hike_service.dart](file:///f:/flutter1/flutter1/lib/services/hike_service.dart), [last_safe_point_service.dart](file:///f:/flutter1/flutter1/lib/services/last_safe_point_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: ไม่มี (ควบคุมผ่าน HikeService)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: จัดเตรียมแผนภูมิวิเคราะห์ความสูงชันเชิงเปรียบเทียบในประวัติการเดินป่า

### 1.7 คู่มือปฐมพยาบาลประกอบจังหวะเสียง (First Aid Guide & Metronome Pacing)
*   **คำอธิบาย (Description)**: สารบัญคู่มือช่วยเหลือเหตุการแพทย์ฉุกเฉินเบื้องต้นแบบละเอียด พร้อมหน้าแอนิเมชัน CPR วงแหวนจำลองตามจังหวะเวลาสากลคอยนำทางความเร็วกด และมีเสียงบรรยายไทยสังเคราะห์ (TTS) ชี้แนะทีละขั้นตอน
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [first_aid_list_screen.dart](file:///f:/flutter1/flutter1/lib/screens/first_aid_list_screen.dart), [first_aid_detail_screen.dart](file:///f:/flutter1/flutter1/lib/screens/first_aid_detail_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [first_aid_service.dart](file:///f:/flutter1/flutter1/lib/services/first_aid_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: ไม่มี
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: ใช้กล้องเพื่อตรวจวัดจังหวะและวิเคราะห์มุมการกด CPR ของผู้ใช้ด้วย AI แบบเรียลไทม์

### 1.8 พยากรณ์อากาศและดัชนี PM 2.5 (Weather & AQI Alerts)
*   **คำอธิบาย (Description)**: เช็คสภาพภูมิอากาศ อุณหภูมิ ลมพายุ ดัชนีมลภาวะ PM 2.5 และดัชนีรังสี UV จาก Open-Meteo API
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [weather_detail_screen.dart](file:///f:/flutter1/flutter1/lib/screens/weather_detail_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [weather_service.dart](file:///f:/flutter1/flutter1/lib/services/weather_service.dart)
*   **ตัวจัดการสถานะ (Related Providers)**: ไม่มี
*   **สถานะการทำงานปัจจุบัน (Current Status)**: เสร็จสมบูรณ์ (มีการร้อยระบบกราฟิก Custom Canvas Painter ลิขสิทธิ์สภาพอากาศเบลอฝุ่นเรืองแสงนีออนเรียบร้อย)
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: ติดตั้งตัวดึงความดันอากาศ (Barometric Pressure Sensor) ในมือถือเพื่อพยากรณ์พายุฝนระดับออฟไลน์

---

## ⏳ 2. ฟีเจอร์ที่อยู่ในระหว่างการพัฒนา (In Progress Features)

### 2.1 ระบบแสดงผลรายละเอียดสถานพยาบาลเชิงลึก (Google Search / SerpAPI Integration)
*   **คำอธิบาย (Description)**: ดึงข้อมูลคะแนนรีวิว, เบอร์โทรศัพท์ทางการ, เว็บไซต์ติดต่อ, เวลาเปิดทำการของสถานที่ตรวจเจอทาง Overpass/Hospital Service เพื่อแสดงรายละเอียดให้ผู้ใช้เปรียบเทียบก่อนเดินทาง
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [hospital_detail_screen.dart](file:///f:/flutter1/flutter1/lib/screens/hospital_detail_screen.dart) (ยังไม่ได้ผูกข้อมูล API เข้าสู่ UI), [GoogleFacilitySheet](file:///f:/flutter1/flutter1/lib/widgets/map/google_facility_sheet.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [serp_api_service.dart](file:///f:/flutter1/flutter1/lib/services/serp_api_service.dart) (ตัวบริการเขียนสำเร็จและพร้อมส่งคำขอแล้ว เหลือเพียงผูกเข้ากับ Widget UI)
*   **ตัวจัดการสถานะ (Related Providers)**: [map_provider.dart](file:///f:/flutter1/flutter1/lib/providers/map_provider.dart)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: ในส่วน Backend ของ Service พัฒนาเสร็จสิ้น (เขียนโค้ด cache ข้อมูล และการแปลงค่าจาก Knowledge Graph เรียบร้อย) แต่หน้าจอฝั่ง UI ยังแสดงเพียงค่าคงที่จำลองที่ไม่ได้ผูก API 
*   **โอกาสพัฒนาต่อยอด (Future Improvement)**: ดึงข้อมูลการประเมินเวลารอคิวและแผนกพิเศษมาเสริม

---

## 🚀 3. ฟีเจอร์ที่อยู่ในแผนการพัฒนา (Planned Features)

### 3.1 ระบบส่งต่อข้อมูลแบบโครงข่ายใยแมงมุม (Multi-Hop Mesh Network Routing)
*   **คำอธิบาย (Description)**: ความสามารถในการส่งต่อแพ็กเกจข้อความแชทออฟไลน์ (Bytes Payload) ผ่านอุปกรณ์ที่เกาะอยู่เป็นทางยาว (Relay Nodes) ส่งผลให้สามารถแชทและแจ้ง SOS หากันได้ไกลขึ้นเกินรัศมี 100 เมตรของอุปกรณ์เดียว
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [nearby_chat_screen.dart](file:///f:/flutter1/flutter1/lib/screens/nearby_chat_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [nearby_service.dart](file:///f:/flutter1/flutter1/lib/services/nearby_service.dart)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: อยู่ในส่วนวางโครงร่างสถาปัตยกรรม (ยังไม่มีการเริ่มเขียนโค้ดเชิงตรรกะสำหรับการทำ Routing Table)

### 3.2 ระบบประมวลผลแผนที่แบบเวกเตอร์ออฟไลน์ (Vector Tile Map Integration)
*   **คำอธิบาย (Description)**: สลับเอ็นจินการเก็บแผนที่จากภาพ Raster PNG มาเป็นแผนที่ Vector (Mapbox Vector Tiles หรือสเปก MVT) เพื่อให้ผู้ใช้สามารถดาวน์โหลดแผนที่ของทั้งภูมิภาค/จังหวัดมาบันทึกในขนาดไฟล์ที่เล็กลง 90%
*   **หน้าจอที่เกี่ยวข้อง (Related Screens)**: [map_screen.dart](file:///f:/flutter1/flutter1/lib/screens/map_screen.dart)
*   **บริการที่เกี่ยวข้อง (Related Services)**: [map_offline_service.dart](file:///f:/flutter1/flutter1/lib/services/map_offline_service.dart)
*   **สถานะการทำงานปัจจุบัน (Current Status)**: อยู่ในขั้นตอนการวิจัย (Research Phase)

---

## 📄 สัญญาอนุญาต (License)

*   ขณะนี้โปรเจกต์ **BANTAWAN** ยังไม่ได้มีการกำหนดประเภทของสัญญาอนุญาต (License) อย่างเป็นทางการเพื่อวัตถุประสงค์เชิงพาณิชย์ หรือการเผยแพร่แบบ Open-Source
