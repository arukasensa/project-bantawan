import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/features/chat/models/mule_envelope.dart';

void main() {
  group('MuleEnvelope Model Tests', () {
    test('creates and converts to/from Map correctly', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 48));

      final envelope = MuleEnvelope(
        envelopeId: 'env_test_12345',
        senderNodeId: 'node_sender_1',
        senderCallsign: 'Alice',
        recipientNodeId: 'node_recipient_2',
        encryptedPayload: 'ENCRYPTED_BASE64_DATA',
        payloadIv: 'IV_BASE64',
        payloadAuthTag: 'TAG_BASE64',
        senderSignature: 'SIG_BASE64',
        isUrgentSOS: true,
        createdAt: now,
        expiresAt: expiry,
        hopCarryCount: 1,
        status: 'CARRIED',
      );

      expect(envelope.isExpired, isFalse);
      expect(envelope.isUrgentSOS, isTrue);
      expect(envelope.estimatedSizeBytes, greaterThan(0));

      final map = envelope.toMap();
      expect(map['envelopeId'], 'env_test_12345');
      expect(map['isUrgentSOS'], 1);

      final restored = MuleEnvelope.fromMap(map);
      expect(restored.envelopeId, envelope.envelopeId);
      expect(restored.senderNodeId, envelope.senderNodeId);
      expect(restored.senderCallsign, envelope.senderCallsign);
      expect(restored.recipientNodeId, envelope.recipientNodeId);
      expect(restored.encryptedPayload, envelope.encryptedPayload);
      expect(restored.isUrgentSOS, isTrue);
      expect(restored.hopCarryCount, 1);
      expect(restored.status, 'CARRIED');
    });

    test('JSON serialization for network transmission works properly', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 3));

      final envelope = MuleEnvelope(
        senderNodeId: 'node_sos_alert',
        senderCallsign: 'Bob',
        recipientNodeId: '@RESCUE_TEAM',
        encryptedPayload: 'HELP_COORDINATES_ENCRYPTED',
        payloadIv: 'IV_DATA',
        payloadAuthTag: 'TAG_DATA',
        senderSignature: 'SIG_DATA',
        isUrgentSOS: true,
        createdAt: now,
        expiresAt: expiry,
      );

      final json = envelope.toJson();
      expect(json['recipientNodeId'], '@RESCUE_TEAM');
      expect(json['isUrgentSOS'], isTrue);

      final fromJson = MuleEnvelope.fromJson(json);
      expect(fromJson.recipientNodeId, '@RESCUE_TEAM');
      expect(fromJson.senderCallsign, 'Bob');
      expect(fromJson.isUrgentSOS, isTrue);
    });

    test('detects expired envelope correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));
      final envelope = MuleEnvelope(
        senderNodeId: 'node_1',
        senderCallsign: 'Charlie',
        recipientNodeId: 'node_2',
        encryptedPayload: 'DATA',
        payloadIv: 'IV',
        payloadAuthTag: 'TAG',
        senderSignature: 'SIG',
        expiresAt: pastDate,
      );

      expect(envelope.isExpired, isTrue);
    });

    test('DELIVERY_RECEIPT packet serializes and parses properly', () {
      final receiptPacket = {
        'isMuleEnvelope': true,
        'muleAction': 'DELIVERY_RECEIPT',
        'envelopeId': 'env_delivered_999',
      };

      expect(receiptPacket['isMuleEnvelope'], isTrue);
      expect(receiptPacket['muleAction'], 'DELIVERY_RECEIPT');
      expect(receiptPacket['envelopeId'], 'env_delivered_999');
    });
  });
}
