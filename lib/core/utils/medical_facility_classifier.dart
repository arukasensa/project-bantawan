// ============================================================================
// 🏥 BANTAWAN Medical Facility Classifier & Validator
// 
// โมดูลจำแนกประเภทและคัดกรองสถานพยาบาล (Hospital, Clinic, Pharmacy)
// แก้ไขปัญหา:
// 1. โรงพยาบาลถูกจัดเป็นร้านยา (เนื่องจาก 'โรงพยาบาล' มีคำว่า 'ยา' อยู่ข้างใน)
// 2. สถานที่อื่นที่ไม่ใช่สถานพยาบาล (หมอชิต, ก๋วยเตี๋ยว, สัตว์เลี้ยง, ยางรถ, โรงแรม)
// ============================================================================

import '../../models/facility_type.dart';
import '../../models/medical_facility.dart';

class MedicalFacilityClassifier {
  // ─── 1. คำที่ต้องตัดทิ้งทันที (Blacklist / Exclusions) ───
  // สถานที่ที่มีคำเหล่านี้ไม่ใช่สถานพยาบาลสำหรับมนุษย์แน่นอน
  static final List<String> _animalExclusions = [
    'สัตว์',
    'สัตวแพทย์',
    'รักษาสัตว์',
    'สัตวรักษ์',
    'pet',
    'vet',
    'veterinary',
    'animal',
    'dog',
    'cat',
  ];

  static final List<String> _transportExclusions = [
    'หมอชิต',
    'สถานีขนส่ง',
    'ท่ารถ',
    'คิวรถ',
    'ป้ายรถ',
    'ป้ายหยุดรถ',
    'ป้ายรถเมล์',
    'สถานีรถไฟ',
    'bts',
    'mrt',
    'airport',
    'สนามบิน',
    'ท่าเรือ',
    // จุดจอดรถ / วินมอเตอร์ไซค์ รอบ รพ.
    'ลานจอดรถ',
    'อาคารจอดรถ',
    'ที่จอดรถ',
    'parking',
    'จุดจอดรถ',
    'จุดรับส่ง',
    'วินมอเตอร์ไซค์',
    'วินมอไซค์',
    'วินรถ',
    'ท่ารถตู้',
    'คิวรถตู้',
    'ป้อมยาม',
  ];

  static final List<String> _foodAndDrinkExclusions = [
    // แบรนด์เครื่องดื่ม/กาแฟ/ของหวาน (โดยเฉพาะที่ตั้งในและรอบ รพ.)
    'มี่เสวี่่ย',
    'มี่เสวี่ย',
    'mixue',
    'ชาชัก',
    'ชานม',
    'ชาพะยอม',
    'ไอศกรีม',
    'ice cream',
    'โรตี',
    'amazon',
    'อเมซอน',
    'cafe amazon',
    'คาเฟ่ อเมซอน',
    'inthanin',
    'อินทนิล',
    'starbucks',
    'สตาร์บัคส์',
    'punthai',
    'พันธุ์ไทย',
    'all cafe',
    'ออลล์ คาเฟ่',
    'ชาตรามือ',
    'chatramue',
    'เต่าบิน',
    'taobin',
    'kudsan',
    'คัดสรร',
    'd\'oro',
    'ดิโอโร่',
    'true coffee',
    'ทรูคอฟฟี่',
    'bellinee',
    'เบลลินี่',
    'swensen',
    'สเวนเซ่นส์',
    'dairy queen',
    'แดรี่ควีน',

    // อาหารทั่วไป และ ร้านอาหาร/ศูนย์อาหารใน รพ.
    'ก๋วยเตี๋ยว',
    'ร้านอาหาร',
    'restaurant',
    'cafe',
    'คาเฟ่',
    'กาแฟ',
    'coffee',
    'เบเกอรี่',
    'bakery',
    'หมูกระทะ',
    'ชาบู',
    'ส้มตำ',
    'ตลาด',
    'ครัว',
    'บาร์',
    'pub',
    'bar',
    'บุฟเฟต์',
    'โต๊ะจีน',
    'ข้าวหมก',
    'ข้าวมันไก่',
    'ข้าวยำ',
    'ก๋วยจั๊บ',
    'ข้าวแกง',
    'อาหารตามสั่ง',
    'ข้าวหมูแดง',
    'ข้าวขาหมู',
    'อาหารจานเดียว',
    'food court',
    'ศูนย์อาหาร',
    'โรงอาหาร',
    'แคนทีน',
    'canteen',
    's&p',
    'เอสแอนด์พี',
    'kfc',
    'เคเอฟซี',
    'mcdonald',
    'แมคโดนัลด์',
    'chester',
    'เชสเตอร์',
    'black canyon',
    'แบล็คแคนยอน',
  ];

