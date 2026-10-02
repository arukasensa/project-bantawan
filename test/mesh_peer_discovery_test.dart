import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter1/features/chat/models/mesh_peer.dart';
import 'package:flutter1/features/chat/services/crypto_mesh_service.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MeshPeer Model Tests', () {
    test('Should properly serialize and deserialize MeshPeer', () {
      final peer = MeshPeer(
        peerId: 'Node_C',
        peerName: 'Survivor C',
        publicKeyHex: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        hopCount: 2,
        directEndpoint: null,
      );

      final json = peer.toJson();
      final reconstructed = MeshPeer.fromJson(json);

      expect(reconstructed.peerId, equals('Node_C'));
      expect(reconstructed.peerName, equals('Survivor C'));
      expect(reconstructed.publicKeyHex, equals(peer.publicKeyHex));
      expect(reconstructed.hopCount, equals(2));
      expect(reconstructed.isDirect, isFalse);
      expect(reconstructed.isReachable, isTrue);
    });

    test('Direct peer should have isDirect true', () {
      final directPeer = MeshPeer(
        peerId: 'Node_B',
        peerName: 'Survivor B',
        publicKeyHex: '1234',
        hopCount: 1,
        directEndpoint: 'endpoint_b',
      );

      expect(directPeer.isDirect, isTrue);
    });

    test('Should handle emergency medical profile data and getters', () {
      final peerWithMedical = MeshPeer(
        peerId: 'Node_Medic',
        peerName: 'Dr. Somchai',
        publicKeyHex: '5678',
        hopCount: 2,
        emergencyProfile: {
          'bloodType': 'AB+',
          'allergies': 'Penicillin, Peanuts',
          'conditions': 'Hypertension',
          'hospitalPref': 'Songklanagarind Hospital',
          'organDonor': 'true',
        },
      );

      expect(peerWithMedical.bloodType, equals('AB+'));
      expect(peerWithMedical.allergies, equals('Penicillin, Peanuts'));
      expect(peerWithMedical.conditions, equals('Hypertension'));
      expect(peerWithMedical.hospitalPref, equals('Songklanagarind Hospital'));
      expect(peerWithMedical.isOrganDonor, isTrue);
      expect(peerWithMedical.hasMedicalData, isTrue);

      final json = peerWithMedical.toJson();
      final restored = MeshPeer.fromJson(json);

      expect(restored.bloodType, equals('AB+'));
      expect(restored.allergies, equals('Penicillin, Peanuts'));
      expect(restored.isOrganDonor, isTrue);
    });
  });

  group('E2EE with Mesh Discovered Public Keys', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CryptoMeshService.initKeys();
    });

    test('Should register peer public key and encrypt/decrypt multi-hop private message', () {
      // Node A's setup
      final myPubKey = CryptoMeshService.myPublicKeyHex;
      expect(myPubKey.length, equals(64));

      // Simulate Node C generating an announcement
      // Node C's simulated public key (64 hex characters = 32 bytes)
      final simulatedPeerId = 'node_${myPubKey.substring(0, 12)}';
      // Register a known peer's public key
      CryptoMeshService.registerPeerPublicKey(simulatedPeerId, myPubKey);

      expect(CryptoMeshService.hasPeerPublicKey(simulatedPeerId), isTrue);

      // Node A encrypts a message for Node C
      const secretMessage = 'Hello Node C, this is Node A via Multi-hop Mesh!';
      final encrypted = CryptoMeshService.encryptPayload(
        plainText: secretMessage,
        recipientId: simulatedPeerId,
        senderId: CryptoMeshService.nodeId,
      );

      expect(encrypted.startsWith('ENC_V4::'), isTrue);

      // Node C receives and decrypts
      final decrypted = CryptoMeshService.decryptPayload(
        cipherText: encrypted,
        recipientId: simulatedPeerId,
        senderId: CryptoMeshService.nodeId,
      );

      expect(decrypted, equals(secretMessage));
    });
  });

  group('NearbyMessage PEER_ANNOUNCE Tests', () {
    test('PEER_ANNOUNCE message serialization retains announce fields', () {
      final msg = NearbyMessage(
        senderId: 'Node_A',
        senderName: 'Survivor A',
        content: 'PEER_ANNOUNCE',
        timestamp: DateTime.now(),
        isPeerAnnounce: true,
        peerPublicKey: 'deadbeefcafe0123456789abcdef0123456789abcdef0123456789abcdef0123',
        hopCount: 1,
        ttl: 3,
      );

      final json = msg.toJson();
      final restored = NearbyMessage.fromJson(json);

      expect(restored.isPeerAnnounce, isTrue);
      expect(restored.peerPublicKey, equals(msg.peerPublicKey));
      expect(restored.hopCount, equals(1));
      expect(restored.ttl, equals(3));
    });
  });
}
