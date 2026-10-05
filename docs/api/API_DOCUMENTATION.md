# BANTAWAN - API Documentation & External Specifications

**โครงการ**: BANTAWAN (Smart Survival & Emergency Assistance Application)  
**คีย์ทดสอบสาธารณะ**: `dbdf5b58f8ab78d6646afdfc7bfdc2bc` (Longdo Map API Key)  

---

## 1. บริการ Longdo Map REST APIs

### 1.1 ค้นหาสถานพยาบาลรอบตัว (Nearby POI Search)
- **Endpoint**: `https://search.longdo.com/mapsearch/json/search`
- **Method**: `GET`
- **พารามิเตอร์**:
  - `key`: API Key (String)
  - `lat`: ละติจูดพิกัดศูนย์กลาง (Double)
  - `lon`: ลองจิจูดพิกัดศูนย์กลาง (Double)
  - `span`: รัศมีค้นหา เช่น `10km`
  - `limit`: จำนวนผลลัพธ์สูงสุด เช่น `100`
  - `tag`: หมวดหมู่สถานที่ เช่น `hospital,medical_center,clinic,pharmacy`
- **ตัวอย่าง Request**:
  ```http
  GET https://search.longdo.com/mapsearch/json/search?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&lat=7.0086&lon=100.4747&span=10km&limit=100&tag=hospital
  ```

### 1.2 รายละเอียดสถานที่เจาะจง (POI Details)
- **Endpoint**: `https://api.longdo.com/map/services/poi/get`
- **Method**: `GET`
- **พารามิเตอร์**:
  - `key`: API Key
  - `id`: รหัสประจำสถานที่ เช่น `A00874523`
- **ตัวอย่าง Request**:
  ```http
  GET https://api.longdo.com/map/services/poi/get?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&id=A00874523
  ```

### 1.3 รายงานอุบัติเหตุและเหตุจราจรฉุกเฉิน (Traffic Incidents)
- **Endpoint**: `https://api.longdo.com/map/services/rest/traffic`
- **Method**: `GET`
- **พารามิเตอร์**:
  - `key`: API Key
  - `type`: ระบุเป็น `incident`
- **ตัวอย่าง Request**:
  ```http
  GET https://api.longdo.com/map/services/rest/traffic?key=dbdf5b58f8ab78d6646afdfc7bfdc2bc&type=incident
  ```

---

## 2. บริการ OpenStreetMap Overpass API (OSM Query Language)

ใช้เป็น API สำรอง (Fallback Provider) กรณี Longdo ล้มเหลว หรือใช้งานนอกพื้นที่ประเทศไทย

- **Endpoint**: `https://overpass-api.de/api/interpreter`
- **Endpoints สำรอง**: 
  - `https://lz4.overpass-api.de/api/interpreter`
  - `https://z.overpass-api.de/api/interpreter`
  - `https://overpass.kumi.systems/api/interpreter`
- **Method**: `POST`
- **Timeout**: 10 วินาที พร้อมระบบ Retry Loop 2 ครั้ง
- **ตัวอย่าง Payload (Overpass QL)**:
  ```xml
  [out:json][timeout:10];
  (
    node["amenity"~"hospital|clinic|pharmacy"](around:10000,7.0086,100.4747);
    way["amenity"~"hospital|clinic|pharmacy"](around:10000,7.0086,100.4747);
    relation["amenity"~"hospital|clinic|pharmacy"](around:10000,7.0086,100.4747);
  );
  out center;
  ```

---

## 3. บริการคำนวณเส้นทาง OSRM Routing API

- **Endpoint**: `https://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2}`
- **Method**: `GET`
- **พารามิเตอร์**:
  - `overview`: `full`
  - `geometries`: `polyline`
  - `steps`: `true`
- **ตัวอย่าง Request**:
  ```http
  GET https://router.project-osrm.org/route/v1/driving/100.4747,7.0086;100.4850,7.0200?overview=full&geometries=polyline&steps=true
  ```
- **การประเมินผลลัพธ์**: ถอดรหัส Polyline String เป็นพิกัด `List<LatLng>` ผ่านคลาส `PolylinePoints.decodePolyline()`

---

## 4. บริการตรวจวัดสภาพอากาศ Open-Meteo APIs

### 4.1 พยากรณ์สภาพอากาศ (Weather API)
- **Endpoint**: `https://api.open-meteo.com/v1/forecast`
- **Method**: `GET`
- **ตัวอย่าง Request**:
  ```http
  GET https://api.open-meteo.com/v1/forecast?latitude=7.0086&longitude=100.4747&current=temperature_2m,weather_code&hourly=weather_code&forecast_days=1
  ```

### 4.2 ตรวจวัดมลพิษ PM 2.5 และคุณภาพอากาศ (Air Quality API)
- **Endpoint**: `https://air-quality-api.open-meteo.com/v1/air-quality`
- **Method**: `GET`
- **ตัวอย่าง Request**:
  ```http
  GET https://air-quality-api.open-meteo.com/v1/air-quality?latitude=7.0086&longitude=100.4747&current=pm2_5,carbon_monoxide,nitrogen_dioxide,ozone&hourly=pm2_5&forecast_days=1
  ```

---

## 5. บริการค้นหาชื่อตำแหน่งพิกัด (Geocoding APIs)

### 5.1 Photon API (ค้นหาพิกัดโดยอิงตามตำแหน่งผู้ใช้)
- **Endpoint**: `https://photon.komoot.io/api/`
- **ตัวอย่าง Request**:
  ```http
  GET https://photon.komoot.io/api/?q=%E0%B8%AB%E0%B8%B2%E0%B8%94%E0%B9%83%E0%B8%A5%E0%B9%8C&lat=7.0086&lon=100.4747&limit=1
  ```

### 5.2 Nominatim API (ค้นหาพิกัดระดับสากล)
- **Endpoint**: `https://nominatim.openstreetmap.org/search`
- **ตัวอย่าง Request**:
  ```http
  GET https://nominatim.openstreetmap.org/search?q=%E0%B8%AB%E0%B8%B2%E0%B8%94%E0%B9%83%E0%B8%A5%E0%B9%8C&format=json&limit=1&addressdetails=1
  ```
- **ข้อกำหนด**: แนบ Header `User-Agent: Bantawan Survival App`