  static final List<String> _lodgingExclusions = [
    'โรงแรม',
    'hotel',
    'resort',
    'รีสอร์ท',
    'รีสอร์ต',
    'hostel',
    'อพาร์ทเม้น',
    'อพาร์ทเมนท์',
    'apartment',
    'คอนโด',
    'condo',
    'หอพัก',
    'แมนชั่น',
    'mansion',
    'เกสต์เฮ้าส์',
    'guest house',
    'บังกะโล',
    'บ้านพัก',
    'แฟลต',
    'ตึกพักอาศัย',
  ];

  static final List<String> _vehicleExclusions = [
    'อู่ซ่อม',
    'ปะยาง',
    'ร้านยาง',
    'cockpit',
    'b-quik',
    'บีควิก',
    'ล้างรถ',
    'คาร์แคร์',
    'car care',
    'ปั๊มน้ำมัน',
    'ปั๊มแก๊ส',
    'gas station',
    'ยานยนต์',
    'อะไหล่',
    'มอเตอร์ไซค์',
    'การช่าง',
  ];

  static final List<String> _sportsExclusions = [
    'สนามฟุตบอล',
    'สนามหญ้าเทียม',
    'สนามมวย',
    'สนามกอล์ฟ',
    'สนามเทนนิส',
    'สนามแบดมินตัน',
    'สนามยิงปืน',
    'สนามเด็กเล่น',
    'สนาม',
    'stadium',
    'arena',
    'football',
    'soccer',
    'sport',
    'สปอร์ต',
    'สระว่ายน้ำ',
    'ฟิตเนส',
    'fitness',
    'gym',
    'ยิม',
  ];

  static final List<String> _scienceAndCultureExclusions = [
    'หอดูดาว',
    'ท้องฟ้าจำลอง',
    'พิพิธภัณฑ์',
    'museum',
    'หอศิลป์',
    'อนุสาวรีย์',
    'อนุสรณ์',
    'วัด',
    'มัสยิด',
    'โบสถ์',
    'สำนักสงฆ์',
    'ศาลเจ้า',
    'ฌาปนสถาน',
    'สุสาน',
  ];

  static final List<String> _associationExclusions = [
    'สมาคม',
    'ชมรม',
    'สโมสร',
    'พรรคการเมือง',
  ];

  static final List<String> _militaryAndGovernmentExclusions = [
    'ค่ายทหาร',
    'กองร้อย',
    'กองพัน',
    'มณฑลทหาร',
    'กองบิน',
    'ฐานทัพ',
    'สถานีตำรวจ',
    'สภ.',
    'สน.',
    'ตำรวจภูธร',
    'police',
    'สำนักงาน',
    'กระทรวง',
    'กรมการ',
    'เทศบาล',
    'อบต.',
    'อบจ.',
    'ที่ทำการ',
    'ศาลจังหวัด',
    'ศาลแขวง',
    'ศาลากลาง',
    'ที่ว่าการอำเภอ',
    'สรรพากร',
    'ประกันสังคม',
    'ยุติธรรม',
    'บังคับคดี',
    'คุมประพฤติ',
    'อัยการ',
  ];

