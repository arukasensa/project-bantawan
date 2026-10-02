// ============================================================================
// 🏥 BANTAWAN Offline First Aid Knowledge Base: FirstAidService
// 
// ┌─────────────────────────────────────────────────────────┐
// │                     BANTAWAN App                        │
// │            (Offline Survival & Emergency Care)          │
// ├─────────────────────────────────────────────────────────┤
// │                  FirstAidService                        │
// │  ┌───────────────────────────────────────────────────┐  │
// │  │           Static In-Memory Knowledge Base         │  │
// │  │   (CPR / Choking / Burns / Fractures / Bites)     │  │
// │  │   รองรับ 2 ภาษา: ไทย + อังกฤษ | Offline 100%     │  │
// │  └───────────────────────────────────────────────────┘  │
// └─────────────────────────────────────────────────────────┘
// 
// บริการคลังความรู้การปฐมพยาบาลเบื้องต้น (First Aid Guide Service)
// ข้อมูลทั้งหมดเป็น Static Data ฝังตัวในแอป ไม่ต้องอาศัยอินเทอร์เน็ต
// รองรับคู่มือการช่วยชีวิตสำคัญ:
//   - CPR (การกดหน้าอกช่วยชีวิต)
//   - Choking (สิ่งแปลกปลอมอุดหลอดลม)
//   - Burns (แผลไฟไหม้)
//   - Fractures (กระดูกหัก)
//   - Animal Bites / Poisoning (สัตว์กัดต่อย / พิษ)
// ============================================================================

/// 📦 โมเดลขั้นตอนการปฐมพยาบาลแต่ละลำดับ (FirstAidStep)
/// แต่ละขั้นตอนมีหัวข้อ คำอธิบาย ภาพประกอบ และ Animation Type รองรับ 2 ภาษา
class FirstAidStep {
  /// ลำดับขั้นตอนที่ (1, 2, 3...)
  final int stepNumber;

  /// หัวข้อขั้นตอน (ภาษาไทย)
  final String title;

  /// รายละเอียดวิธีปฏิบัติ (ภาษาไทย)
  final String description;

  /// หัวข้อขั้นตอน (ภาษาอังกฤษ)
  final String? titleEn;

  /// รายละเอียดวิธีปฏิบัติ (ภาษาอังกฤษ)
  final String? descriptionEn;

  /// พาธรูปภาพประกอบใน assets
  final String? imageAsset;

  /// ประเภทแอนิเมชันภาพเคลื่อนไหวจำลอง (Visual Type)
  final String? visualType;

  FirstAidStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.titleEn,
    this.descriptionEn,
    this.imageAsset,
    this.visualType,
  });

  String getTitle(bool isThai) => isThai ? title : (titleEn ?? title);
  String getDescription(bool isThai) => isThai ? description : (descriptionEn ?? description);
}

/// 📦 โมเดลหัวข้อหมวดหมู่อาการบาดเจ็บ/การปฐมพยาบาล (FirstAidTopic)
/// จัดกลุ่มขั้นตอนการปฐมพยาบาล พร้อมไอคอน สี และคำเตือนสำคัญ รองรับ 2 ภาษา
class FirstAidTopic {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String color;
  final List<FirstAidStep> steps;
  final String? warning;
  final String? titleEn;
  final String? subtitleEn;
  final String? warningEn;

  FirstAidTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
    this.warning,
    this.titleEn,
    this.subtitleEn,
    this.warningEn,
  });

  String getTitle(bool isThai) => isThai ? title : (titleEn ?? title);
  String getSubtitle(bool isThai) => isThai ? subtitle : (subtitleEn ?? subtitle);
  String? getWarning(bool isThai) => isThai ? warning : (warningEn ?? warning);
}

