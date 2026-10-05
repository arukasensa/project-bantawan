# BANTAWAN - ศูนย์รวมเอกสารทางเทคนิค (Documentation Hub)

ยินดีต้อนรับสู่ศูนย์รวมเอกสารข้อมูลเชิงเทคนิค สถาปัตยกรรมระบบ และคู่มือการพัฒนาระบบทั้งหมดของโครงการ **BANTAWAN (Smart Survival & Emergency Assistance Application)**

---

## 🗺️ แผนผังสารบัญเอกสารทั้งหมด (Documentation Directory)

### 🏛️ 1. สถาปัตยกรรมและโครงสร้างระบบ (Architecture)
| เอกสาร | รายละเอียดและขอบเขต | ลิงก์เข้าชม |
|---|---|---|
| **System Architecture** | สถาปัตยกรรมภาพรวม Clean Feature-First Architecture, State Flow, Layer Responsibilities | [SYSTEM_ARCHITECTURE.md](architecture/SYSTEM_ARCHITECTURE.md) |
| **Mesh Routing Protocol** | เจาะลึกวิทยุสื่อสาร P2P Mesh, Multi-hop Flooding Relay, Dynamic Hop Count, Data Mule | [MESH_ROUTING.md](architecture/MESH_ROUTING.md) |
| **Offline-First Design** | กลยุทธ์การทำงานออฟไลน์, Slippy Map Tiling Scheme, SQLite V6 Persistence | [OFFLINE_DESIGN.md](architecture/OFFLINE_DESIGN.md) |

---

### 🧩 2. ข้อมูลมอดูลระบบ (Modules & Features)
| เอกสาร | รายละเอียดและขอบเขต | ลิงก์เข้าชม |
|---|---|---|
| **Map Module** | ระบบแผนที่ 3 สไตล์, Tile Caching, POI Pipeline, OSRM/Direct Bearing Routing | [MAP_MODULE.md](modules/MAP_MODULE.md) |
| **Feature Catalog** | รายการฟังก์ชันการทำงานทั้งหมดของระบบ 7 มอดูลหลัก | [FEATURES.md](modules/FEATURES.md) |
| **Product Roadmap** | แผนพัฒนาไมล์สโตนโครงการ และการยกระดับประสิทธิภาพในอนาคต | [ROADMAP.md](modules/ROADMAP.md) |

---

### 🔌 3. ข้อมูลการเชื่อมต่อ API (API Documentation)
| เอกสาร | รายละเอียดและขอบเขต | ลิงก์เข้าชม |
|---|---|---|
| **API Specifications** | ข้อกำหนดและตัวอย่างคำขอ Longdo Map, OSM Overpass, OSRM, Open-Meteo Weather/AQI | [API_DOCUMENTATION.md](api/API_DOCUMENTATION.md) |

---

### 🛠️ 4. คู่มือการติดตั้งและขึ้นระบบ (Developer Guides)
| เอกสาร | รายละเอียดและขอบเขต | ลิงก์เข้าชม |
|---|---|---|
| **Installation Guide** | ขั้นตอนติดตั้ง Environment, Flutter SDK, และการรันแอปพลิเคชัน | [INSTALL.md](guides/INSTALL.md) |
| **Deployment Guide** | ขั้นตอนการคอมไพล์ APK / Android App Bundle และการตั้งค่าขึ้นสโตร์ | [DEPLOYMENT.md](guides/DEPLOYMENT.md) |
| **Troubleshooting Guide**| วิธีแก้ไขปัญหาพบบ่อย (บลูทูธไม่เจอ, RAM ไม่พอ, สิทธิ์ Android/iOS) | [TROUBLESHOOTING.md](guides/TROUBLESHOOTING.md) |

---

### 📏 5. กฎระเบียบและมาตรฐาน (Rules & Standards)
| เอกสาร | รายละเอียดและขอบเขต | ลิงก์เข้าชม |
|---|---|---|
| **AI Development Rules** | มาตรฐานการเขียนโค้ดและข้อบังคับในการแก้ไขระบบสำหรับ AI Assistants | [AI_RULES.md](rules/AI_RULES.md) |

---

### 🎓 6. เอกสารเชิงวิชาการและโครงงาน (Academic & Thesis)
| เอกสาร | รายละเอียดและขอบเขต | ลิงก์เข้าชม |
|---|---|---|
| **Project Abstract** | บทคัดย่อโครงงานวิจัย (ภาษาไทยและภาษาอังกฤษ) | [ABSTRACT.md](academic/ABSTRACT.md) |
| **Chapter 3 Methodology** | ระเบียบวิธีวิจัยและขั้นตอนการออกแบบสถาปัตยกรรมระบบ | [CHAPTER3_METHODOLOGY.md](academic/CHAPTER3_METHODOLOGY.md) |
| **Project Scope** | ขอบเขตของโครงการ กลุ่มเป้าหมาย และตัวชี้วัดความสำเร็จ | [PROJECT_SCOPE.md](academic/PROJECT_SCOPE.md) |
| **Theory & Technology** | ทฤษฎีเครือข่าย Ad-hoc, การเข้ารหัสลับ, และระบบสารสนเทศภูมิศาสตร์ | [THEORY_AND_TECHNOLOGY.md](academic/THEORY_AND_TECHNOLOGY.md) |
| **Engineering Log** | บันทึกประวัติการพัฒนาและแก้ไขระบบเชิงวิศวกรรม | [AI_ENGINEERING_LOG.md](academic/AI_ENGINEERING_LOG.md) |
