class GetDirectlyConnectedPeersResponse {
  GetDirectlyConnectedPeersResponse({required this.peers});

  factory GetDirectlyConnectedPeersResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final peersMap = json['result'] as Map<String, dynamic>? ?? {};
    final peersList = peersMap.keys.map((String key) {
      final peers = peersMap[key] as List<dynamic>? ?? [];
      return DirectlyConnectedPeer(
        peerId: key,
        peerAddresses: peers.map((dynamic peer) => peer.toString()).toList(),
      );
    }).toList();

    return GetDirectlyConnectedPeersResponse(peers: peersList);
  }

  final List<DirectlyConnectedPeer> peers;
}

class DirectlyConnectedPeer {
  DirectlyConnectedPeer({required this.peerId, required this.peerAddresses});

  factory DirectlyConnectedPeer.fromJson(Map<String, dynamic> json) {
    return DirectlyConnectedPeer(
      peerId: json['id'] as String? ?? '',
      peerAddresses: json['addresses'] as List<String>? ?? [],
    );
  }

  final String peerId;
  final List<String> peerAddresses;
}
