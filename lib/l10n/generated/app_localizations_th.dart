// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'BANTAWAN';

  @override
  String get sos => 'ขอความช่วยเหลือ';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navMap => 'แผนที่';

  @override
  String get navSOS => 'ฉุกเฉิน';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get greetingAfternoon => 'สวัสดีตอนกลางวัน,';

  @override
  String get safetyStatusNormal => 'ระบบดูแลความปลอดภัยทำงานปกติ';

  @override
  String get loadingWeather => 'กำลังดึงข้อมูลสภาพอากาศ...';

  @override
  String get retryHint => 'หากค้างนานเกินไปกรุณาแตะเพื่อลองใหม่';

  @override
  String get locationNotFound => 'หาพิกัดไม่พบ';

  @override
  String get tapToRetry => 'แตะเพื่อลองใหม่';

  @override
  String get emergencyHotlines => 'สายด่วนความช่วยเหลือ';

  @override
  String get seeAll => 'ดูทั้งหมด';

  @override
  String get hospitals => 'โรงพยาบาล';

  @override
  String get firstAidGuide => 'คู่มือปฐมพยาบาล';

  @override
  String get survivalTools => 'เครื่องมือเอาตัวรอด';

  @override
  String get emergencyContacts => 'ผู้ติดต่อฉุกเฉิน';

  @override
  String get medicalHistory => 'ประวัติสุขภาพ';

  @override
  String get medicalId => 'ข้อมูลการแพทย์';

  @override
  String get bloodType => 'หมู่เลือด';

  @override
  String get nearestHospital => 'โรงพยาบาลใกล้ที่สุด';

  @override
  String get survivalTitle => 'เครื่องมือเอาตัวรอด';

  @override
  String get compass => 'เข็มทิศดิจิทัล';

  @override
  String get flashlight => 'ไฟฉายขอความช่วยเหลือ';

  @override
  String get siren => 'เสียงหวอฉุกเฉิน';

  @override
  String get nearbyNetwork => 'เครือข่ายฉุกเฉินใกล้เคียง';

  @override
  String get startNetwork => 'เปิดระบบระบุตัวตน';

  @override
  String get stopNetwork => 'ปิดระบบระบุตัวตน';

  @override
  String get enterChat => 'เข้าสู่ห้องแชทใกล้เคียง';

  @override
  String get offlineChatTitle => 'แชทเครือข่ายออฟไลน์';

  @override
  String get searchingPeers => 'กำลังค้นหาคนรอบข้าง...';

  @override
  String connectedDevices(int count) {
    return 'เชื่อมต่อ $count อุปกรณ์';
  }

  @override
  String get noMessages => 'ยังไม่มีข้อความ\nส่ง SOS หรือทักทายคนรอบข้างได้เลย';

  @override
  String get typeEmergencyMsg => 'พิมพ์ข้อความฉุกเฉิน...';

  @override
  String get myLocation => 'พิกัดของฉัน';

  @override
  String get viewInMap => 'ดูในแผนที่';

  @override
  String get locationError => 'ไม่สามารถดึงตำแหน่งได้';

  @override
  String get medicalEmergency => 'เหตุฉุกเฉินทางการแพทย์';

  @override
  String get police => 'สถานีตำรวจ';

  @override
  String get fire => 'สถานีดับเพลิง';

  @override
  String get tourist => 'ตำรวจท่องเที่ยว';

  @override
  String get rescue => 'หน่วยกู้ภัย';

  @override
  String get mentalHealth => 'สุขภาพจิต';

  @override
  String get sosButtonHint => 'กดเพื่อขอความช่วยเหลือทันที';

  @override
  String get signalAccuracy => 'ความแม่นยำของสัญญาณ';

  @override
  String get searchingSignal => 'กำลังค้นหาสัญญาณ...';

  @override
  String get meters => 'เมตร';

  @override
  String get latitude => 'ละติจูด';

  @override
  String get longitude => 'ลองจิจูด';

  @override
  String get altitude => 'ความสูง';

  @override
  String get heading => 'ทิศทาง';

  @override
  String get copyCoordsForRescue => 'คัดลอกพิกัดเพื่อขอความช่วยเหลือ';

  @override
  String get readyForWifiRadio => 'พร้อมสำหรับการสื่อสารทางวิทยุ';

  @override
  String get startingSystem => 'กำลังเริ่มระบบ...';

  @override
  String get identifiableByOthers => 'ผู้อื่นสามารถเห็นคุณได้แล้ว';

  @override
  String get startOfflineSearch => 'เริ่มการค้นหาออฟไลน์';

  @override
  String sendMsgToDevices(int count) {
    return 'ส่งข้อความไปยัง $count อุปกรณ์ใกล้เคียง';
  }

  @override
  String get coordsCopied => 'คัดลอกพิกัดตำแหน่งแล้ว';

  @override
  String get mapTitle => 'สถานพยาบาลใกล้เคียง';

  @override
  String get mapSubtitle => 'ค้นหาสถานพยาบาลที่ใกล้ที่สุด';

  @override
  String mapPoints(int count) {
    return '$count จุด';
  }

  @override
  String get filterAll => 'ทั้งหมด';

  @override
  String get filterHospitals => 'โรงพยาบาล';

  @override
  String get filterClinics => 'คลินิก';

  @override
  String get searchRadius => 'รัศมีค้นหา';

  @override
  String get mapStyle => 'รูปแบบแผนที่';

  @override
  String get kmUnit => 'กม.';

  @override
  String etaLabel(String eta) {
    return 'ถึงใน $eta';
  }

  @override
  String get minutes => 'นาที';

  @override
  String get sosInitialMsg => 'กำลังขอความช่วยเหลือ! โปรดอยู่ในความสงบ';

  @override
  String sosCountdown(int count) {
    return 'กำลังส่งสัญญาณใน $count...';
  }

  @override
  String get sosSent => 'ส่งสัญญาณ SOS สำเร็จ';

  @override
  String get sosActive => 'กำลังทำงาน';

  @override
  String get cancelSos => 'ยกเลิก SOS';

  @override
  String get nearbyUsers => 'คนรอบข้าง';

  @override
  String distUnit(String dist) {
    return '$dist กม.';
  }

  @override
  String get sosHoldCancelHelp => 'ปล่อยเพื่อยกเลิก | ถือต่อเพื่อยืนยัน';

  @override
  String get sosCanceledNotify => 'SOS ถูกยกเลิก';

  @override
  String get sosLoggingLocation => 'ตำแหน่งปัจจุบันกำลังถูกบันทึก';

  @override
  String get sosSendingMedicalData => 'ข้อมูลการแพทย์ของคุณจะถูกส่งไปด้วย';

  @override
  String get sosSentDetail =>
      'เราได้ส่งข้อความ SMS และตำแหน่งของคุณให้คนสนิทแล้ว\nท่านสามารถโทรออกหาผู้ติดต่อฉุกเฉินตอนนี้ได้';

  @override
  String get finishButton => 'เสร็จสิ้น';

  @override
  String get okButton => 'ตกลง';

  @override
  String get noEmergencyContacts => 'ไม่พบผู้ติดต่อฉุกเฉิน';

  @override
  String get addEmergencyContactsHint =>
      'กรุณาเพิ่ม Emergency Contact ก่อนใช้งาน SOS';

  @override
  String get error => 'ผิดพลาด';

  @override
  String get smsAppOpened => 'เปิดแอป SMS แล้ว';

  @override
  String get distance => 'ระยะทาง';

  @override
  String get medicalIDHeader => 'ข้อมูลทางการแพทย์';

  @override
  String get conditionsLabel => 'โรคประจำตัว';

  @override
  String get allergiesLabel => 'อาการแพ้';

  @override
  String get hospitalPrefLabel => 'โรงพยาบาลที่เลือก';

  @override
  String get insuranceLabel => 'บริษัทประกัน';

  @override
  String get notSpecified => 'ไม่ได้ระบุ';

  @override
  String get bodyCompHeader => 'สัดส่วนร่างกาย';

  @override
  String get weightLabel => 'น้ำหนัก';

  @override
  String get heightLabel => 'ส่วนสูง';

  @override
  String get bmiLabel => 'ดัชนีมวลกาย';

  @override
  String get appSettingsHeader => 'ตั้งค่าทั่วไป';

  @override
  String get appLanguageLabel => 'ภาษาของแอป';

  @override
  String get securityHeader => 'ความปลอดภัยและบัญชี';

  @override
  String get deleteAccountLabel => 'ลบบัญชี';

  @override
  String get logoutLabel => 'ออกจากระบบ';

  @override
  String get editProfile => 'แก้ไขข้อมูล';

  @override
  String get saveProfile => 'บันทึกข้อมูล';

  @override
  String get guestUser => 'ผู้ใช้งานทั่วไป';

  @override
  String get ageLabel => 'อายุ';

  @override
  String get bloodTypeShort => 'กรุ๊ปเลือด';

  @override
  String smsConfirmHint(int count) {
    return 'กรุณากดยืนยันการส่งข้อความในแอป SMS\n\nส่งถึง: $count คน';
  }

  @override
  String get cancelButton => 'ยกเลิกทันที';

  @override
  String get filterPharmacies => 'ร้านขายยา';

  @override
  String get openingHours => 'เวลาทำการ';

  @override
  String get openNow => 'เปิดอยู่';

  @override
  String get closed => 'ปิดแล้ว';

  @override
  String get sosConfirmSend => 'กรุณากดยืนยันการส่งข้อความในหน้า SMS ทันที';

  @override
  String get sosHaveYouSent => 'คุณกดยืนยันการส่งข้อความแล้วหรือยัง?';

  @override
  String get yesAlreadySent => 'ส่งเรียบร้อยแล้ว';

  @override
  String get reSendLimit => 'ส่งอีกครั้ง';

  @override
  String get tabPublic => 'สาธารณะ';

  @override
  String get tabPrivate => 'ส่วนตัว';

  @override
  String get onlinePeers => 'โหนดในรัศมี';

  @override
  String get meshRelayTitle => 'บริดจ์และการส่งต่อทอด (Mesh Relay)';

  @override
  String get meshRelayDesc =>
      'ส่งต่อแพ็กเก็ตข้อความและ SOS ข้ามโหนดในรัศมีบลูทูธแบบ Multi-hop';

  @override
  String get dataMuleTitle => 'คนส่งสารฉุกเฉิน (Data Mule)';

  @override
  String get dataMuleDesc =>
      'ฝากส่งข้อความผ่านอุปกรณ์คนอื่นเมื่ออยู่นอกระยะสัญญาณ';

  @override
  String get tacticalCallsign => 'นามเรียกขาน (@callsign)';

  @override
  String get changeCallsign => 'เปลี่ยนชื่อ';

  @override
  String get appLanguage => 'ภาษาของแอป';

  @override
  String get carrierBag => 'กระเป๋าคนส่งสาร';

  @override
  String get selectCarrier => 'เลือกคนส่งสาร (Data Mule)';

  @override
  String get dispatchAllConnected => 'ฝากทุกคนที่เชื่อมต่อ';

  @override
  String get autoPlayVoice => 'เล่นเสียงอัตโนมัติ';

  @override
  String get systemInfo => 'ข้อมูลสถาปัตยกรรมระบบ';

  @override
  String get settingsTab => 'ตั้งค่า';

  @override
  String get infoTab => 'ข้อมูล';

  @override
  String get sendSos => 'ส่งสัญญาณ SOS';

  @override
  String get shareLocation => 'แชร์ตำแหน่งที่ตั้ง';

  @override
  String get recordVoice => 'กดค้างเพื่อบันทึกเสียง';

  @override
  String get offlineBagEmpty => 'ยังไม่มีซองจดหมายในกระเป๋า';

  @override
  String get navFirstAid => 'ปฐมพยาบาล';

  @override
  String get disasterInterface => 'ระบบช่วยเหลือภาวะภัยพิบัติ';

  @override
  String get disasterSub =>
      'เลือกสถานการณ์เพื่อเข้าถึงระบบช่วยเหลือการสื่อสารแบบจำลองและออฟไลน์';

  @override
  String get floodTitle => 'น้ำท่วม';

  @override
  String get floodDesc => 'ฉุกเฉินน้ำท่วมและการสื่อสารออฟไลน์';

  @override
  String get fireTitle => 'ไฟไหม้';

  @override
  String get fireDesc => 'สัญญาณไฟฉายและไซเรนขอความช่วยเหลือ';

  @override
  String get earthquakeTitle => 'แผ่นดินไหว';

  @override
  String get earthquakeDesc => 'สัญญาณขอความช่วยเหลือเบื้องต้น';

  @override
  String get lostTitle => 'การหลงทาง';

  @override
  String get lostDesc => 'เข็มทิศและการระบุพิกัดตำแหน่ง';

  @override
  String get flashlightTitle => 'ไฟฉายฉุกเฉิน';

  @override
  String get flashlightSos => 'โหมด SOS (3 สั้น 3 ยาว 3 สั้น)';

  @override
  String get flashlightStrobe => 'ไฟกะพริบแจ้งเตือน (Strobe)';

  @override
  String strobeSpeed(String speed) {
    return 'ความถี่กะพริบ: $speed Hz';
  }

  @override
  String get sirenTitle => 'ไซเรนฉุกเฉิน';

  @override
  String get sirenPolice => 'เสียงตำรวจ';

  @override
  String get sirenAmbulance => 'เสียงพยาบาล';

  @override
  String get sirenTactical => 'เสียงเตือนภัยยุทธวิธี';

  @override
  String get sirenStop => 'ปิดเสียงไซเรน';

  @override
  String get compassTitle => 'เข็มทิศและการระบุพิกัดตำแหน่ง';

  @override
  String get compassCalibrating => 'กำลังเริ่มต้นเข็มทิศ...';

  @override
  String get compassUnavailable => 'เข็มทิศไม่พร้อมใช้งาน';

  @override
  String get compassPermDenied =>
      'กรุณาเปิดสิทธิ์ตำแหน่ง (Location) ในการตั้งค่าแอปเพื่อใช้เข็มทิศ';

  @override
  String get compassSensorMissing =>
      'อุปกรณ์นี้ไม่มี Magnetometer หรือไม่รองรับเซ็นเซอร์เข็มทิศ';

  @override
  String compassAccuracyLabel(String acc) {
    return 'ความแม่นยำของเซนเซอร์: $acc';
  }

  @override
  String get directionN => 'ทิศเหนือ';

  @override
  String get directionS => 'ทิศใต้';

  @override
  String get directionE => 'ทิศตะวันออก';

  @override
  String get directionW => 'ทิศตะวันตก';

  @override
  String get copyCoordsSuccess => 'คัดลอกลิงก์แผนที่เรียบร้อยแล้ว';

  @override
  String get shareCoordsPrompt => 'แชร์ตำแหน่งของท่าน';

  @override
  String get coordCopiedClip => 'คัดลอกพิกัดลงคลิปบอร์ดแล้ว';

  @override
  String get meshOffline => '#mesh ออฟไลน์';

  @override
  String get meshScanning => 'กำลังค้นหาโหนด...';

  @override
  String meshConnectedNodes(int count) {
    return 'โหนดเชื่อมต่อ $count จุด';
  }

  @override
  String get disasterAlertTitle => 'การแจ้งเตือนภัยพิบัติ';

  @override
  String get noDisasterReport => 'ไม่มีรายงานภัยพิบัติรุนแรงในพื้นที่';

  @override
  String get offlineWeatherInfo => 'ข้อมูลสภาพอากาศแบบออฟไลน์';

  @override
  String get connectivityTitle => 'สถานะการเชื่อมต่อ';

  @override
  String get meshOfflineActive =>
      'โหมดออฟไลน์ Mesh ทำงานสมบูรณ์ (ไม่ใช้อินเทอร์เน็ต)';

  @override
  String get deviceHealthTitle => 'แดชบอร์ดสุขภาพอุปกรณ์';

  @override
  String get batteryLabel => 'แบตเตอรี่';

  @override
  String get storageLabel => 'พื้นที่จัดเก็บ';

  @override
  String get sensorsLabel => 'เซนเซอร์';

  @override
  String get gettingLocation => 'กำลังดึงตำแหน่ง...';

  @override
  String get identifyingLoc => 'กำลังระบุ...';

  @override
  String get openPermSettings => 'เปิดสิทธิ์ในตั้งค่า';

  @override
  String get unknownStreet => 'ไม่ทราบชื่อถนน';

  @override
  String medicalIdComplete(int percent) {
    return 'ข้อมูลการแพทย์สมบูรณ์ $percent%';
  }

  @override
  String get nearestHospitalTitle => 'โรงพยาบาลใกล้ที่สุด';

  @override
  String get anonymousMode => 'โหมดนิรนาม (ANONYMOUS)';

  @override
  String get iceContact => 'ผู้ติดต่อฉุกเฉินด่วน (ICE CONTACT)';

  @override
  String get hikeElevation => 'ระดับความสูง';

  @override
  String get hikeDistance => 'ระยะทาง';

  @override
  String get hikeDuration => 'เวลาเดิน';

  @override
  String get hikeSpeed => 'ความเร็ว';

  @override
  String get hikePace => 'ความเร็วเฉลี่ย';

  @override
  String get hikeAltitude => 'ความสูงจากระดับน้ำทะเล';

  @override
  String get meterUnit => 'ม.';

  @override
  String get backtrackTitle => 'นำทางย้อนรอย';

  @override
  String backtrackDistanceLabel(String dist) {
    return 'ระยะห่างจากจุดเริ่มต้น: $dist';
  }

  @override
  String get backtrackArrived => '🎉 ถึงจุดเริ่มต้นแล้ว!';

  @override
  String get endHikeTitle => 'สิ้นสุดการเดินป่า?';

  @override
  String get endHikeConfirm =>
      'ข้อมูลเส้นทางจะถูกบันทึกเก็บไว้ในอุปกรณ์ของคุณแบบออฟไลน์';

  @override
  String get confirmButton => 'ยืนยัน';

  @override
  String get cancelAction => 'ยกเลิก';

  @override
  String get noticeBoardTitle => 'ประกาศ @ #mesh';

  @override
  String get noticePostEmergency => 'ประกาศฉุกเฉินด่วน';

  @override
  String get noticeDurationLabel => 'ระยะเวลาแสดงประกาศ';

  @override
  String get duration1d => '1 วัน';

  @override
  String get duration3d => '3 วัน';

  @override
  String get duration7d => '7 วัน';

  @override
  String get noticeDelete => 'ลบประกาศ';

  @override
  String get noticeEmpty => 'ยังไม่มีประกาศในขณะนี้';

  @override
  String get noticePostedUrgent =>
      '🚨 ปักประกาศฉุกเฉินและกระจายสัญญาณไปยังทุกโหนดแล้ว';

  @override
  String get noticePostedNormal =>
      '📌 ปักประกาศออฟไลน์สำเร็จ กระจายต่อแบบ Peer-to-Peer';

  @override
  String get callsignDialogTitle => 'เปลี่ยนนามเรียกขาน (@)';

  @override
  String get callsignDialogPrompt =>
      'ชื่อนี้จะแสดงใน #mesh และระบุตัวตนในเครือข่ายออฟไลน์:';

  @override
  String get saveAction => 'บันทึก';

  @override
  String get deleteNoticeConfirm => 'คุณแน่ใจหรือไม่ว่าต้องการลบประกาศนี้?';

  @override
  String get verifyPeerTitle => 'ตรวจสอบตัวตนคู่สนทนา';

  @override
  String get scanPeerQr => 'สแกน QR Code เพื่อยืนยัน';

  @override
  String get myQr => 'QR ของฉัน';

  @override
  String get scanFriendQr => 'สแกน QR เพื่อน';

  @override
  String get qrInstruction =>
      'ให้เพื่อนสแกน QR Code นี้เพื่อยืนยัน Public Key ของคุณ ป้องกันการปลอมแปลงตัวตนในเครือข่าย Mesh';

  @override
  String get verifiedStatus => 'ยืนยันตัวตนแล้ว';

  @override
  String get unverifiedStatus => 'ยังไม่ยืนยันตัวตน';

  @override
  String get keyChangedAlert =>
      '⚠️ คำเตือนความปลอดภัย: กุญแจของคู่สนทนาเปลี่ยนแปลง!';

  @override
  String compareFingerprint(String name) {
    return 'เปรียบเทียบข้อความนี้กับหน้าจอของ $name';
  }

  @override
  String get safetyTitle => 'เช็กความปลอดภัยอัตโนมัติ';

  @override
  String get safetySubtitle => 'ระบบเฝ้าระวังความปลอดภัยยุทธวิธี';

  @override
  String get safetyStandby => 'สแตนด์บาย';

  @override
  String get safetyAlert => 'ภาวะวิกฤต';

  @override
  String get safetyActive => 'กำลังเฝ้าระวัง';

  @override
  String get safetyStandbyDesc =>
      'ระบบพร้อมสแตนด์บาย • เฝ้าระวังอัตโนมัติผ่านเครือข่าย MESH';

  @override
  String get safetyActiveDesc =>
      'ระบบกำลังเฝ้าระวัง • แตะหน้าปัดหรือกดปุ่มเพื่อยืนยันตัวตน';

  @override
  String get safetyCrisisDesc =>
      'ภาวะวิกฤต! กรุณากดยืนยันความปลอดภัยเพื่อยกเลิกการส่ง SOS';

  @override
  String get checkInNow => 'ยืนยันความปลอดภัยทันที';

  @override
  String get recurringCheckin => 'โหมดตรวจสอบซ้ำ';

  @override
  String get facilitiesNearbyTitle => 'พิกัดสถานพยาบาลรอบตัว';

  @override
  String get noFacilitiesFiltered => 'ไม่พบสถานพยาบาลตามตัวกรอง';

  @override
  String get openStatus => 'เปิดทำการอยู่';

  @override
  String get closedStatus => 'ปิดทำการ';

  @override
  String get navigateAction => 'นำทาง';

  @override
  String get callAction => 'โทรออก';

  @override
  String get greetingMorning => 'สวัสดีตอนเช้า,';

  @override
  String get greetingEvening => 'สวัสดีตอนเย็น,';

  @override
  String get urgentNoticeAlert => '🚨 มีประกาศด่วน';

  @override
  String get tapToOpenRadar => 'แตะเพื่อเปิดเรดาร์';

  @override
  String get hikeFloatingActive => '🌲 เดินป่าอยู่';

  @override
  String get hikeFloatingBacktrack => '🧭 กำลังย้อนรอย...';

  @override
  String get gpsSignalLabel => 'สัญญาณ GPS';

  @override
  String get gpsEnabled => 'เปิดใช้งาน';

  @override
  String get gpsDisabled => 'ปิดใช้งาน';

  @override
  String get gpsLockSuccess => 'ระบุตำแหน่งได้';

  @override
  String get gpsLockFail => 'ระบุไม่ได้';

  @override
  String get meshNodesLabel => 'เครือข่าย Mesh';

  @override
  String get meshTapToChat => 'แตะเพื่อแชท';

  @override
  String get meshNoConnection => 'ไม่มีการเชื่อมต่อ';

  @override
  String get nodesUnit => 'โหนด';

  @override
  String get pleaseCharge => 'กรุณาชาร์จ';

  @override
  String get normalStatus => 'ปกติ';

  @override
  String get forecast24h7d => 'พยากรณ์ 24 ชม. & 7 วันข้างหน้า';

  @override
  String get internetUnstable => 'อินเทอร์เน็ตไม่เสถียร';

  @override
  String get offlineMapRecommend =>
      'แนะนำให้สำรองแผนที่ออฟไลน์ไว้เพื่อความปลอดภัยก่อนเดินทางติดขัด';

  @override
  String get downloadMap => 'ดาวน์โหลด';

  @override
  String get startingDownloadMap => 'กำลังเริ่มดาวน์โหลดแผนที่ออฟไลน์...';

  @override
  String get checkInSystemWorking => 'ระบบเช็คอินกำลังทำงาน';

  @override
  String checkInTimeRemaining(String time) {
    return 'เหลือเวลา: $time';
  }

  @override
  String get checkInRecurringSuffix => ' (โหมดวนลูป)';

  @override
  String get checkInAutoPrompt =>
      'ตั้งเวลาเพื่อส่ง SOS อัตโนมัติหากขาดการติดต่อ';

  @override
  String get checkInWarningExpiring => 'เตือน: เวลาใกล้หมดแล้ว!';

  @override
  String get bloodTypePrefix => 'หมู่เลือด - ';

  @override
  String get deactivateSystem => 'DEACTIVATE SYSTEM (ปิดระบบ)';

  @override
  String get iAmSafe => 'ฉันปลอดภัยดี (I AM SAFE)';

  @override
  String get iAmSafeSubtitle => 'กดเพื่อรีเซ็ตเวลานับถอยหลังรอบใหม่';

  @override
  String activateShield(int minutes) {
    return 'ACTIVATE SHIELD • $minutes MIN';
  }

  @override
  String get activateShieldSubtitle => 'เปิดระบบเฝ้าระวังอัตโนมัติ';

  @override
  String get checkInDurationLabel =>
      'เลือกระยะเวลานับถอยหลัง (CHECK-IN DURATION)';

  @override
  String get countingDown => '• กำลังนับเวลาอยู่';

  @override
  String get recurringModeTitle => 'โหมดวนลูป (Recurring)';

  @override
  String get recurringModeSubtitle =>
      'เริ่มนับรอบใหม่อัตโนมัติทันทีหลังกดยืนยันตัวตน';

  @override
  String get systemArmed => 'SYSTEM ARMED';

  @override
  String get tapToArm => 'TAP TO ARM';

  @override
  String get urgentNoticeTitle => '[เตือนภัยด่วน] ';

  @override
  String get urgentNoticeDesc =>
      'ระบบกำลังจะยิงสัญญาณ SOS พร้อมพิกัด GPS อัตโนมัติในไม่ช้า';

  @override
  String get standbyNoticeTitle => '[ระบบเฝ้าระวัง] ';

  @override
  String get standbyNoticeDesc =>
      'หากหมดเวลาโดยไม่มีการตอบรับ ระบบจะยิงพิกัด GPS ฉุกเฉินผ่าน Mesh ทันที';

  @override
  String get endHikeBtn => 'สิ้นสุดการเดินป่า (End Hike)';

  @override
  String get hikeResumeBtn => 'เดินป่าต่อ';

  @override
  String get hikeHoldToEnd => 'HOLD TO END';

  @override
  String backtrackDistanceRemaining(String dist) {
    return 'ห่างอีก $dist';
  }

  @override
  String get backtrackFollowArrow => 'เดินมุ่งหน้าตามลูกศรและรอยเส้นสีส้ม';

  @override
  String get backtrackBasecamp => 'จุดเริ่มต้น (Basecamp ⛳)';

  @override
  String get backtrackNavActive => 'กำลังนำทางกลับจุดเริ่มต้น';

  @override
  String get hikeRecording => 'HIKE RECORDING';

  @override
  String get hikeRecordingTrail => 'กำลังบันทึกรอยทางออฟไลน์';

  @override
  String get hikeMinimizedBox => 'ย่อหน้าจอ (บันทึกต่อในพื้นหลัง)';

  @override
  String get hikeExitDialogTitle => 'ออกจากหน้าเดินป่า?';

  @override
  String get hikeExitDialogDesc =>
      'กิจกรรมการเดินป่ากำลังบันทึกอยู่ คุณต้องการทำรายการใด?';

  @override
  String hikeTrailDistance(String dist, int points) {
    return '$dist กม. • $points จุด';
  }

  @override
  String get shareSmsTitle => 'ส่งพิกัดผ่าน SMS';

  @override
  String get shareSmsSubtitle => 'ส่งข้อความขอความช่วยเหลือทันที';

  @override
  String get copyLinkTitle => 'คัดลอกลิงก์ตำแหน่ง';

  @override
  String get copyLinkSubtitle => 'แชร์พิกัดเป็น Google Maps Link';

  @override
  String get meshOfflineNetworkTitle =>
      'เครือข่ายสื่อสารออฟไลน์ (Mesh Network)';

  @override
  String get meshScanningSubtitle => 'ระบบกำลังสแกนหาคนรอบข้าง...';

  @override
  String get meshOfflineDisabled => 'ปิดการสื่อสารออฟไลน์';

  @override
  String get openChatRoom => 'เปิดห้องแชท';

  @override
  String get localSosTitle => 'ขอความช่วยเหลือเร่งด่วน (Local SOS)';

  @override
  String get localSosSubtitle =>
      'ส่งสัญญาณถึงคนรอบข้างในระยะ 100 เมตร (ออฟไลน์)';

  @override
  String get sosTrappedRoof => 'ติดอยู่บนหลังคา';

  @override
  String get sosNeedFoodWater => 'ต้องการน้ำ/อาหาร';

  @override
  String get sosInjuredElderly => 'มีผู้บาดเจ็บ/สูงอายุ';

  @override
  String get sosWaterRising => 'ระดับน้ำสูงขึ้น';

  @override
  String sosSentBroadcast(String text) {
    return 'ส่งสัญญาณ: $text เรียบร้อยแล้ว';
  }

  @override
  String get urgentSosTitle => 'ขอความช่วยเหลือด่วน (SOS)';

  @override
  String get fireService199 => 'ดับเพลิง (199)';

  @override
  String get medicalService1669 => 'กู้ชีพ (1669)';

  @override
  String get emergencySignalsTitle => 'สัญญาณขอความช่วยเหลือ';

  @override
  String get flashlightSosOff => 'ปิดไฟ SOS';

  @override
  String get flashlightSosOn => 'ไฟฉาย SOS';

  @override
  String get strobeOff => 'ปิดแฟลช';

  @override
  String get strobeOn => 'ไฟแฟลช';

  @override
  String get sirenOff => 'ปิดไซเรน';

  @override
  String get sirenOn => 'ไซเรน';

  @override
  String get safetyCheckShortcutTitle => 'ระบบเช็คอินอัตโนมัติ (Safety Check)';

  @override
  String get safetyCheckShortcutSubtitle =>
      'ส่ง SOS อัตโนมัติหากคุณขาดการติดต่อ';

  @override
  String get hikeActiveTitle => 'กำลังบันทึกการเดินป่า (Hike Active)';

  @override
  String get hikeStartTitle => 'เริ่มเดินป่า (Hike Mode)';

  @override
  String get hikeActiveSubtitle => 'บันทึกเส้นทางแล้ว.. คลิกเพื่อหยุด';

  @override
  String get hikeStartSubtitle => 'บันทึกเส้นทางเดินและปักหมุดปากทาง';

  @override
  String get hikeEndSnackbar => 'สิ้นสุดการบันทึกการเดินป่า';

  @override
  String get hikePrepTitle => 'เตรียมความพร้อมการเดินป่า';

  @override
  String get hikePrepDesc =>
      'กำลังเตรียมพื้นที่เดินป่า (10 ตร.กม.) และแผนที่ Offline';

  @override
  String get hikeStartAdventure => 'เริ่มการผจญภัย (โหมดเดินป่า)';

  @override
  String get unableToGetLocation => 'ไม่สามารถระบุพิกัดได้';

  @override
  String get openAppSettings => 'เปิดการตั้งค่าแอป';

  @override
  String get headingDirectionLabel => 'ทิศทางการมุ่งหน้า';

  @override
  String get directionNE => 'ตะวันออกเฉียงเหนือ (NE)';

  @override
  String get directionSE => 'ตะวันออกเฉียงใต้ (SE)';

  @override
  String get directionSW => 'ตะวันตกเฉียงใต้ (SW)';

  @override
  String get directionNW => 'ตะวันตกเฉียงเหนือ (NW)';

  @override
  String get altitudeMsl => 'ความสูง (MSL)';

  @override
  String get facilitiesNearbySubtitle => 'พิกัดสถานพยาบาลรอบตัว';

  @override
  String facilityUnitCount(int count) {
    return '$count แห่ง';
  }

  @override
  String get searchMedicalHint => 'ค้นหาโรงพยาบาล, คลินิก, ร้านยา...';

  @override
  String get openNowFilter => 'เปิดอยู่ตอนนี้';

  @override
  String get sortByNearest => 'ใกล้ที่สุด';

  @override
  String get sortByName => 'ตามชื่อ A-Z';

  @override
  String get chipAll => 'ทั้งหมด';

  @override
  String get chipHospital => '🏥 รพ.';

  @override
  String get chipClinic => '🩺 คลินิก';

  @override
  String get chipPharmacy => '💊 ร้านยา';

  @override
  String get open24Hours => 'เปิด 24 ชม.';

  @override
  String get myFingerprintTitle => '📱 Fingerprint ของเครื่องคุณ';

  @override
  String myFingerprintDesc(String peer) {
    return 'ให้ $peer ตรวจสอบรหัสนี้บนเครื่องของเขา';
  }

  @override
  String peerFingerprintTitle(String peer) {
    return '🔑 Fingerprint ของ $peer';
  }

  @override
  String peerFingerprintDesc(String peer) {
    return 'เปรียบเทียบข้อความนี้กับหน้าจอของ $peer';
  }

  @override
  String get fingerprintCopied => 'คัดลอก Fingerprint เรียบร้อย';

  @override
  String get noFingerprintData => 'ยังไม่มีข้อมูล Fingerprint ให้คัดลอก';

  @override
  String get verifiedSuccess => 'ยืนยันตัวตนเรียบร้อยแล้ว';

  @override
  String get resetTrust => 'ยกเลิกการยืนยัน (Reset Trust)';

  @override
  String get resetTrustSuccess => 'ยกเลิกการยืนยันเรียบร้อยแล้ว';

  @override
  String get scanQrForKeys => 'สแกน QR Code เพื่อรับ Key ทันที';

  @override
  String get waitingForPublicKey =>
      'ยังไม่ได้รับ Public Key จากคู่สนทนานี้ในระบบ Mesh กรุณารอให้คู่สนทนาออนไลน์ หรือสแกน QR Code เพื่อแลกเปลี่ยนกุญแจทันที';

  @override
  String get acceptNewKey => 'ยืนยันตัวตน Key ใหม่ (Accept New Key)';

  @override
  String get markAsVerified => 'ยืนยันตัวตนคู่สนทนา (Mark as Verified)';
}
