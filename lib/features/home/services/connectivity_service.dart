// ============================================================================
// 📶 BANTAWAN Network Connectivity & Quality Service: ConnectivityService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Realtime Environment & Status)              │
// ├─────────────────────────────────────────────────────────┤
// │                ConnectivityService                      │
// │  ┌───────────────────────┬───────────────────────────┐  │
// │  │   connectivity_plus   │    DNS / Latency Probe    │  │
// │  │ (Hardware Interface)  │  (InternetAddress.lookup) │  │
// │  └───────────────────────┴───────────────────────────┘  │
// ├─────────────────────────────────────────────────────────┤
// │                  NetworkStability                       │
// │     (stable / unstable / disconnected states)           │
// └─────────────────────────────────────────────────────────┘
// 
// บริการตรวจจับสถานะเครือข่ายอินเทอร์เน็ตและความเสถียร (Connectivity Service)
// ออกแบบเป็น Singleton ร่วมกับ ChangeNotifier เพื่อกระจายสถานะ Realtime ไปยัง UI
// ตรวจสอบการเชื่อมต่อ Wi-Fi / Cellular / Offline และทดสอบ DNS Lookup (google.com)
// เพื่อประเมินว่ามีเน็ตออกสู่อินเทอร์เน็ตจริงหรือไม่ พร้อมวิเคราะห์ความหน่วง (Latency)
// ============================================================================

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// 📊 ระดับความเสถียรของสัญญาณเครือข่ายอินเทอร์เน็ต (NetworkStability)
enum NetworkStability {
  /// สัญญาณเน็ตเสถียร ค่า Latency ต่ำ ใช้งานระบบนำทางและกู้ภัยออนไลน์ได้เต็มประสิทธิภาพ
  stable,

  /// สัญญาณเริ่มขาดๆ หายๆ หรือค่า Latency สูง (> 1.5 วินาที) เหมาะแก่การเตรียมพร้อมโหมดออฟไลน์
  unstable,

  /// ไม่มีสัญญาณอินเทอร์เน็ต (ออฟไลน์สมบูรณ์) ระบบจะสลับไปใช้แคชและ P2P Nearby ทันที
  disconnected,
}

/// 🏛️ คลาสบริการตรวจสอบสถานะการเชื่อมต่ออินเทอร์เน็ต (ConnectivityService)
/// ใช้สถาปัตยกรรม Singleton เพื่อให้ทุกโมดูลในระบบอ้างอิงสถานะเครือข่ายเดียวกัน
class ConnectivityService extends ChangeNotifier {
  // ----------------------------------------------------------------------------
  // 🔒 Singleton Pattern Implementation
  // ----------------------------------------------------------------------------
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // ----------------------------------------------------------------------------
  // 📦 Internal State & Controllers
  // ----------------------------------------------------------------------------
  final Connectivity _connectivity = Connectivity(); // อินสแตนซ์สำหรับอ่านค่าระดับฮาร์ดแวร์
  StreamSubscription<List<ConnectivityResult>>? _subscription; // ตัวฟังอีเวนต์การเปลี่ยนแปลงสถานะเน็ต

  /// 📶 ผลลัพธ์ประเภทการเชื่อมต่อล่าสุด (Wi-Fi, Mobile, None)
  ConnectivityResult _currentResult = ConnectivityResult.none;

  /// 🚦 ระดับคุณภาพและความเสถียรของเครือข่ายปัจจุบัน
  NetworkStability _stability = NetworkStability.stable;

  /// 🛡️ แฟล็กป้องกันการยิงเช็ก Latency ซ้ำซ้อนพร้อมกันหลายครั้ง (Debounce Guard)
  bool _isCheckingStability = false;

  // ----------------------------------------------------------------------------
  // 📢 Getters
  // ----------------------------------------------------------------------------
  /// ประเภทการเชื่อมต่อฮาร์ดแวร์ล่าสุด
  ConnectivityResult get currentResult => _currentResult;

  /// คุณภาพความเสถียรของสัญญาณอินเทอร์เน็ต
  NetworkStability get stability => _stability;

