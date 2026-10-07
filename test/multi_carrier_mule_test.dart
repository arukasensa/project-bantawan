import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/features/chat/models/mule_envelope.dart';

void main() {
  group('Multi-Carrier Mule & Opportunistic DTN Relay Tests', () {
    test('MuleEnvelope handles maxHops, canRelay, and incrementHop correctly', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 48));

      final envelope = MuleEnvelope(
        envelopeId: 'env_multi_101',
        senderNodeId: 'node_alice',
        senderCallsign: 'Alice',
        recipientNodeId: 'node_dave',
        encryptedPayload: 'CIPHERTEXT_123',
        payloadIv: '',
        payloadAuthTag: '',
        senderSignature: 'SIG_123',
        isUrgentSOS: true,
        createdAt: now,
        expiresAt: expiry,
        hopCarryCount: 0,
        maxHops: 2,
        status: 'CARRIED',
      );

      // เริ่มต้น hop = 0, maxHops = 2 -> canRelay ต้องเป็น true
      expect(envelope.hopCarryCount, 0);
      expect(envelope.maxHops, 2);
      expect(envelope.canRelay, isTrue);

      // ส่งต่อทอดที่ 1 (Hop 1)
      final hop1 = envelope.incrementHop();
      expect(hop1.envelopeId, 'env_multi_101');
      expect(hop1.hopCarryCount, 1);
      expect(hop1.canRelay, isTrue);

      // ส่งต่อทอดที่ 2 (Hop 2) -> ถึงเพดาน maxHops = 2
      final hop2 = hop1.incrementHop();
      expect(hop2.hopCarryCount, 2);
      expect(hop2.canRelay, isFalse); // ห้ามส่งต่ออีก ป้องกันน้ำท่วมเครือข่าย
    });

    test('MuleEnvelope Map and JSON serialization preserves maxHops and hopCarryCount', () {
      final envelope = MuleEnvelope(
        envelopeId: 'env_k_replication_99',
        senderNodeId: 'node_sender',
        senderCallsign: 'Rescue_HQ',
        recipientNodeId: 'node_shelter',
        encryptedPayload: 'ENCRYPTED_COORDINATES',
        payloadIv: 'iv_val',
        payloadAuthTag: 'tag_val',
        senderSignature: 'sig_val',
        isUrgentSOS: true,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        hopCarryCount: 1,
        maxHops: 3,
      );

      // Map serialization (SQLite)
      final map = envelope.toMap();
      expect(map['maxHops'], 3);
      expect(map['hopCarryCount'], 1);

      final fromMap = MuleEnvelope.fromMap(map);
      expect(fromMap.maxHops, 3);
      expect(fromMap.hopCarryCount, 1);
      expect(fromMap.canRelay, isTrue);

      // JSON serialization (Nearby BYTES network payload)
      final json = envelope.toJson();
      expect(json['maxHops'], 3);
      expect(json['hopCarryCount'], 1);

      final fromJson = MuleEnvelope.fromJson(json);
      expect(fromJson.maxHops, 3);
      expect(fromJson.hopCarryCount, 1);
    });

    test('MULE_RELAY packet format and incremented hop payload', () {
      final envelope = MuleEnvelope(
        envelopeId: 'env_relay_packet',
        senderNodeId: 'node_alice',
        senderCallsign: 'Alice',
        recipientNodeId: 'node_bob',
        encryptedPayload: 'SECRET_PAYLOAD',
        payloadIv: '',
        payloadAuthTag: '',
        senderSignature: 'SIG',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
        hopCarryCount: 0,
        maxHops: 2,
      );

      final relayedEnv = envelope.incrementHop();
      final packet = {
        'isMuleEnvelope': true,
        'muleAction': 'MULE_RELAY',
        'envelope': relayedEnv.toJson(),
      };

      expect(packet['isMuleEnvelope'], isTrue);
      expect(packet['muleAction'], 'MULE_RELAY');
      final envData = packet['envelope'] as Map<String, dynamic>;
      expect(envData['envelopeId'], 'env_relay_packet');
      expect(envData['hopCarryCount'], 1);
      expect(envData['maxHops'], 2);
    });

    test('DELIVERY_RECEIPT Anti-Packet Vaccine Purge packet structure', () {
      final receiptPacket = {
        'isMuleEnvelope': true,
        'muleAction': 'DELIVERY_RECEIPT',
        'envelopeId': 'env_target_delivered',
      };

      expect(receiptPacket['isMuleEnvelope'], isTrue);
      expect(receiptPacket['muleAction'], 'DELIVERY_RECEIPT');
      expect(receiptPacket['envelopeId'], 'env_target_delivered');
    });
  });
}
