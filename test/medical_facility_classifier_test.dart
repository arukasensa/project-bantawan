import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/core/utils/medical_facility_classifier.dart';
import 'package:flutter1/models/medical_facility.dart';

void main() {
  group('MedicalFacilityClassifier Tests', () {
    test('Hospitals must be classified as hospital (not pharmacy)', () {
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลศิริราช'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลสงขลานครินทร์'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลกรุงเทพหาดใหญ่'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'รพ.สงขลา'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'Bangkok Hospital Hat Yai'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'รพ.สต.บ้านทุ่ง'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลส่งเสริมสุขภาพตำบลควนลัง'), 'hospital');
    });

    test('Pharmacies must be classified as pharmacy', () {
      expect(MedicalFacilityClassifier.classify(name: 'ร้านขายยาฟาร์มาซี'), 'pharmacy');
      expect(MedicalFacilityClassifier.classify(name: 'ร้านยากรุงเทพ'), 'pharmacy');
      expect(MedicalFacilityClassifier.classify(name: 'ศิริราชเภสัช'), 'pharmacy');
      expect(MedicalFacilityClassifier.classify(name: 'Boots Pharmacy'), 'pharmacy');
      expect(MedicalFacilityClassifier.classify(name: 'คลังยาพระราม 2'), 'pharmacy');
      expect(MedicalFacilityClassifier.classify(name: 'เต็กเฮงหยู โอสถ'), 'pharmacy');
    });

    test('Clinics and Health Centers must be classified as clinic', () {
      expect(MedicalFacilityClassifier.classify(name: 'คลินิกหมอสมชาย'), 'clinic');
      expect(MedicalFacilityClassifier.classify(name: 'คลีนิกแพทย์สมบูรณ์'), 'clinic');
      expect(MedicalFacilityClassifier.classify(name: 'ทันตกรรมหาดใหญ่'), 'clinic');
      expect(MedicalFacilityClassifier.classify(name: 'สถานีอนามัยเฉลิมพระเกียรติ'), 'clinic');
      expect(MedicalFacilityClassifier.classify(name: 'ศูนย์บริการสาธารณสุข 4'), 'clinic');
      expect(MedicalFacilityClassifier.classify(name: 'สุขศาลาพระราชทาน'), 'clinic');
    });

    test('Animal hospitals and pet clinics must be rejected (null)', () {
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลสัตว์ทองหล่อ'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'คลินิกรักษาสัตว์หาดใหญ่'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'คลินิกสัตวแพทย์'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'Pet Hospital'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'Vet Clinic'), isNull);
    });

    test('Non-medical places with matching keywords must be rejected (null)', () {
      // Transport
      expect(MedicalFacilityClassifier.classify(name: 'สถานีขนส่งหมอชิต'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'หมอชิต 2'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ป้ายรถเมล์ รพ.กรุงเทพ'), isNull);

      // Food / Restaurant
      expect(MedicalFacilityClassifier.classify(name: 'ก๋วยเตี๋ยวเรือหมอโชค'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ร้านอาหารคุณหมอ'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ยาโยอิ Central'), isNull);

      // Vehicle / Shop
      expect(MedicalFacilityClassifier.classify(name: 'ร้านปะยาง 24 ชม.'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ยามาฮ่า มอเตอร์'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'บีควิก สาขาหาดใหญ่'), isNull);

      // Hotels & General
      expect(MedicalFacilityClassifier.classify(name: 'โรงแรมแกรนด์พาเลซ'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'สายหมอกรีสอร์ท'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ทุเรียนหมอนทอง'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'วิทยาลัยพยาบาลบรมราชชนนี'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'โรงงานยาสูบ'), isNull);

      // Sports & Stadium
      expect(MedicalFacilityClassifier.classify(name: 'สนามฟุตบอลหญ้าเทียมยูอารีน่า สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'สนามฟุตบอลเทศบาล'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'Songkhla Arena Stadium'), isNull);

      // Military, Police & Government Offices (Non-hospital)
      expect(MedicalFacilityClassifier.classify(name: 'ค่ายทหารกรมหลวงสงขลานครินทร์'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'สำนักงานปลัดกระทรวงยุติธรรม สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'สถานีตำรวจภูธรเมืองสงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ที่ว่าการอำเภอเมืองสงขลา'), isNull);

      // Observatory, Science & Culture
      expect(MedicalFacilityClassifier.classify(name: 'หอดูดาวเฉลิมพระเกียรติ 7 รอบ พระชนมพรรษา สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'พิพิธภัณฑสถานแห่งชาติ สงขลา'), isNull);

      // Drinks, Desserts & Food Shops
      expect(MedicalFacilityClassifier.classify(name: 'มี่เสวี่่ย สาขา วชิรา สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'Mixue Ice Cream & Tea'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ชาชักวชิรา'), isNull);

      // Associations & Organizations
      expect(MedicalFacilityClassifier.classify(name: 'สมาคมประมงสงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ชมรมกีฬาว่ายน้ำ'), isNull);
    });

    test('Shops, landmarks, and parking next to/in front of hospitals must be rejected (null)', () {
      // Convenience stores near or inside hospital
      expect(MedicalFacilityClassifier.classify(name: 'เซเว่นข้าง รพ.'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'เซเว่น ข้าง รพ.สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: '7-11 ข้าง รพ.'), isNull);
      expect(MedicalFacilityClassifier.classify(name: '7-11 หน้า รพ.หาดใหญ่'), isNull);
      expect(MedicalFacilityClassifier.classify(name: '7-Eleven สาขา โรงพยาบาลสงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ร้านสะดวกซื้อ ตรงข้าม รพ.'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'CJ Express สาขา หน้า รพ.สทิงพระ'), isNull);

      // Coffee & Food inside or near hospital
      expect(MedicalFacilityClassifier.classify(name: 'Cafe Amazon สาขา รพ.สงขลานครินทร์'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ร้านกาแฟ หน้าโรงพยาบาล'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ศูนย์อาหาร รพ.หาดใหญ่'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'S&P สาขา โรงพยาบาลกรุงเทพ'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ร้านข้าวแกง ตรงข้าม รพ.สงขลา'), isNull);

      // Parking, ATM, Transit near hospital
      expect(MedicalFacilityClassifier.classify(name: 'อาคารจอดรถ รพ.สงขลานครินทร์'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ลานจอดรถ หน้า รพ.'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'วินมอไซค์ หน้า รพ.สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ตู้ ATM ธนาคารไทยพาณิชย์ รพ.สงขลา'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ร้านแว่นท็อปเจริญ หน้า รพ.'), isNull);
      expect(MedicalFacilityClassifier.classify(name: 'ร้านถ่ายเอกสาร ตรงข้าม รพ.'), isNull);
    });

    test('Actual clinics and pharmacies near hospital landmarks must classify correctly', () {
      expect(MedicalFacilityClassifier.classify(name: 'คลินิกหมอสมชาย หน้า รพ.สงขลา'), 'clinic');
      expect(MedicalFacilityClassifier.classify(name: 'ร้านขายยาวชิราเภสัช ตรงข้าม รพ.'), 'pharmacy');
      expect(MedicalFacilityClassifier.classify(name: 'ทันตกรรมหมอเอก ข้าง รพ.หาดใหญ่'), 'clinic');
    });

    test('Real military and police hospitals must still be classified as hospital', () {
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลตำรวจ'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลค่ายเสนาณรงค์'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'โรงพยาบาลทหารผ่านศึก'), 'hospital');
      expect(MedicalFacilityClassifier.classify(name: 'รพ.ค่ายวชิราวุธ'), 'hospital');
    });

    test('Hospitals and emergency facilities are always open', () {
      final hospital = MedicalFacility(
        id: 'h1',
        name: 'โรงพยาบาลส่งเสริมสุขภาพตำบล',
        type: 'hospital',
        address: '',
        latitude: 7.0,
        longitude: 100.0,
        phone: '',
        source: 'osm',
        openingHours: 'Mo-Fr 08:30-16:30',
      );
      expect(MedicalFacilityClassifier.isFacilityOpen(hospital), isTrue);

      final genHospital = MedicalFacility(
        id: 'h2',
        name: 'โรงพยาบาลสงขลา',
        type: 'hospital',
        address: '',
        latitude: 7.0,
        longitude: 100.0,
        phone: '',
        source: 'osm',
      );
      expect(MedicalFacilityClassifier.isFacilityOpen(genHospital), isTrue);
    });
  });
}
