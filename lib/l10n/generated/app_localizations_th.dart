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
}
