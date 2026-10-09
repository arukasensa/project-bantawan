import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/features/first_aid/services/first_aid_service.dart';

void main() {
  group('FirstAidService & FirstAidTopic Clinical Enhancement Tests', () {
    test('getTopics returns all 12 complete first aid emergency categories', () {
      final topics = FirstAidService.getTopics();
      expect(topics.length, equals(12));

      final topicIds = topics.map((t) => t.id).toSet();
      expect(topicIds, containsAll([
        'cpr',
        'choking',
        'bleeding',
        'burn',
        'fracture',
        'drowning',
        'snake',
        'shock',
        'heatstroke',
        'electrocution',
        'poisoning',
        'allergic',
      ]));
    });

    test('All 12 topics have ultra-HD 3D badge icons configured', () {
      final topics = FirstAidService.getTopics();
      for (final topic in topics) {
        expect(topic.iconAsset, isNotNull, reason: 'Topic ${topic.id} missing iconAsset');
        expect(
          topic.iconAsset!.startsWith('assets/images/first_aid/icon_'),
          isTrue,
          reason: 'Topic ${topic.id} invalid iconAsset path: ${topic.iconAsset}',
        );
      }
    });

    test('All 12 topics contain comprehensive clinical protocol data and DOs & DONTs', () {
      final topics = FirstAidService.getTopics();
      for (final topic in topics) {
        expect(topic.urgency, isNotNull, reason: 'Topic ${topic.id} missing urgency');
        expect(topic.urgencyEn, isNotNull, reason: 'Topic ${topic.id} missing urgencyEn');
        expect(topic.keyMetric, isNotNull, reason: 'Topic ${topic.id} missing keyMetric');
        expect(topic.keyMetricEn, isNotNull, reason: 'Topic ${topic.id} missing keyMetricEn');
        expect(topic.quickTip, isNotNull, reason: 'Topic ${topic.id} missing quickTip');
        expect(topic.quickTipEn, isNotNull, reason: 'Topic ${topic.id} missing quickTipEn');

        // DOs & DONTs
        expect(topic.dos, isNotNull, reason: 'Topic ${topic.id} missing dos');
        expect(topic.dos!.isNotEmpty, isTrue, reason: 'Topic ${topic.id} empty dos');
        expect(topic.dosEn, isNotNull, reason: 'Topic ${topic.id} missing dosEn');
        expect(topic.dosEn!.isNotEmpty, isTrue, reason: 'Topic ${topic.id} empty dosEn');

        expect(topic.donts, isNotNull, reason: 'Topic ${topic.id} missing donts');
        expect(topic.donts!.isNotEmpty, isTrue, reason: 'Topic ${topic.id} empty donts');
        expect(topic.dontsEn, isNotNull, reason: 'Topic ${topic.id} missing dontsEn');
        expect(topic.dontsEn!.isNotEmpty, isTrue, reason: 'Topic ${topic.id} empty dontsEn');
      }
    });

    test('Bilingual getters return appropriate language strings', () {
      final topics = FirstAidService.getTopics();
      final cpr = topics.firstWhere((t) => t.id == 'cpr');

      expect(cpr.getTitle(true), contains('CPR'));
      expect(cpr.getTitle(false), equals('CPR (Cardiopulmonary Resuscitation)'));

      expect(cpr.getUrgency(true), contains('วิกฤต'));
      expect(cpr.getUrgency(false), contains('Cardiac Arrest'));

      expect(cpr.getKeyMetric(true), contains('100-120'));
      expect(cpr.getKeyMetric(false), contains('100-120 BPM'));

      expect(cpr.getDos(true).first, contains('ส้นมือ'));
      expect(cpr.getDos(false).first, contains('heel of hand'));

      expect(cpr.getDonts(true).first, contains('ห้าม'));
      expect(cpr.getDonts(false).first, contains('Do NOT'));

      expect(cpr.getQuickTip(true), contains('Staying Alive'));
      expect(cpr.getQuickTip(false), contains('Staying Alive'));
    });

    test('Fracture step 2 includes realistic fracture splint illustration', () {
      final topics = FirstAidService.getTopics();
      final fracture = topics.firstWhere((t) => t.id == 'fracture');
      final splintStep = fracture.steps.firstWhere((s) => s.stepNumber == 2);

      expect(splintStep.imageAsset, equals('assets/images/first_aid/fracture_splint.jpg'));
    });
  });
}
