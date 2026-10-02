# รายละเอียดการเรียกใช้บริการ API (API Documentation)

แอปพลิเคชัน **BANTAWAN** ทำงานในรูปแบบ Offline-First แต่รองรับการผสานข้อมูลออนไลน์เมื่อเชื่อมต่อเครือข่าย โดยพึ่งพาการทำงานร่วมกับบริการภายนอกผ่าน HTTP REST API ดังนี้:

---

## 1. บริการแผนที่และข้อมูลสถานที่ของ Longdo Map API

ใช้สำหรับคัดกรองข้อมูลประชากร จุดจราจร กล้อง CCTV และสถานที่สำคัญทางยุทธศาสตร์ในประเทศไทย โดยใช้รหัสทดสอบสาธารณะ `dbdf5b58f8ab78d6646afdfc7bfdc2bc`

### 1.1 ค้นหาตำแหน่งสถานที่พยาบาลรอบตัว (Nearby POI Search)
*   **Endpoint**: `https://search.longdo.com/mapsearch/json/search`
*   **Method**: `GET`
*   **พารามิเตอร์**:
    *   `key`: รหัส API Key
    *   `lat`: ละติจูดของพิกัดศูนย์กลาง
    *   `lon`: ลองจิจูดของพิกัดศูนย์กลาง
    *   `span`: รัศมี เช่น `10km`
    *   `limit`: จำนวนสูงสุดของผลลัพธ์ (เช่น `100`)
    *   `tag` *(ตัวเลือก)*: ประเภทของสถานที่ เช่น `hospital,medical_center,clinic,pharmacy`
    *   `keyword` *(ตัวเลือก)*: คำค้นหา
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://search.longdo.com/mapsearch/json/search?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&lat=7.0086&lon=100.4747&span=20km&limit=100&tag=hospital
    ```

### 1.2 รายละเอียดสถานที่เจาะจง (POI Details)
*   **Endpoint**: `https://api.longdo.com/map/services/poi/get`
*   **Method**: `GET`
*   **พารามิเตอร์**:
    *   `key`: รหัส API Key
    *   `id`: รหัสสถานที่ประจำระบบ Longdo POI
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://api.longdo.com/map/services/poi/get?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&id=A00874523
    ```

### 1.3 ดึงรายการอุบัติเหตุและเหตุภัยพิบัติ (Traffic Incidents)
*   **Endpoint**: `https://api.longdo.com/map/services/rest/traffic`
*   **Method**: `GET`
*   **พารามิเตอร์**:
    *   `key`: รหัส API Key
    *   `type`: ประเภทข้อมูล ระบุเป็น `incident`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://api.longdo.com/map/services/rest/traffic?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&type=incident
    ```

### 1.4 ดึงข้อมูลแผนที่ซ้อนทับเส้นทางการจราจร (Traffic Tile Overlay)
*   **Endpoint**: `https://ms.longdo.com/mmmap/tile.php`
*   **Method**: `GET`
*   **พารามิเตอร์**:
    *   `key`: รหัส API Key
    *   `x`, `y`, `z`: พิกัดแผ่นแผนที่ (OSM Tile format)
    *   `layer`: เลเยอร์ที่ซ้อนทับ ระบุเป็น `traffic`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://ms.longdo.com/mmmap/tile.php?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&x=25412&y=14324&z=15&layer=traffic
    ```

---

## 2. ค้นหาพิกัดข้อมูลสาธารณสุขภายนอกประเทศผ่าน Overpass API (OSM)

ใช้ดึงพิกัดจากฐานข้อมูล OpenStreetMap ในพื้นที่ที่อยู่นอกเขตประเทศไทย หรือระบบ Longdo ขาดหาย

*   **Endpoint**: `https://overpass-api.de/api/interpreter`
    *(มีระบบสำรองไปยัง `https://lz4.overpass-api.de/api/interpreter` และเครือข่ายอื่นกรณีส่งข้อมูลไม่ผ่าน)*
