# บทคัดย่อ (Abstract)

**ชื่อโครงงาน:** ระบบสนับสนุนความปลอดภัยส่วนบุคคลบนสมาร์ทโฟน (BANTAWAN - SOS Premier)  
**ประเภทโครงงาน:** แอปพลิเคชันบนอุปกรณ์เคลื่อนที่ (Mobile Application)  

---

## บทคัดย่อภาษาไทย

โครงงานนี้มีวัตถุประสงค์เพื่อพัฒนาโมบายแอปพลิเคชันช่วยชีวิตและสื่อสารฉุกเฉินในสภาวะวิกฤตภายใต้ชื่อ **ระบบสนับสนุนความปลอดภัยส่วนบุคคลบนสมาร์ทโฟน ** ซึ่งถูกออกแบบตามสถาปัตยกรรมแบบการทำงานออฟไลน์เป็นหลัก (Offline-First Architecture) เพื่อรองรับการใช้งานในพื้นที่ไร้สัญญาณอินเทอร์เน็ตหรือระหว่างเกิดภัยพิบัติทางธรรมชาติ แอปพลิเคชันมีฟังก์ชันการทำงานหลัก 4 ส่วน ได้แก่ 1) ระบบสื่อสารไร้สายแบบไม่อาศัยเซิร์ฟเวอร์ (Off-Grid Mesh Communication) ผ่านเทคโนโลยี Google Nearby Connections (Bluetooth Low Energy และ Wi-Fi Direct) ร่วมกับการเข้ารหัสข้อมูลแบบ End-to-End Encryption (E2EE) ด้วยอัลกอริทึม SHA-256 และ HMAC-SHA256 เพื่อความคุ้มครองความปลอดภัยของข้อมูลฉุกเฉิน 2) ระบบแผนที่ฉุกเฉินออฟไลน์และการนำทางไปยังสถานพยาบาลรอบตัว โดยผสานข้อมูลจาก Longdo Map API, Overpass API (OpenStreetMap) และ OSRM Routing API 3) ระบบเฝ้าระวังภัยพิบัติและสภาพแวดล้อม โดยติดตามสภาพอากาศ สัญญาณเตือนภัย และดรรชนีฝุ่นละออง PM 2.5 ผ่าน Open-Meteo API และ 4) เครื่องมือช่วยชีวิตฉุกเฉิน ได้แก่ สัญญาณไฟฉายรหัสสื่อสาร SOS สัญญาณเสียงไซเรนเตือนภัย เข็มทิศดิจิทัล และคู่มือปฐมพยาบาลออฟไลน์พร้อมระบบอ่านออกเสียง (Text-to-Speech)

จากการทดสอบประสิทธิภาพการทำงานของระบบ พบว่าแอปพลิเคชันสามารถค้นพบและเชื่อมต่อโครงข่าย P2P Mesh Network ในสภาวะไม่มีสัญญาณอินเทอร์เน็ตได้อย่างมีประสิทธิภาพ โดยมีอัตราความสำเร็จในการรับส่งข้อความฉุกเฉินในระยะสายตา (Line-of-Sight) เฉลี่ยร้อยละ 94.5 และมีค่าความหน่วงเวลา (Latency) ในการส่งข้อมูลเฉลี่ยอยู่ที่ 1.42 วินาที ในส่วนของการนำทางและแสดงพิกัดสถานพยาบาล ระบบสามารถแสดงพิกัดและวาดเส้นทางออฟไลน์ผ่านกระบวนการจัดเก็บแคชแผ่นแผนที่ (Tile Caching) ได้อย่างแม่นยำ อย่างไรก็ตาม จากการทดสอบพบข้อจำกัดของระบบสื่อสาร P2P ไร้สาย คือ ประสิทธิภาพและระยะการส่งสัญญาณจะลดลงตามโครงสร้างสิ่งกีดขวางในพื้นที่ และขึ้นอยู่กับรุ่นฮาร์ดแวร์บลูทูธของสมาร์ตโฟนแต่ละเครื่อง เพื่อแก้ไขข้อจำกัดนี้ในอนาคต แนะนำให้มีการพัฒนาระบบคัดเลือกเส้นทางส่งต่อข้อมูลแบบหลายช่วง (Multi-hop Routing Optimization) รวมถึงการเพิ่มโหนดกระจายสัญญาณคงที่ (Static Mesh Beacon) ในพื้นที่จุดเสี่ยงภัยพิบัติสูง

**คำสำคัญ :** ระบบสื่อสารฉุกเฉินไร้สาย  เครือข่ายเมช  แผนที่ออฟไลน์  การเข้ารหัสแบบต้นทางถึงปลายทาง  การกู้ภัยพิบัติ

---

## English Abstract

This project aims to develop a mobile application for emergency survival and communication in crisis situations, named **BANTAWAN (SOS Premier)**. Designed around an Offline-First Architecture, the application guarantees operational capability in off-grid environments or during natural disasters when cellular networks fail. The system consists of four core functional modules: 1) Off-Grid Mesh Communication utilizing Google Nearby Connections (Bluetooth Low Energy and Wi-Fi Direct) secured with End-to-End Encryption (E2EE) via SHA-256 and HMAC-SHA256 algorithms; 2) Offline Emergency Mapping and Turn-by-Turn Navigation to nearby medical facilities, integrating data from Longdo Map API, Overpass API (OpenStreetMap), and OSRM Routing API; 3) Environmental and Disaster Risk Monitoring, tracking real-time weather and PM 2.5 air quality indices via Open-Meteo API; and 4) Emergency Survival Tools, including an SOS Morse Code flashlight strobe, high-frequency audio siren, digital compass, and an offline first-aid guide with Text-to-Speech capabilities.

Experimental testing demonstrated that the application successfully established P2P Mesh Networks in zero-connectivity environments with an average emergency message delivery success rate of 94.5% in line-of-sight conditions and an average latency of 1.42 seconds. For offline navigation, local tile caching enabled precise hospital locator display and route polyline rendering without network access. However, testing revealed performance constraints inherent to P2P wireless communications, where signal range and throughput degraded in the presence of structural obstacles and varied across smartphone Bluetooth hardware revisions. To address these limitations, future work recommends incorporating multi-hop routing optimization algorithms and deploying fixed static mesh beacons in high-risk disaster zones.

**Keywords:** Emergency Wireless Communication, Mesh Network, Offline Map, End-to-End Encryption, Disaster Relief
