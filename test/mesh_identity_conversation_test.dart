import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter1/features/chat/models/mesh_peer.dart';
import 'package:flutter1/features/chat/services/chat_database_helper.dart';
import 'package:flutter1/features/chat/services/crypto_mesh_service.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Persistent Node ID & Identity Tests', () {
    test('nodeId stays consistent and is generated properly', () async {
      await CryptoMeshService.initKeys();
      final nodeId1 = CryptoMeshService.nodeId;
      expect(nodeId1, isNotEmpty);
      expect(nodeId1.startsWith('node_'), isTrue);

      // Re-running initKeys should maintain identical nodeId
      await CryptoMeshService.initKeys();
      final nodeId2 = CryptoMeshService.nodeId;
      expect(nodeId2, equals(nodeId1));
    });

    test('MeshPeer updates display name without creating duplicate peer', () {
      final peersMap = <String, MeshPeer>{};
      const peerNodeId = 'node_target_9999';

      // First announcement: "Survivor_1234"
      final firstPeer = MeshPeer(
        peerId: peerNodeId,
        peerName: 'Survivor_1234',
        publicKeyHex: 'aabbccdd',
        hopCount: 1,
      );
      peersMap[firstPeer.peerId] = firstPeer;

      expect(peersMap.length, equals(1));
      expect(peersMap[peerNodeId]?.peerName, equals('Survivor_1234'));

      // Second announcement: User changes name to "Rescue_Leader"
      final updatedPeer = MeshPeer(
        peerId: peerNodeId,
        peerName: 'Rescue_Leader',
        publicKeyHex: 'aabbccdd',
        hopCount: 1,
      );
      peersMap[updatedPeer.peerId] = updatedPeer;

      // Must remain exactly 1 entry with updated name
      expect(peersMap.length, equals(1));
      expect(peersMap[peerNodeId]?.peerName, equals('Rescue_Leader'));
    });

    test('ChatDatabaseHelper.getConversationId maintains room despite name changes', () {
      const myNodeId = 'node_my_device_1111';
      const peerNodeId = 'node_peer_device_2222';

      final msg1 = NearbyMessage(
        id: 'msg_001',
        senderId: myNodeId,
        senderName: 'Survivor_Old',
        recipientId: peerNodeId,
        recipientName: 'Friend_Old',
        content: 'Hello friend!',
        timestamp: DateTime.now(),
      );

      final convId1 = ChatDatabaseHelper.getConversationId(
        msg1,
        myNodeId: myNodeId,
      );
      expect(convId1, equals('PEER_$peerNodeId'));

      // Friend changes name to "Friend_NewName"
      final msg2 = NearbyMessage(
        id: 'msg_002',
        senderId: peerNodeId,
        senderName: 'Friend_NewName',
        recipientId: myNodeId,
        recipientName: 'Survivor_Old',
        content: 'Hi! I changed my callsign.',
        timestamp: DateTime.now(),
      );

      final convId2 = ChatDatabaseHelper.getConversationId(
        msg2,
        myNodeId: myNodeId,
      );

      // Both messages must route to the identical conversation room!
      expect(convId2, equals(convId1));
      expect(convId2, equals('PEER_$peerNodeId'));
    });

    test('Fail-closed security: encrypt throws without registered public key (no fallback guessing)', () async {
      await CryptoMeshService.initKeys();
      // Trying to encrypt for an unregistered peer must throw fail-closed exception
      expect(
        () => CryptoMeshService.encryptPayload(
          plainText: 'Secret Message',
          recipientId: 'node_unregistered_peer',
          senderId: CryptoMeshService.nodeId,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Fail-closed security: rejects legacy insecure ENC packets', () {
      final legacyResult = CryptoMeshService.decryptPayload(
        cipherText: 'ENC_V2::insecure_xor_data',
        recipientId: 'node_test',
        senderId: 'node_peer',
      );
      expect(legacyResult.contains('รูปแบบการเข้ารหัสรุ่นเก่าที่ไม่ปลอดภัย'), isTrue);
    });
  });
}