*   **Method**: `POST`
*   **Payload ใน Body** (เนื้อหาแบบ Overpass QL):
    ```xml
    [out:json][timeout:10];
    (
      node["amenity"~"hospital|clinic|pharmacy"](around:{radiusInMeters},{latitude},{longitude});
      way["amenity"~"hospital|clinic|pharmacy"](around:{radiusInMeters},{latitude},{longitude});
      relation["amenity"~"hospital|clinic|pharmacy"](around:{radiusInMeters},{latitude},{longitude});
    );
    out center;
    ```

---

## 3. บริการคำนวณเส้นทางนำทาง OSRM Routing API

ใช้สร้างเวกเตอร์เส้นทางการขับขี่แบบเลี้ยวต่อเลี้ยว (Turn-by-turn routing) เพื่อนำไปวาดทับบนแผนที่ `flutter_map`

*   **Endpoint**: `https://router.project-osrm.org/route/v1/driving/{startLon},{startLat};{destLon},{destLat}`
*   **Method**: `GET`
*   **พารามิเตอร์**:
    *   `overview`: ตั้งค่าเป็น `full`
    *   `geometries`: รูปแบบรับพิกัดเส้นทาง ตั้งค่าเป็น `polyline`
    *   `steps`: สั่งรับข้อความเลี้ยวต่อเลี้ยว ตั้งค่าเป็น `true`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://router.project-osrm.org/route/v1/driving/100.4747,7.0086;100.4850,7.0200?overview=full&geometries=polyline&steps=true
    ```
*   **ผลลัพธ์ตอบกลับ**: คืนค่า Polyline รหัสความปลอดภัย ซึ่งจะถอดรหัสในแอปพลิเคชันผ่านคลาส `PolylinePoints.decodePolyline()` เพื่อนำไปใช้วาดเส้นเรืองแสงนีออนนำทาง

---

## 4. ตรวจวัดระดับสภาพอากาศและคุณภาพอากาศ Open-Meteo API

ใช้ตรวจสอบระดับความเสี่ยงของพายุ ฝน และประเมินฝุ่น PM 2.5 บริเวณรอบตัวผู้ใช้

### 4.1 ตรวจดูข้อมูลสภาพอากาศ (Weather API)
*   **Endpoint**: `https://api.open-meteo.com/v1/forecast`
*   **Method**: `GET`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://api.open-meteo.com/v1/forecast?latitude=7.0086&longitude=100.4747&current=temperature_2m,weather_code&hourly=weather_code&forecast_days=1
    ```

### 4.2 ตรวจสอบระดับฝุ่นละอองและสารเคมีในชั้นบรรยากาศ (Air Quality API)
*   **Endpoint**: `https://air-quality-api.open-meteo.com/v1/air-quality`
*   **Method**: `GET`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://air-quality-api.open-meteo.com/v1/air-quality?latitude=7.0086&longitude=100.4747&current=pm2_5,carbon_monoxide,nitrogen_dioxide,ozone&hourly=pm2_5&forecast_days=1
    ```

---

## 5. บริการค้นหาพิกัดจากคำศัพท์ (Geocoding APIs)

ใช้แปลข้อความค้นหา (เช่น "หาดใหญ่") เป็นพิกัดละติจูด/ลองจิจูด เพื่อเปลี่ยนตำแหน่งกล้องในแผนที่

### 5.1 Photon API (ค้นหาพิกัดโดยใช้พิกัดผู้ใช้ช่วยระบุรัศมี)
*   **Endpoint**: `https://photon.komoot.io/api/`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://photon.komoot.io/api/?q=%E0%B8%AB%E0%B8%B2%E0%B8%94%E0%B9%83%E0%B8%A5%E0%B9%8C&lat=7.0086&lon=100.4747&limit=1
    ```

### 5.2 Nominatim API (ค้นหาระดับสากลเป็นตัวเลือกสำรอง)
*   **Endpoint**: `https://nominatim.openstreetmap.org/search`
*   **ตัวอย่างคำขอ**:
    ```http
    GET https://nominatim.openstreetmap.org/search?q=%E0%B8%AB%E0%B8%B2%E0%B8%94%E0%B9%83%E0%B8%A5%E0%B9%8C&format=json&limit=1&addressdetails=1
    ```
    *(ข้อกำหนด: ต้องแนบ Header `User-Agent: Bantawan Survival App` เพื่อป้องกันการถูกปฏิเสธจากเซิร์ฟเวอร์)*