/// 🏛️ คลาสบริการคลังข้อมูลการปฐมพยาบาล (FirstAidService)
/// ให้บริการข้อมูลคู่มือช่วยชีวิตแบบ Static ทำงานได้เต็มประสิทธิภาพในโหมดออฟไลน์
class FirstAidService {
  /// 📌 ดึงรายการหัวข้อการปฐมพยาบาลทั้งหมด พร้อมขั้นตอนปฏิบัติครบชุด
  /// ส่งคืน List ของ [FirstAidTopic] ที่มีข้อมูลสมบูรณ์ ครอบคลุมอาการฉุกเฉินที่พบบ่อยในการเดินป่า
  static List<FirstAidTopic> getTopics() {
    return [
      // ─── CPR ───────────────────────────────────────────────────
      FirstAidTopic(
        id: 'cpr',
        title: 'การทำ CPR',
        titleEn: 'CPR (Cardiopulmonary Resuscitation)',
        subtitle: 'การปั๊มหัวใจกู้ชีพ',
        subtitleEn: 'Emergency Cardiac Rescue',
        icon: '🫀',
        color: '0xFFE53935',
        warning: 'โทร 1669 ทันทีก่อนเริ่มทำการช่วยเหลือ หากผู้ป่วยไม่หายใจ',
        warningEn: 'Call 1669 / emergency services immediately before starting CPR if the patient is not breathing.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ประเมินสถานการณ์ (Check)',
            titleEn: 'Assess Situation (Check)',
            description:
                'ตรวจสอบความปลอดภัยของสถานที่ก่อนเข้าไปช่วยเหลือ จากนั้นปลุกเรียกผู้ป่วยด้วยการตบไหล่ทั้งสองข้างแรงๆ และเรียกด้วยเสียงดัง หากผู้ป่วยไม่ตอบสนอง ไม่ขยับตัว หรือหายใจเฮือก/ไม่หายใจ ให้ถือว่าอยู่ในสภาวะหัวใจหยุดเต้น',
            descriptionEn:
                'Ensure scene safety. Tap both shoulders firmly and shout loudly to wake patient. If unresponsive or not breathing normally, treat as cardiac arrest.',
            imageAsset: 'assets/images/first_aid/cpr_overview.jpg',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ขอความช่วยเหลือ (Call)',
            titleEn: 'Call for Help (Call)',
            description:
                'ตะโกนขอความช่วยเหลือจากคนรอบข้าง และมอบหมายคนใดคนหนึ่งให้รีบโทรสายด่วน 1669 ทันที เพื่อแจ้งสถานที่เกิดเหตุ อาการผู้ป่วย และขอเครื่องช็อตหัวใจไฟฟ้าอัตโนมัติ (AED) มายังจุดเกิดเหตุโดยเร็วที่สุด',
            descriptionEn:
                'Shout for help. Assign someone to call 1669 / 911 immediately and request an Automated External Defibrillator (AED).',
            visualType: 'call_1669',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'การกดหน้าอก (Compressions)',
            titleEn: 'Chest Compressions',
            description:
                'จัดผู้ป่วยนอนหงายบนพื้นแข็ง คุกเข่าข้างลำตัว วางส้นมือข้างหนึ่งกึ่งกลางหน้าอก (แนวกระดูกหน้าอก) ประสานมืออีกข้างด้านบน เหยียดแขนตึง โน้มตัวให้ไหล่ตั้งฉากกับหน้าอก กดลงลึก 5-6 ซม. และปล่อยให้หน้าอกคืนตัวสุด ห้ามยกมือออกจากอก',
            descriptionEn:
                'Lay patient on firm surface. Place heel of hand on center of chest, interlock fingers, keep arms straight, compress 5-6 cm deep.',
            imageAsset: 'assets/images/first_aid/cpr_compression.jpg',
          ),
          FirstAidStep(
            stepNumber: 4,
            title: 'จังหวะและความต่อเนื่อง',
            titleEn: 'Rhythm & Continuity',
            description:
                'กดด้วยความเร็ว 100-120 ครั้งต่อนาที (ให้สอดคล้องกับจังหวะเพลง "คุ้กกี้เสี่ยงทาย" หรือ "Staying Alive") ทำต่อเนื่องจนกว่าทีมกู้ชีพจะมาถึง หรือเครื่อง AED พร้อมทำงาน หรือผู้ป่วยกลับมารู้สึกตัว',
            descriptionEn:
                'Compress at a rate of 100-120 beats per minute (to the rhythm of "Staying Alive"). Continue until help or AED arrives.',
            visualType: 'pulse',
          ),
        ],
      ),