  static final List<String> _generalCommerceExclusions = [
    // ร้านสะดวกซื้อ มินิมาร์ท และซูเปอร์มาร์เก็ต
    '7-eleven',
    '7-11',
    '7/11',
    'เซเว่น',
    'เซเว่นอีเลฟเว่น',
    'เซเว่น-อีเลฟเว่น',
    'เซเว่น อีเลฟเว่น',
    'seven-eleven',
    'seven eleven',
    'seven',
    'lawson',
    'ลอว์สัน',
    'family mart',
    'familymart',
    'แฟมิลี่มาร์ท',
    'tops',
    'ท็อปส์',
    'cj express',
    'cj more',
    'ซีเจ',
    'mini big c',
    'มินิบิ๊กซี',
    'lotus',
    'โลตัส',
    'บิ๊กซี',
    'big c',
    'supermarket',
    'ซูเปอร์มาร์เก็ต',
    'ซุปเปอร์มาร์เก็ต',
    'มินิมาร์ท',
    'minimart',
    'mini mart',
    'ร้านสะดวกซื้อ',
    'ร้านของชำ',
    'ของชำ',
    'โชห่วย',
    'ร้านค้า',
    'มาร์ท',
    'mart',

    // ธนาคารและการเงิน
    'ธนาคาร',
    'bank',
    'ตู้ atm',
    'atm',
    'จุดบริการด่วน',

    // ขนส่งพัสดุ
    'ไปรษณีย์',
    'post office',
    'เคอรี่',
    'kerry',
    'flash express',
    'j&t',
    'ninja van',
    'spx express',

    // เสริมสวย / บริการ
    'ซาลอน',
    'เสริมสวย',
    'ตัดผม',
    'ทำเล็บ',
    'salon',
    'barber',
    'นวดแผนไทย',
    'สปา',
    'spa',

    // แว่นตา (ร้านแว่นหน้า รพ.)
    'ท็อปเจริญ',
    'แว่นท็อปเจริญ',
    'ร้านแว่น',
    'หอแว่น',
    'แว่นตา',
    'optical',
    'kt optic',

    // ซักรีด
    'otteri',
    'อ๊อตเทริ',
    'ซักผ้า',
    'ซักรีด',
    'laundry',
    'laundromat',

    // คลัง / โรงงาน / ก่อสร้าง / ถ่ายเอกสาร
    'โกดัง',
    'คลังสินค้า',
    'โรงงาน',
    'ร้านทอง',
    'เฟอร์นิเจอร์',
    'วัสดุก่อสร้าง',
    'ถ่ายเอกสาร',
    'ร้านหนังสือ',
    'ดอกไม้',
  ];

  // คำที่มีคำว่า 'ยา' หรือ 'หมอ' แต่ไม่ใช่ร้านยาหรือสถานพยาบาล
  static final List<String> _falsePositiveExclusions = [
    'ยาโยอิ',
    'yayoi',
    'ยามาฮ่า',
    'yamaha',
    'ยาสูบ',
    'ยาสีฟัน',
    'ยาหยี',
    'หมอนทอง',
    'ทะเลหมอก',
    'สายหมอก',
    'หม่อม',
  ];

  // คำระบุตำแหน่งเปรียบเทียบกับโรงพยาบาล (Landmark / Relative Location Indicators)
  // สถานที่ที่มีคำเหล่านี้ เป็นเพียงสถานที่ข้างเคียง/ตรงข้าม/ใกล้เคียง ไม่ใช่ตัวโรงพยาบาลเอง
  static final List<String> _relativeLocationIndicators = [
    'ข้าง รพ',
    'ข้างรพ',
    'ข้าง โรงพยาบาล',
    'ข้างโรงพยาบาล',
    'หน้า รพ',
    'หน้ารพ',
    'หน้า โรงพยาบาล',
    'หน้าโรงพยาบาล',
    'ตรงข้าม รพ',
    'ตรงข้ามรพ',
    'ตรงข้าม โรงพยาบาล',
    'ตรงข้ามโรงพยาบาล',
    'ฝั่งตรงข้าม รพ',
    'ฝั่งตรงข้ามรพ',
    'ฝั่งตรงข้าม โรงพยาบาล',
    'ฝั่งตรงข้ามโรงพยาบาล',
    'ใกล้ รพ',
    'ใกล้รพ',
    'ใกล้ โรงพยาบาล',
    'ใกล้โรงพยาบาล',
    'หลัง รพ',
    'หลังรพ',
    'หลัง โรงพยาบาล',
    'หลังโรงพยาบาล',
    'เยื้อง รพ',
    'เยื้องรพ',
    'เยื้อง โรงพยาบาล',
    'เยื้องโรงพยาบาล',
    'ติด รพ',
    'ติดรพ',
    'ติด โรงพยาบาล',
    'ติดโรงพยาบาล',
    'รอบ รพ',
    'รอบรพ',
    'รอบ โรงพยาบาล',
    'รอบโรงพยาบาล',
    'ซอย รพ',
    'ซอยรพ',
    'ซอย โรงพยาบาล',
    'ซอยโรงพยาบาล',
    'ซอยข้าง รพ',
    'ซอยข้างโรงพยาบาล',
    'opp. hospital',
    'opposite hospital',
    'near hospital',
    'next to hospital',
    'behind hospital',
    'beside hospital',
    'in front of hospital',
  ];