  // ============================================================================
  // 🚀 Section 1: Lifecycle & Initialization
  // ============================================================================

  /// 📌 เริ่มต้นการทำงานของบริการเครือข่าย: ตรวจสอบสถานะแรกเริ่ม และสมัครรับฟังการเปลี่ยนแปลง
  Future<void> init() async {
    // 1. ตรวจสอบสถานะการเชื่อมต่อครั้งแรกทันทีที่เปิดแอป
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // 2. สมัครรับสตรีมการแจ้งเตือนเมื่อระบบปฏิบัติการตรวจพบการเปลี่ยนสถานะเครือข่าย
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  // ============================================================================
  // 🔄 Section 2: Status Updates & Network Probing
  // ============================================================================

  /// 📌 อัปเดตสถานะเครือข่ายภายในจากผลลัพธ์ของระบบปฏิบัติการ
  /// - [results]: รายการสถานะการเชื่อมต่อจากไลบรารี connectivity_plus (เวอร์ชัน 6.x)
  void _updateStatus(List<ConnectivityResult> results) {
    // 1. ตรวจสอบว่ามีรายการเชื่อมต่อส่งกลับมาหรือไม่
    if (results.isEmpty) {
      _currentResult = ConnectivityResult.none;
    } else {
      _currentResult = results.first; // เลือกการเชื่อมต่อหลัก
    }

    // 2. หากอุปกรณ์ไม่ได้เชื่อมต่อเครือข่ายใดๆ เลย
    if (_currentResult == ConnectivityResult.none) {
      _stability = NetworkStability.disconnected;
    } else {
      // 3. หากเชื่อมต่อ Wi-Fi หรือ Cellular ให้ทดสอบ Ping จริงว่าอินเทอร์เน็ตออกได้หรือไม่
      _checkStability();
    }
    
    // 4. แจ้งเตือนวิดเจ็ตหรือ Provider ที่กำลังฟังอยู่ให้อัปเดต UI ทันที
    notifyListeners();
  }

  /// 📌 ตรวจสอบความเสถียรและค่าความหน่วง (Latency Probe) โดยทดสอบ DNS Lookup ไปยัง Host มาตรฐาน
  Future<void> _checkStability() async {
    // ป้องกันการทำงานซ้ำหากมีการตรวจสอบเดิมกำลังรอดำเนินการอยู่
    if (_isCheckingStability) return;
    _isCheckingStability = true;

    try {
      // 1. เริ่มจับเวลาการทดสอบการเชื่อมต่อ
      final stopwatch = Stopwatch()..start();
      
      // 2. ทดสอบค้นหา DNS ไปยัง google.com โดยกำหนด Timeout ไว้ที่ 3 วินาที
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();

      // 3. ตรวจสอบว่าได้รับ IP Address ที่ถูกต้องตอบกลับมาหรือไม่
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // หากค่าความหน่วงสูงเกิน 1.5 วินาที (1500ms) ให้ถือว่าสัญญาณไม่เสถียร (Unstable)
        if (stopwatch.elapsedMilliseconds > 1500) {
          _stability = NetworkStability.unstable;
        } else {
          _stability = NetworkStability.stable;
        }
      } else {
        _stability = NetworkStability.unstable;
      }
    } catch (_) {
      // หากเกิด Timeout หรือไม่สามารถแปลงชื่อโฮสต์ได้ ถือว่าสัญญาณไม่เสถียรหรือติด Captive Portal
      _stability = NetworkStability.unstable;
    } finally {
      // ปลดล็อกสถานะการตรวจสอบ และแจ้งเตือนผู้ฟังอีกครั้ง
      _isCheckingStability = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // 🧹 Section 3: Resource Cleanup
  // ============================================================================

  /// 📌 คืนทรัพยากรและยกเลิก StreamSubscription เมื่อปิดบริการ
  @override
  void dispose() {
    _subscription?.cancel(); // ยกเลิกการฟังการเปลี่ยนแปลงเครือข่าย
    super.dispose();
  }
}