      // ─── Choking ──────────────────────────────────────────────
      FirstAidTopic(
        id: 'choking',
        title: 'สำลัก/อาหารติดคอ',
        titleEn: 'Choking First Aid',
        subtitle: 'การช่วยเหลือเมื่อมีสิ่งอุดกั้นทางเดินหายใจ',
        subtitleEn: 'Airway Obstruction Rescue',
        icon: '😮',
        color: '0xFFFB8C00',
        warning:
            'หากผู้ป่วยไอไม่ได้ พูดไม่ได้ หรือหายใจไม่ออก ให้รีบช่วยเหลือทันที',
        warningEn: 'If the person cannot cough, speak, or breathe, provide immediate assistance.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ประเมินการสำลัก',
            titleEn: 'Assess Choking',
            description:
                'ถามผู้ป่วยว่า "สำลักใช่ไหม?" หากผู้ป่วยพยักหน้าแต่พูดไม่มีเสียง เอามือกุมคอ แสดงว่ามีการอุดกั้นรุนแรง หากยังไอได้เองให้ส่งเสริมให้ไอออกมา อย่าเพิ่งไปตบหลัง',
            descriptionEn:
                'Ask if they are choking. If they nod and clutch their neck without sound, perform Heimlich maneuver immediately.',
            imageAsset: 'assets/images/first_aid/choking_overview.jpg',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'การจัดท่าทางช่วยเหลือ',
            titleEn: 'Rescue Positioning',
            description:
                'ยืนซ้อนด้านหลังผู้ป่วย แยกเท้าออกเพื่อความมั่นคง สอดแขนทั้งสองข้างใต้รักแร้โอบรอบเอวผู้ป่วย โน้มตัวผู้ป่วยไปด้านหน้าเล็กน้อย',
            descriptionEn:
                'Stand behind patient, place arms under armpits around waist, lean patient slightly forward.',
            visualType: 'positioning',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'รัดกระตุกหน้าท้อง (Heimlich Maneuver)',
            titleEn: 'Abdominal Thrusts (Heimlich)',
            description:
                'กำมือข้างหนึ่งวางเหนือสะดือ แต่อยู่ใต้ลิ้นปี่ เอามืออีกข้างกุมมือที่กำไว้ แล้วออกแรงรัดกระตุกเข้าหาตัวและขึ้นด้านบนเฉียงๆ อย่างรวดเร็วและรุนแรง เพื่อเพิ่มแรงดันในทรวงอกผลักสิ่งแปลกปลอมออกมา',
            descriptionEn:
                'Make a fist above navel, grasp with other hand, thrust inward and upward rapidly.',
            imageAsset: 'assets/images/first_aid/heimlich.jpg',
          ),
          FirstAidStep(
            stepNumber: 4,
            title: 'กรณีหมดสติ',
            titleEn: 'If Unconscious',
            description:
                'หากสิ่งแปลกปลอมยังไม่หลุดและผู้ป่วยหมดสติ ให้ค่อยๆ วางผู้ป่วยลงบนพื้นราบและเริ่มทำ CPR ทันที พร้อมทั้งสังเกตในปากว่ามีสิ่งแปลกปลอมหลุดออกมาให้เห็นหรือไม่',
            descriptionEn:
                'If object does not come out and patient loses consciousness, lower patient to ground and begin CPR immediately.',
            imageAsset: 'assets/images/first_aid/cpr_compression.jpg',
          ),
        ],
      ),

      // ─── Bleeding ─────────────────────────────────────────────
      FirstAidTopic(
        id: 'bleeding',
        title: 'เลือดออก/บาดแผล',
        titleEn: 'Bleeding & Wounds',
        subtitle: 'การห้ามเลือดและปฐมพยาบาลบาดแผล',
        subtitleEn: 'Hemostasis & Wound First Aid',
        icon: '🩸',
        color: '0xFFD32F2F',
        warning:
            'สวมถุงมือยางหากเป็นไปได้ เพื่อป้องกันการติดเชื้อจากเลือดผู้ป่วย',
        warningEn: 'Wear gloves if available to prevent infection from blood.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'การกดตำแหน่งเลือดออก',
            titleEn: 'Direct Pressure',
            description:
                'ใช้ผ้าสะอาดหรือหน้าผากรองกดลงบนบาดแผลโดยตรงด้วยแรงที่สม่ำเสมอเพื่อห้ามเลือด หากเลือดซึมออกมาจนผ้าชุ่ม ให้วางผ้าผืนใหม่ทับลงไปทันที (ห้ามดึงผ้าเดิมออกเพราะจะทำให้ลิ่มเลือดหลุด)',
            descriptionEn:
                'Apply direct firm pressure on wound with clean cloth. Add more cloth if soaked, do not remove original cloth.',
            imageAsset: 'assets/images/first_aid/bleeding_pressure.jpg',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ยกส่วนที่บาดเจ็บให้สูง',
            titleEn: 'Elevate Limb',
            description:
                'หากบาดแผลอยู่ที่แขนหรือขา และไม่มีรอยหักของกระดูก ให้ยกอวัยวะนั้นให้สูงกว่าระดับหัวใจของผู้ป่วย เพื่อลดแรงดันเลือดที่ไปเลี้ยงบริเวณแผล ช่วยให้เลือดหยุดไหลได้เร็วขึ้น',
            descriptionEn:
                'If wound is on arm or leg without fracture, elevate above heart level to slow bleeding.',
            visualType: 'elevation',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'การพันแผล',
            titleEn: 'Bandage Wound',
            description:
                'เมื่อเลือดหยุดไหลหรือไหลซึมช้าลง ให้ใช้ผ้าพันแผลพันรอบผ้าก๊อซให้แน่นพอดี ไม่แน่นจนปลายนิ้วเขียวคล้ำ และรีบนำส่งโรงพยาบาลหากแผลลึกหรือมีสิ่งแปลกปลอมฝังอยู่',
            descriptionEn:
                'Wrap bandage firmly over dressing once bleeding slows. Seek medical attention if deep.',
            visualType: 'bandage',
          ),
        ],
      ),

      // ─── Burn ─────────────────────────────────────────────────
      FirstAidTopic(
        id: 'burn',
        title: 'แผลไฟไหม้/น้ำร้อนลวก',
        titleEn: 'Burns & Scalds',
        subtitle: 'การปฐมพยาบาลแผลความร้อน',
        subtitleEn: 'Thermal Injury First Aid',
        icon: '🔥',
        color: '0xFFEF6C00',
        warning:
            'ห้ามเจาะตุ่มพอง ห้ามทายาสีฟัน น้ำปลา หรือยาหม่อง เพราะอาจทำให้ติดเชื้อรุนแรง',
        warningEn: 'Do not pop blisters or apply toothpaste, fish sauce, or balm.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ลดความร้อนทันที',
            titleEn: 'Cool Immediately',
            description:
                'ล้างบริเวณที่ถูกลวกด้วยน้ำสะอาดอุณหภูมิห้องไหลผ่านนานอย่างน้อย 10-20 นาที จนกว่าความปวดแสบปวดร้อนจะทุเลาลง ห้ามใช้น้ำแข็งหรือน้ำเย็นจัดราดโดยตรงเพราะจะทำให้เนื้อเยื่อตายเพิ่ม',
            descriptionEn:
                'Cool burn under cool running tap water for 10-20 minutes. Do not use ice directly.',
            imageAsset: 'assets/images/first_aid/burn_cooling.jpg',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ถอดสิ่งของรัดแน่น',
            titleEn: 'Remove Constrictions',
            description:
                'รีบถอดแหวน นาฬิกา หรือเสื้อผ้าที่รัดแน่นออกจากบริเวณที่โดนลวกก่อนที่จะมีอาการบวมพอง หากเสื้อผ้าติดหนึบกับแผล ห้ามกระชากออก ให้ตัดผ้าส่วนรอบๆ แทน',
            descriptionEn:
                'Remove tight items like rings or watches before swelling occurs.',
            visualType: 'remove_tight',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'การปิดแผล',
            titleEn: 'Cover Burn',
            description:
                'ใช้ผ้าสะอาดหรือพลาสติกใสห่ออาหาร (Wrap) ปิดแผลไว้หลวมๆ เพื่อป้องกันฝุ่นละอองและการระเหยของน้ำเนื้อเยื่อ แล้วรีบไปพบแพทย์หากแผลมีขนาดใหญ่หรือเกิดขึ้นที่ใบหน้า ข้อพับ หรืออวัยวะสืบพันธุ์',
            descriptionEn:
                'Cover loosely with clean cloth or sterile wrap and seek medical care.',
            visualType: 'cover_burn',
          ),
        ],
      ),

      // ─── Fracture ─────────────────────────────────────────────
      FirstAidTopic(
        id: 'fracture',
        title: 'กระดูกหัก',
        titleEn: 'Bone Fractures',
        subtitle: 'การดามกระดูกเบื้องต้น',
        subtitleEn: 'Basic Bone Splinting',
        icon: '🦴',
        color: '0xFF5D4037',
        warning:
            'ห้ามพยายามนวด ดึง หรือดัดกระดูกให้เข้าที่เอง เพราะอาจทำลายเส้นประสาทและหลอดเลือด',
        warningEn: 'Do not try to straighten or reset broken bones manually.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ประเมินและประคอง',
            titleEn: 'Immobilize',
            description:
                'ให้ผู้ป่วยอยู่นิ่งที่สุด ประคองอวัยวะที่บาดเจ็บให้อยู่ในท่าที่ผู้ป่วยเจ็บน้อยที่สุด หากมีแผลเลือดออกให้ห้ามเลือดก่อนด้วยการกดเบาๆ',
            descriptionEn:
                'Keep patient still and support injured limb in most comfortable position.',
            visualType: 'immobilize',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'การดาม (Splinting)',
            titleEn: 'Apply Splint',
            description:
                'ใช้วัสดุที่มีความแข็งและยาวพอ (เช่น หนังสือหนา, แผ่นไม้, ร่ม) มาวางขนาบข้างส่วนที่หัก โดยให้ความยาวครอบคลุมถึงข้อต่อด้านบนและด้านล่างของจุดที่หัก แล้วใช้ผ้าพันยึดวัสดุดามให้แน่นพอประมาณ',
            descriptionEn:
                'Use rigid material to splint joints above and below fracture site.',
            visualType: 'splinting',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'ลดอาการบวม',
            titleEn: 'Reduce Swelling',
            description:
                'หากสามารถทำได้ ให้ประคบเย็นเหนือบริเวณที่ปวดเพื่อลดอาการบวมและบรรเทาความเจ็บปวดระหว่างรอการเคลื่อนย้ายไปโรงพยาบาล',
            descriptionEn:
                'Apply cold pack wrapped in cloth to reduce pain and swelling.',
            visualType: 'cold_pack',
          ),
        ],
      ),

      // ─── Drowning ─────────────────────────────────────────────
      FirstAidTopic(
        id: 'drowning',
        title: 'จมน้ำ',
        titleEn: 'Drowning Rescue',
        subtitle: 'การช่วยเหลือคนจมน้ำ',
        subtitleEn: 'Water Rescue First Aid',
        icon: '🌊',
        color: '0xFF1976D2',
        warning:
            'ห้ามอุ้มพาดบ่าเพื่อเอาน้ำออก เพราะจะทำให้เสียเวลาและอาจทำให้อาเจียน',
        warningEn: 'Do not carry patient over shoulder to drain water.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ช่วยขึ้นจากน้ำ',
            titleEn: 'Water Rescue',
            description:
                'โยนอุปกรณ์ช่วยลอยตัวให้ผู้ประสบภัย หรือยื่นไม้ยาวให้จับ (ตะโกน โยน ยื่น) ห้ามกระโดดลงน้ำไปช่วยหากไม่ได้รับการฝึก',
            descriptionEn:
                'Reach or throw flotation gear. Do not jump in unless trained.',
            visualType: 'rescue_gear',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ตรวจการหายใจ',
            titleEn: 'Check Breathing',
            description:
                'วางผู้ป่วยบนพื้นราบ แข็ง และแห้ง ตรวจดูว่ายังหายใจหรือไม่ โดยการมองหน้าอกกระเพื่อม ฟังเสียงลมหายใจ และสังเกตอุณหภูมิลมที่แก้ม',
            descriptionEn:
                'Place patient on firm surface and check for normal breathing.',
            visualType: 'check_breathing',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'หากไม่หายใจ — ทำ CPR',
            titleEn: 'Perform CPR',
            description:
                'เริ่มทำ CPR ทันทีด้วยการกดหน้าอก 30 ครั้ง สลับกับเป่าลมหายใจ 2 ครั้ง พร้อมโทร 1669 ทันที',
            descriptionEn:
                'If not breathing, start CPR immediately (30 compressions : 2 breaths) and call 1669.',
            imageAsset: 'assets/images/first_aid/cpr_compression.jpg',
          ),
        ],
      ),

      // ─── Snake Bite ───────────────────────────────────────────
      FirstAidTopic(
        id: 'snake',
        title: 'งูกัด',
        titleEn: 'Snake Bite',
        subtitle: 'ปฐมพยาบาลเมื่อถูกงูกัด',
        subtitleEn: 'Snake Bite First Aid',
        icon: '🐍',
        color: '0xFF388E3C',
        warning: 'ห้ามดูดพิษ ห้ามกรีดแผล ห้ามขันชะเนาะ',
        warningEn: 'Do not suck venom, cut wound, or apply tourniquet.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ล้างแผล',
            titleEn: 'Wash Wound',
            description:
                'ล้างแผลด้วยน้ำสะอาดและสบู่เบาๆ นานอย่างน้อย 15 นาที เพื่อชะล้างพิษออก อย่าบีบหรือกดแผล',
            descriptionEn:
                'Wash gently with clean water and soap for 15 minutes.',
            visualType: 'clean_water',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ดามอวัยวะให้นิ่ง',
            titleEn: 'Immobilize Limb',
            description:
                'ดามส่วนที่ถูกกัดด้วยเฝือกชั่วคราวให้อยู่นิ่งที่สุด และให้อยู่ต่ำกว่าระดับหัวใจเพื่อชะลอการแพร่กระจายของพิษ',
            descriptionEn:
                'Keep limb still with temporary splint below heart level.',
            visualType: 'immobilize',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'นำส่งโรงพยาบาลทันที',
            titleEn: 'Go to Hospital',
            description:
                'รีบนำส่งโรงพยาบาลทันที หากจำลักษณะงูได้หรือถ่ายรูปไว้จะช่วยให้แพทย์เลือกเซรุ่มแก้พิษได้ถูกต้อง',
            descriptionEn:
                'Transport to hospital immediately. Take photo of snake if safe.',
            visualType: 'hospital_go',
          ),
        ],
      ),

      // ─── Fainting / Shock ─────────────────────────────────────
      FirstAidTopic(
        id: 'shock',
        title: 'เป็นลม/ช็อก',
        titleEn: 'Fainting & Shock',
        subtitle: 'การปฐมพยาบาลผู้ป่วยเป็นลม',
        subtitleEn: 'Fainting First Aid',
        icon: '😵',
        color: '0xFF7B1FA2',
        warning: 'หากไม่รู้สึกตัวห้ามให้ดื่มน้ำเด็ดขาด',
        warningEn: 'Do not give fluids if patient is unconscious.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'จัดท่าทาง',
            titleEn: 'Position Patient',
            description:
                'ให้ผู้ป่วยนอนราบ ยกปลายเท้าสูงขึ้นเล็กน้อย (ประมาณ 30 ซม.) เพื่อให้เลือดเลี้ยงสมองได้ดีขึ้น',
            descriptionEn:
                'Lay flat and elevate legs 30 cm to increase blood flow to brain.',
            visualType: 'legs_elevated',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'คลายเสื้อผ้า',
            titleEn: 'Loosen Clothing',
            description:
                'ปลดกระดุมหรือคลายเสื้อผ้าให้หลวม เพื่อให้หายใจสะดวก และคลายเข็มขัดออก',
            descriptionEn:
                'Unbutton collar and loosen belt for easy breathing.',
            visualType: 'loosen_clothing',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'ให้อากาศถ่ายเท',
            titleEn: 'Provide Fresh Air',
            description:
                'พัดวีให้มีลมโกรก อย่าให้คนมุง และห้ามให้ดื่มน้ำหากยังไม่รู้สึกตัวเต็มที่',
            descriptionEn:
                'Fan fresh air and keep crowd away. Do not give water if unalert.',
            visualType: 'fresh_air',
          ),
        ],
      ),

      // ─── Heat Stroke ──────────────────────────────────────────
      FirstAidTopic(
        id: 'heatstroke',
        title: 'ฮีทสโตรก (โรคลมแดด)',
        titleEn: 'Heat Stroke',
        subtitle: 'การช่วยเหลือผู้ป่วยภาวะตัวร้อนจัด',
        subtitleEn: 'Severe Overheating Rescue',
        icon: '☀️',
        color: '0xFFFF5722',
        warning:
            'เป็นภาวะฉุกเฉินที่เป็นอันตรายถึงชีวิต ต้องรีบลดอุณหภูมิกายโดยด่วน',
        warningEn: 'Life-threatening emergency. Cool body rapidly.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'นำเข้าที่ร่ม',
            titleEn: 'Move to Shade',
            description:
                'ย้ายผู้ป่วยไปยังที่ร่มที่มีอากาศถ่ายเทสะดวกหรือห้องแอร์ทันที',
            descriptionEn:
                'Move patient immediately to shaded or air-conditioned area.',
            visualType: 'shade',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ลดอุณหภูมิ',
            titleEn: 'Cool Down Body',
            description:
                'ถอดเสื้อผ้าที่ไม่จำเป็นออก ใช้ผ้าชุบน้ำเย็นเช็ดตามตัว ซอกคอ รักแร้ และขาหนีบ หรือใช้พัดลมเป่า',
            descriptionEn:
                'Remove excess clothing and wipe body with cool damp towels.',
            visualType: 'cool_towel',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'วางน้ำแข็งที่จุดสำคัญ',
            titleEn: 'Ice Packs',
            description:
                'หากมีน้ำแข็ง ให้ห่อผ้าแล้ววางตามซอกคอ รักแร้ และขาหนีบ เพื่อระบายความร้อนได้เร็วขึ้น และรีบโทร 1669',
            descriptionEn:
                'Place ice packs at neck, armpits, and groin. Call 1669.',
            visualType: 'ice_pack',
          ),
        ],
      ),

      // ─── Electrocution ────────────────────────────────────────
      FirstAidTopic(
        id: 'electrocution',
        title: 'ไฟดูด/ไฟฟ้าช็อต',
        titleEn: 'Electric Shock',
        subtitle: 'การช่วยเหลือเบื้องต้นอย่างปลอดภัย',
        subtitleEn: 'Safe Electrical First Aid',
        icon: '⚡',
        color: '0xFFFFEB3B',
        warning: 'อย่าสัมผัสตัวผู้ถูกไฟดูดโดยตรงจนกว่าจะตัดกระแสไฟแล้ว',
        warningEn: 'Do not touch victim until power is disconnected.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ตัดวงจรไฟฟ้า',
            titleEn: 'Disconnect Power',
            description:
                'รีบสับคัตเอาท์หรือดึงปลั๊กออกทันที หรือใช้วัสดุที่ไม่เป็นสื่อไฟฟ้า (เช่น ไม้แห้ง ผ้าแห้ง) เขี่ยสายไฟออกจากตัวผู้ป่วย',
            descriptionEn:
                'Turn off main switch or push wire away using dry non-conductive object.',
            visualType: 'cut_power',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ตรวจการหายใจ',
            titleEn: 'Check Breathing',
            description:
                'เมื่อปลอดภัยแล้ว ให้ตรวจการหายใจ หากหยุดหายใจให้เริ่ม CPR ทันที',
            descriptionEn:
                'Check breathing once safe. Start CPR if breathing stops.',
            imageAsset: 'assets/images/first_aid/cpr_compression.jpg',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'ดูแลบาดแผล',
            titleEn: 'Care for Burns',
            description:
                'หากยังมีสติ ให้ผู้ป่วยนอนราบ ปิดแผลไฟไหม้ด้วยผ้าสะอาด และนำส่งโรงพยาบาลทันที',
            descriptionEn:
                'Cover electrical burns with clean cloth and seek emergency care.',
            visualType: 'burn_care',
          ),
        ],
      ),

      // ─── Poisoning ────────────────────────────────────────────
      FirstAidTopic(
        id: 'poisoning',
        title: 'ได้รับสารพิษ',
        titleEn: 'Poisoning',
        subtitle: 'การปฐมพยาบาลเมื่อรับสารเคมีหรือยาเกินขนาด',
        subtitleEn: 'Chemical Exposure & Overdose',
        icon: '🧪',
        color: '0xFF9C27B0',
        warning:
            'ห้ามทำให้ผู้ป่วยอาเจียนเด็ดขาด หากสารนั้นเป็นกรดหรือด่างรุนแรง',
        warningEn: 'Do not induce vomiting if corrosive chemicals were swallowed.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ระบุสารพิษ',
            titleEn: 'Identify Poison',
            description:
                'รีบตรวจสอบว่าผู้ป่วยได้รับสารใด ปริมาณเท่าใด และเวลาใด (เก็บตัวอย่างหรือขวดสารพิษไปด้วย)',
            descriptionEn:
                'Identify substance, amount, and time of ingestion.',
            visualType: 'chemical_id',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ล้างสารพิษ (ทางผิวหนัง)',
            titleEn: 'Flush Skin',
            description:
                'หากถูกผิวหนัง ให้ล้างด้วยน้ำสะอาดไหลผ่านนานๆ อย่างน้อย 15 นาที',
            descriptionEn:
                'Flush affected skin with running water for 15 minutes.',
            imageAsset: 'assets/images/first_aid/bleeding_pressure.jpg',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'สังเกตอาการ',
            titleEn: 'Monitor Patient',
            description:
                'หากหมดสติ ให้จัดท่าตะแคงข้างเพื่อป้องกันการสำลัก และรีบนำส่งโรงพยาบาลหรือโทร 1669',
            descriptionEn:
                'Place in recovery position if unconscious and call 1669.',
            visualType: 'tilt_recovery',
          ),
        ],
      ),

      // ─── Allergic Reaction ────────────────────────────────────
      FirstAidTopic(
        id: 'allergic',
        title: 'แพ้อย่างรุนแรง',
        titleEn: 'Severe Allergic Reaction',
        subtitle: 'Anaphylaxis การแพ้อาหารหรือแมลงกัดต่อย',
        subtitleEn: 'Anaphylaxis First Aid',
        icon: '🐝',
        color: '0xFFF44336',
        warning:
            'อาการแพ้รุนแรงอาจทำให้ทางเดินหายใจบวมอุดตันได้ภายในไม่กี่นาที',
        warningEn: 'Severe allergy can cause airway obstruction within minutes.',
        steps: [
          FirstAidStep(
            stepNumber: 1,
            title: 'ประเมินอาการ',
            titleEn: 'Assess Symptoms',
            description:
                'สังเกตอาการผื่นลมพิษ ปากบวม หายใจลำบาก หรือเวียนศีรษะหน้ามืด',
            descriptionEn:
                'Look for hives, swelling, difficulty breathing, or dizziness.',
            visualType: 'bee_sting',
          ),
          FirstAidStep(
            stepNumber: 2,
            title: 'ใช้ยาฉีด (ถ้ามี)',
            titleEn: 'Use EpiPen',
            description:
                'หากผู้ป่วยมีปากกาฉีดยา EpiPen ให้ช่วยฉีดเข้าที่กล้ามเนื้อต้นขาด้านนอกทันที',
            descriptionEn:
                'Administer EpiPen into outer thigh muscle immediately if available.',
            visualType: 'epipen',
          ),
          FirstAidStep(
            stepNumber: 3,
            title: 'จัดท่าจัดทาง',
            titleEn: 'Position & Call 1669',
            description:
                'ให้ผู้ป่วยนอนราบยกเท้าสูง หากหายใจลำบากให้นั่งตัวตรง และรีบไปโรงพยาบาลทันที',
            descriptionEn:
                'Lay flat with legs raised, or sit up if breathing is difficult.',
            visualType: 'legs_elevated',
          ),
        ],
      ),
    ];
  }
}