  // ─── 2. คัดกรองและจำแนกประเภท (Classification Logic) ───
  /// ตรวจสอบว่าสถานที่นี้ติดรายการ Blacklist (สัตว์เลี้ยง, ขนส่ง, อาหาร, ซ่อมรถ, กีฬา, ทหาร, ธุรกิจทั่วไป) หรือไม่
  static bool isBlacklisted(
    String name, {
    String? tag,
    String? amenity,
    String? healthcare,
  }) {
    final lowerName = name.toLowerCase().trim();
    final lowerTag = (tag ?? '').toLowerCase().trim();
    final lowerAmenity = (amenity ?? '').toLowerCase().trim();
    final lowerHealthcare = (healthcare ?? '').toLowerCase().trim();

    // 1. ตรวจสอบสัตว์เลี้ยง/สัตวแพทย์ (ตัดทิ้งเด็ดขาดเสมอ)
    for (final word in _animalExclusions) {
      if (lowerName.contains(word) ||
          lowerTag.contains(word) ||
          lowerAmenity.contains(word) ||
          lowerHealthcare.contains(word)) {
        return true;
      }
    }

    // 2. ตัดทิ้งคำที่เป็น false positive
    for (final word in _falsePositiveExclusions) {
      if (lowerName.contains(word)) return true;
    }

    // 3. กีฬา / สนามกีฬา / สันทนาการ
    for (final word in _sportsExclusions) {
      if (lowerName.contains(word)) return true;
    }

    // 4. หอดูดาว / พิพิธภัณฑ์ / โบราณสถาน / ศาสนสถาน
    for (final word in _scienceAndCultureExclusions) {
      if (lowerName.contains(word)) return true;
    }

    // 5. ตัดทิ้งสถานที่ขนส่ง, อาหาร/เครื่องดื่ม, ที่พัก, ซ่อมรถ, ธุรกิจทั่วไป
    for (final word in _transportExclusions) {
      if (lowerName.contains(word)) return true;
    }
    for (final word in _foodAndDrinkExclusions) {
      if (lowerName.contains(word)) return true;
    }
    for (final word in _lodgingExclusions) {
      if (lowerName.contains(word)) return true;
    }
    for (final word in _vehicleExclusions) {
      if (lowerName.contains(word)) return true;
    }
    for (final word in _generalCommerceExclusions) {
      if (lowerName.contains(word)) return true;
    }

    // 6. ตรวจสอบสถานที่ที่อ้างอิงตำแหน่งข้างเคียงโรงพยาบาล (ข้าง รพ., หน้า รพ., ตรงข้าม รพ.)
    // หากไม่ใช่คลินิก หรือร้านขายยาจริง ให้ตัดทิ้งทันที (เช่น เซเว่นข้าง รพ., ร้านข้าวแกง หน้า รพ.)
    final hasRelativeHospitalLocation = _relativeLocationIndicators.any((phrase) => lowerName.contains(phrase));
    if (hasRelativeHospitalLocation) {
      final isActualClinicOrPharmacy = lowerName.contains('คลินิก') ||
          lowerName.contains('คลีนิก') ||
          lowerName.contains('clinic') ||
          lowerName.contains('ทันตกรรม') ||
          lowerName.contains('ทันตแพทย์') ||
          lowerName.contains('สถานีอนามัย') ||
          lowerName.contains('ร้านขายยา') ||
          lowerName.contains('ร้านยา') ||
          lowerName.contains('เภสัช') ||
          lowerName.contains('ฟาร์มาซี') ||
          lowerName.contains('pharmacy');
      if (!isActualClinicOrPharmacy) {
        return true;
      }
    }

    // ตรวจสอบว่ามีชื่อระบุเป็นสถานพยาบาลมนุษย์แท้จริงหรือไม่
    final hasGenuineMedicalIdentity = !hasRelativeHospitalLocation && (
        lowerName.contains('โรงพยาบาล') ||
        lowerName.contains('hospital') ||
        lowerName.contains('รพ.') ||
        lowerName.contains('รพ.สต.') ||
        lowerName.contains('ศูนย์การแพทย์') ||
        lowerName.contains('สถานพยาบาล') ||
        lowerName.contains('คลินิก') ||
        lowerName.contains('คลีนิก') ||
        lowerName.contains('clinic') ||
        lowerName.contains('ร้านขายยา') ||
        lowerName.contains('ร้านยา') ||
        lowerName.contains('เภสัช') ||
        lowerName.contains('สถานีอนามัย') ||
        lowerAmenity == 'hospital' ||
        lowerHealthcare == 'hospital');

    // 7. สมาคม / ชมรม / องค์กร (ตัดทิ้ง ยกเว้นมีระบุว่าเป็นสถานพยาบาลชัดเจน)
    for (final word in _associationExclusions) {
      if (lowerName.contains(word) && !hasGenuineMedicalIdentity) return true;
    }

    // 8. ค่ายทหาร / สถานีตำรวจ / สถานที่ราชการ / สำนักงาน / กระทรวง
    // (ตัดทิ้ง ยกเว้นเป็นโรงพยาบาลจริง เช่น โรงพยาบาลตำรวจ, โรงพยาบาลค่ายเสนาณรงค์)
    for (final word in _militaryAndGovernmentExclusions) {
      if (lowerName.contains(word) && !hasGenuineMedicalIdentity) return true;
    }

    // 9. สถาบันการศึกษา (โรงเรียน, มหาวิทยาลัย) ยกเว้นโรงพยาบาลมหาวิทยาลัย
    final isEducational = lowerName.contains('โรงเรียน') ||
        lowerName.contains('มหาวิทยาลัย') ||
        lowerName.contains('วิทยาลัย') ||
        lowerName.contains('อนุบาล') ||
        lowerName.contains('มัธยม');

    if (isEducational && !hasGenuineMedicalIdentity) {
      return true;
    }

    return false;
  }

