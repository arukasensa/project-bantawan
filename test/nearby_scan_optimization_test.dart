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

    test('getPeerConnectionStatus detects ghost nodes when silent > 22 seconds (3 missed 8s pings)', () {
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

      // In-grace peer (16s ago - 1 missed ping, still within 22s grace window)
      final inGracePeer = MeshPeer(
        peerId: 'peer_grace',
        peerName: 'Peer Grace',
        publicKeyHex: '0123456789abcdef',
        hopCount: 1,
        directEndpoint: 'ep_test',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 16)),
      );
      expect(
        service.getPeerConnectionStatus(inGracePeer),
        equals(PeerConnectionStatus.direct),
        reason: 'Should stay connected if only 1-2 pings are missed during radio scanning',
      );

      // Stale peer (26s ago - Ghost Node after 3 missed pings)
      final ghostPeer = MeshPeer(
        peerId: 'peer_ghost',
        peerName: 'Peer Ghost',
        publicKeyHex: '0123456789abcdef',
        hopCount: 1,
        directEndpoint: 'ep_test',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 26)),
      );
      expect(
        service.getPeerConnectionStatus(ghostPeer),
        equals(PeerConnectionStatus.offline),
        reason: 'Should mark direct peer offline after >22s of silence (Ghost Node prevention)',
      );
    });

    test('createPingPacket creates ultra-lightweight JSON payload (< 60 bytes)', () {
      final ping = NearbyService.createPingPacket('node_a1b2c3d4e5f6', timestamp: 1728400000000);
      expect(ping['type'], equals('PING'));
      expect(ping['s'], equals('node_a1b2c3d4e5f6'));
      expect(ping['t'], equals(1728400000000));

      final jsonStr = '{"type":"${ping['type']}","s":"${ping['s']}","t":${ping['t']}}';
      expect(jsonStr.length, lessThan(60), reason: 'Lightweight keep-alive ping must not saturate BLE radio');
      expect(NearbyService.isPingPacket(ping), isTrue);
      expect(NearbyService.isPingPacket({'type': 'CHAT'}), isFalse);
      expect(NearbyService.isPingPacket('invalid'), isFalse);
    });

    test('MeshPeer.isReachable honors 25s threshold for 1-hop and 45s for multi-hop', () {
      final now = DateTime.now();
      final directReachable = MeshPeer(
        peerId: 'p1',
        peerName: 'P1',
        publicKeyHex: 'pk1',
        hopCount: 1,
        lastSeen: now.subtract(const Duration(seconds: 24)),
      );
      expect(directReachable.isReachable, isTrue);

      final directExpired = MeshPeer(
        peerId: 'p2',
        peerName: 'P2',
        publicKeyHex: 'pk2',
        hopCount: 1,
        lastSeen: now.subtract(const Duration(seconds: 26)),
      );
      expect(directExpired.isReachable, isFalse);

      final multiHopReachable = MeshPeer(
        peerId: 'p3',
        peerName: 'P3',
        publicKeyHex: 'pk3',
        hopCount: 2,
        lastSeen: now.subtract(const Duration(seconds: 40)),
      );
      expect(multiHopReachable.isReachable, isTrue);

      final multiHopExpired = MeshPeer(
        peerId: 'p4',
        peerName: 'P4',
        publicKeyHex: 'pk4',
        hopCount: 2,
        lastSeen: now.subtract(const Duration(seconds: 50)),
      );
      expect(multiHopExpired.isReachable, isFalse);
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

    test('generateTacticalCallsign returns Survivor #<4-digit numbers> deterministically', () {
      final callsignA1 = NearbyService.generateTacticalCallsign('node_a1b2c3d4e5f6');
      final callsignA2 = NearbyService.generateTacticalCallsign('node_a1b2c3d4e5f6');
      final callsignB = NearbyService.generateTacticalCallsign('node_9876543210ab');

      expect(callsignA1, equals(callsignA2), reason: 'Must be deterministic for same nodeId');
      expect(RegExp(r'^Survivor #\d{4}$').hasMatch(callsignA1), isTrue,
          reason: 'Must match Survivor #<4 digits>');
      expect(RegExp(r'^Survivor #\d{4}$').hasMatch(callsignB), isTrue,
          reason: 'Must match Survivor #<4 digits>');
    });

    test('resolvePeerDisplayName prioritizes real custom names over generic fallback', () {
      final service = NearbyService();
      service.discoveredMeshPeers.clear();

      // Peer with custom real name in Mesh
      service.discoveredMeshPeers['node_somchai'] = MeshPeer(
        peerId: 'node_somchai',
        peerName: 'สมชาย ใจดี',
        publicKeyHex: '1234abcd',
        hopCount: 1,
        lastSeen: DateTime.now(),
      );

      // Even if fallbackName is a generic callsign like Survivor #1234 or Survivor_1234
      final resolved = service.resolvePeerDisplayName(
        'node_somchai',
        fallbackName: 'Survivor #1234',
      );
      expect(resolved, equals('สมชาย ใจดี'),
          reason: 'Should prioritize real profile name over generic callsign');
    });

    test('resolvePeerDisplayName falls back to deterministic callsign when name is generic or ugly', () {
      final service = NearbyService();
      service.discoveredMeshPeers.clear();

      final resolved = service.resolvePeerDisplayName(
        'node_a1b2c3d4e5f6',
        fallbackName: 'node_a1b2c3d4e5f6',
      );
      expect(resolved, equals(NearbyService.generateTacticalCallsign('node_a1b2c3d4e5f6')),
          reason: 'Should return deterministic Survivor #<4 digits> instead of node_xxx');
    });
  });
}
