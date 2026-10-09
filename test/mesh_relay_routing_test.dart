import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter1/features/chat/models/mesh_peer.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tactical Mesh Relay Engine Tests', () {
    test('isRelayBridgeActive returns true when node has 2 or more direct connections', () {
      final service = NearbyService();
      service.connectedDevices.clear();

      expect(service.isRelayBridgeActive, isFalse);

      service.connectedDevices['ep_a'] = 'Node A';
      expect(service.isRelayBridgeActive, isFalse);

      service.connectedDevices['ep_c'] = 'Node C';
      expect(service.isRelayBridgeActive, isTrue);
    });

    test('recordRelayedPacket updates counters and last relayed information', () {
      final service = NearbyService();
      final initialTotal = service.relayedPacketCount;
      final initialPub = service.relayedPublicCount;
      final initialPriv = service.relayedPrivateCount;

      service.recordRelayedPacket(
        isPrivate: false,
        info: 'Public broadcast relay test',
      );

      expect(service.relayedPacketCount, equals(initialTotal + 1));
      expect(service.relayedPublicCount, equals(initialPub + 1));
      expect(service.relayedPrivateCount, equals(initialPriv));
      expect(service.lastRelayedPacketInfo, equals('Public broadcast relay test'));
      expect(service.lastRelayedPacketTime, isNotNull);

      service.recordRelayedPacket(
        isPrivate: true,
        info: 'Private E2EE packet relay test',
      );

      expect(service.relayedPacketCount, equals(initialTotal + 2));
      expect(service.relayedPrivateCount, equals(initialPriv + 1));
      expect(service.lastRelayedPacketInfo, equals('Private E2EE packet relay test'));
    });

    test('MeshPeer 2-hop status resolution with direct bridge presence', () {
      final service = NearbyService();
      service.connectedDevices.clear();
      service.discoveredMeshPeers.clear();

      // Node B is directly connected to this node
      service.connectedDevices['ep_b'] = 'Node B';
      service.discoveredMeshPeers['node_b'] = MeshPeer(
        peerId: 'node_b',
        peerName: 'Node B',
        publicKeyHex: 'key_b',
        hopCount: 1,
        directEndpoint: 'ep_b',
      );

      // Node C is 2 hops away, reached through Node B
      final peerC = MeshPeer(
        peerId: 'node_c',
        peerName: 'Node C',
        publicKeyHex: 'key_c',
        hopCount: 2,
        directEndpoint: null,
      );
      service.discoveredMeshPeers['node_c'] = peerC;

      // When reverse path to C points to ep_b which is connected:
      service.setReversePathForTesting('node_c', 'ep_b');

      final statusC = service.getPeerConnectionStatus(peerC);
      expect(statusC, equals(PeerConnectionStatus.relayed));

      // If ep_b disconnects, peer C must become offline
      service.connectedDevices.remove('ep_b');
      final statusCOffline = service.getPeerConnectionStatus(peerC);
      expect(statusCOffline, equals(PeerConnectionStatus.offline));
    });
  });
}