  // ─── 2. คัดกรองและจำแนกประเภท (Classification Logic) ───
  /// จำแนกชื่อและแท็กของสถานที่:
  /// ส่งคืน 'hospital', 'clinic', 'pharmacy' หรือ null หากไม่ใช่สถานพยาบาล
  static String? classify({
    required String name,
    String? tag,
    String? amenity,
    String? healthcare,
    String? building,
    String? existingType,
    String? fallbackType,
  }) {
    if (isBlacklisted(name, tag: tag, amenity: amenity, healthcare: healthcare)) {
      return null;
    }

    final lowerName = name.toLowerCase().trim();
    final lowerAmenity = (amenity ?? '').toLowerCase().trim();
    final lowerHealthcare = (healthcare ?? '').toLowerCase().trim();
    final lowerBuilding = (building ?? '').toLowerCase().trim();

    final hasRelativeHospitalLocation = _relativeLocationIndicators.any((phrase) => lowerName.contains(phrase));

    // ─── กฎที่ 1: ตรวจสอบจากชื่อสถานที่ (Name Ground-Truth) ก่อนเสมอ ───
    // ก) หากชื่อระบุชัดเจนว่าเป็นโรงพยาบาล (รวมถึง รพ.สต., รพ., ศูนย์การแพทย์, สถานพยาบาล)
    // ⚠️ ต้องไม่เป็นสถานที่อ้างอิงตำแหน่งข้างเคียง เช่น ข้าง รพ., หน้า รพ., ตรงข้าม รพ.
    final hasHospitalName = !hasRelativeHospitalLocation && (
        lowerName.contains('โรงพยาบาล') ||
        lowerName.contains('hospital') ||
        lowerName.contains('รพ.') ||
        lowerName.contains('รพ.สต.') ||
        lowerName.contains('ศูนย์การแพทย์') ||
        lowerName.contains('สถานพยาบาล') ||
        lowerName.contains('ศูนย์แพทยศาสตร์') ||
        lowerName.contains('สถาบันการแพทย์'));

    // ข) หากชื่อระบุชัดเจนว่าเป็นคลินิก, ทันตกรรม, อนามัย, เวชกรรม ฯลฯ
    final hasClinicName = lowerName.contains('คลินิก') ||
        lowerName.contains('คลีนิก') ||
        lowerName.contains('clinic') ||
        lowerName.contains('ทันตกรรม') ||
        lowerName.contains('ทันตแพทย์') ||
        lowerName.contains('ทำฟัน') ||
        lowerName.contains('dental') ||
        lowerName.contains('สถานีอนามัย') ||
        lowerName.contains('ศูนย์อนามัย') ||
        lowerName.contains('อนามัย') ||
        lowerName.contains('ศูนย์บริการสาธารณสุข') ||
        lowerName.contains('สุขศาลา') ||
        lowerName.contains('เวชกรรม') ||
        lowerName.contains('การแพทย์') ||
        lowerName.contains('โพลีคลินิก') ||
        lowerName.contains('polyclinic') ||
        lowerName.contains('กายภาพบำบัด') ||
        lowerName.contains('กายภาพ') ||
        lowerName.contains('แพทย์แผนไทย') ||
        lowerName.contains('ไตเทียม') ||
        lowerName.contains('ตรวจโรค') ||
        lowerName.contains('ชันสูตร') ||
        lowerName.contains('การพยาบาล') ||
        lowerName.startsWith('หมอ') ||
        lowerName.contains('คลินิกหมอ') ||
        lowerName.contains('คลินิกแพทย์') ||
        lowerName.contains('ศูนย์สุขภาพ');

    // ค) หากชื่อระบุชัดเจนว่าเป็นร้านขายยา
    final hasPharmacyName = lowerName.contains('ร้านขายยา') ||
        lowerName.contains('ร้านยา') ||
        lowerName.contains('เภสัช') ||
        lowerName.contains('ฟาร์มาซี') ||
        lowerName.contains('pharmacy') ||
        lowerName.contains('drugstore') ||
        lowerName.contains('drug store') ||
        lowerName.contains('chemist') ||
        lowerName.contains('apothecary') ||
        lowerName.contains('boots') ||
        lowerName.contains('watsons') ||
        lowerName.contains('คลังยา') ||
        (lowerName.contains('โอสถ') && !lowerName.contains('โอสถสภา'));

    // ถือชื่อเป็นเกณฑ์ชี้ขาด:
    // 1. ถ้ามีชื่อโรงพยาบาล -> hospital
    if (hasHospitalName) {
      return 'hospital';
    }
    // 2. ถ้าชื่อบอกว่าเป็นคลินิก (และไม่ได้มีคำว่าโรงพยาบาล) -> clinic เด็ดขาด! ไม่ให้กลายเป็น hospital
    if (hasClinicName) {
      return 'clinic';
    }
    // 3. ถ้าชื่อบอกว่าเป็นร้านขายยา -> pharmacy
    if (hasPharmacyName) {
      return 'pharmacy';
    }

    // ─── กฎที่ 2: หากชื่อไม่ได้ระบุ ให้ดูจาก OpenStreetMap Semantic Tags เท่านั้น ───
    final isTagHospital = lowerAmenity == 'hospital' ||
        lowerHealthcare == 'hospital' ||
        lowerBuilding == 'hospital';
    if (isTagHospital) return 'hospital';

    final isTagPharmacy = lowerAmenity == 'pharmacy' ||
        lowerHealthcare == 'pharmacy';
    if (isTagPharmacy) return 'pharmacy';

    final isTagClinic = lowerAmenity == 'clinic' ||
        lowerAmenity == 'doctors' ||
        lowerAmenity == 'health_post' ||
        lowerHealthcare == 'clinic' ||
        lowerHealthcare == 'doctor' ||
        lowerHealthcare == 'dentist' ||
        lowerHealthcare == 'physiotherapist';
    if (isTagClinic) return 'clinic';

    // ─── กฎที่ 3: หากไม่มีหลักฐานชัดเจนว่าเป็นสถานพยาบาล ห้ามเดาหรือ fallback เด็ดขาด ───
    return null;
  }

