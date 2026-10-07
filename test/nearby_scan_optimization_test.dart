import 'package:flutter_test/flutter_test.dart';
import 'package:flutter1/features/chat/models/mesh_peer.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';

void main() {
  group('Nearby BLE Scan & Connection Optimization Tests', () {
    test('parseAdvertisedName parses BW prefixed endpoint name correctly', () {
      const raw = 'BW:a1b2c3d4e5f6:Survivor Alpha';
      final parsed = NearbyService.parseAdvertisedName(raw);

      expect(parsed.peerNodeId, equals('node_a1b2c3d4e5f6'));
      expect(parsed.peerName, equals('Survivor Alpha'));
    });

    test('parseAdvertisedName handles callsigns with colons gracefully', () {
      const raw = 'BW:a1b2c3d4e5f6:Tactical:Unit:01';
      final parsed = NearbyService.parseAdvertisedName(raw);

      expect(parsed.peerNodeId, equals('node_a1b2c3d4e5f6'));
      expect(parsed.peerName, equals('Tactical:Unit:01'));
    });

    test('parseAdvertisedName maintains backward compatibility with legacy raw names', () {
      const raw = 'Survivor Phoenix';
      final parsed = NearbyService.parseAdvertisedName(raw);

      expect(parsed.peerNodeId, isNull);
      expect(parsed.peerName, equals('Survivor Phoenix'));
    });

    test('parseAdvertisedName strips node_ prefix if redundantly passed', () {
      const raw = 'BW:node_fedcba987654:Rescue Medic';
      final parsed = NearbyService.parseAdvertisedName(raw);

      expect(parsed.peerNodeId, equals('node_fedcba987654'));
      expect(parsed.peerName, equals('Rescue Medic'));
    });

    test('Deterministic Master/Responder tie-breaker works symmetrically', () {
      const nodeA = 'node_111111111111';
      const nodeB = 'node_222222222222';

      // Node B is lexicographically greater than Node A
      final isBMaster = nodeB.compareTo(nodeA) > 0;
      final isAMaster = nodeA.compareTo(nodeB) > 0;

      expect(isBMaster, isTrue, reason: 'Node B should be Master (Initiator)');
      expect(isAMaster, isFalse, reason: 'Node A should be Responder (Listener)');
      expect(isBMaster != isAMaster, isTrue, reason: 'Master and Responder must never collide');
    });

    test('Advertised name length stays safely within BLE payload limits (< 131 bytes)', () {
      final service = NearbyService();
      final name = service.advertisedName;

      // Nearby Connections endpoint name limit is 131 bytes
      expect(name.length, lessThanOrEqualTo(131));
      expect(name.startsWith('BW:'), isTrue);
    });

    test('isPeerAlreadyConnectedOrPending detects duplicate endpoints and names', () {
      final service = NearbyService();
      service.connectedDevices.clear();
      service.connectedDevices['ep_123'] = 'Survivor Bravo';

      // Duplicate by endpoint ID
      expect(
        service.isPeerAlreadyConnectedOrPending(
          endpointId: 'ep_123',
          peerDisplayName: 'Survivor Charlie',
        ),
        isTrue,
        reason: 'Should prevent connection if endpoint ID is already connected',
      );

      // Duplicate by display name
      expect(
        service.isPeerAlreadyConnectedOrPending(
          endpointId: 'ep_999',
          peerDisplayName: 'Survivor Bravo',
        ),
        isTrue,
        reason: 'Should prevent connection if peer display name is already connected',
      );

      // Brand new peer
      expect(
        service.isPeerAlreadyConnectedOrPending(
          endpointId: 'ep_new',
          peerDisplayName: 'Survivor Delta',
        ),
        isFalse,
        reason: 'Should allow connection for unvisited peer',
      );
    });

    test('isPeerAlreadyConnectedOrPending detects duplicate by discoveredMeshPeers direct link', () {
      final service = NearbyService();
      service.connectedDevices.clear();
      service.discoveredMeshPeers.clear();

      service.connectedDevices['ep_456'] = 'Survivor Echo';
      service.discoveredMeshPeers['node_echo'] = MeshPeer(
        peerId: 'node_echo',
        peerName: 'Survivor Echo',
        publicKeyHex: '0123456789abcdef',
        hopCount: 1,
        directEndpoint: 'ep_456',
        lastSeen: DateTime.now(),
      );

      // Even if scanned with a new endpoint ID, detects active direct connection via peerNodeId
      expect(
        service.isPeerAlreadyConnectedOrPending(
          peerNodeId: 'node_echo',
          endpointId: 'ep_different',
          peerDisplayName: 'Survivor Echo Rotated',
        ),
        isTrue,
        reason: 'Should block duplicate connection when node ID is already connected on another endpoint',
      );
    });

    test('getPeerConnectionStatus detects ghost nodes when silent > 15 seconds', () {
      final service = NearbyService();
      service.connectedDevices.clear();
      service.connectedDevices['ep_test'] = 'Peer Test';

      // Active peer (5s ago)
      final activePeer = MeshPeer(
        peerId: 'peer_active',
        peerName: 'Peer Active',
        publicKeyHex: '0123456789abcdef',
        hopCount: 1,
        directEndpoint: 'ep_test',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      expect(
        service.getPeerConnectionStatus(activePeer),
        equals(PeerConnectionStatus.direct),
      );

      // Stale peer (20s ago - Ghost Node)
      final ghostPeer = MeshPeer(
        peerId: 'peer_ghost',
        peerName: 'Peer Ghost',
        publicKeyHex: '0123456789abcdef',
        hopCount: 1,
        directEndpoint: 'ep_test',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 20)),
      );
      expect(
        service.getPeerConnectionStatus(ghostPeer),
        equals(PeerConnectionStatus.offline),
        reason: 'Should mark direct peer offline after 15s of silence (Ghost Node prevention)',
      );
    });

    test('getPeerConnectionStatus marks all nodes offline when connectedDevices is empty', () {
      final service = NearbyService();
      service.connectedDevices.clear();

      final peer = MeshPeer(
        peerId: 'peer_test',
        peerName: 'Peer Test',
        publicKeyHex: '0123456789abcdef',
        hopCount: 1,
        directEndpoint: 'ep_test',
        lastSeen: DateTime.now(),
      );
      expect(
        service.getPeerConnectionStatus(peer),
        equals(PeerConnectionStatus.offline),
        reason: 'If device has 0 Bluetooth links, all peers must report offline',
      );
    });
  });
}