  /// ตรวจสอบว่า MedicalFacility นี้เป็นสถานที่ทางการแพทย์ที่ถูกต้องหรือไม่
  static bool isValidFacility(MedicalFacility facility) {
    // 1. ตรวจสอบ Blacklist
    if (isBlacklisted(facility.name)) return false;

    // 2. จำแนกประเภท — ต้องระบุได้ว่าเป็น hospital, clinic หรือ pharmacy ชัดเจน
    final type = classify(
      name: facility.name,
      amenity: facility.source == 'osm' ? facility.type : null,
      healthcare: facility.source == 'osm' ? facility.type : null,
    );
    return type != null;
  }

  /// คืนค่า Enum FacilityType จาก string ที่ normalize แล้ว
  static FacilityType? stringToFacilityType(String? typeStr) {
    if (typeStr == null) return null;
    switch (typeStr.toLowerCase()) {
      case 'hospital':
        return FacilityType.hospital;
      case 'clinic':
        return FacilityType.clinic;
      case 'pharmacy':
        return FacilityType.pharmacy;
      default:
        return null;
    }
  }

  /// ตรวจสอบว่าสถานพยาบาลเปิดให้บริการอยู่หรือไม่
  static bool isFacilityOpen(MedicalFacility facility, [DateTime? now]) {
    final current = now ?? DateTime.now();

    // 1. โรงพยาบาล (Hospital) หรือสถานพยาบาลที่มีแผนกฉุกเฉินเปิดให้บริการตลอด 24 ชั่วโมงเสมอ
    if (facility.type.toLowerCase() == 'hospital' ||
        facility.hasEmergency ||
        facility.isOpen24Hours ||
        facility.name.contains('โรงพยาบาล') ||
        facility.name.contains('รพ.')) {
      return true;
    }

    // 2. หากไม่มีข้อมูลเวลาทำการที่แน่ชัด ให้ถือว่าเปิดให้บริการ (ตามเวลาปกติ)
    if (facility.openingHours == null || facility.openingHours!.trim().isEmpty) {
      return true;
    }

    final lower = facility.openingHours!.toLowerCase().trim();

    // 3. ระบุว่าเปิด 24 ชม. หรือตลอดเวลา
    if (lower.contains('24') || lower.contains('24/7') || lower.contains('open')) {
      return true;
    }

    // 4. ระบุว่าปิดถาวร หรือปิดบริการ
    if (lower.contains('closed') || lower.contains('ปิด') || lower.contains('off')) {
      return false;
    }

    // 5. ตรวจสอบช่วงเวลา (เช่น 08:00-17:00 หรือ 08:30-16:30)
    final timeMatch = RegExp(r'(\d{1,2})[:.](\d{2})\s*-\s*(\d{1,2})[:.](\d{2})').firstMatch(lower);
    if (timeMatch != null) {
      final startHour = int.tryParse(timeMatch.group(1)!) ?? 8;
      final startMin = int.tryParse(timeMatch.group(2)!) ?? 0;
      final endHour = int.tryParse(timeMatch.group(3)!) ?? 17;
      final endMin = int.tryParse(timeMatch.group(4)!) ?? 0;

      final currentMinutes = current.hour * 60 + current.minute;
      final startMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;

      // ตรวจสอบวันหยุดสุดสัปดาห์หากระบุชัดเจนว่า Mo-Fr
      if (lower.contains('mo-fr') &&
          (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday)) {
        return false;
      }

      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }

    // หากไม่สามารถระบุได้ชัดเจน ให้ default เป็นเปิดทำการ
    return true;
  }
}
