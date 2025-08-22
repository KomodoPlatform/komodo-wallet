/// IPFS gateway configuration constants
class IpfsConstants {
  IpfsConstants._();

  /// Primary gateways ordered by reliability and performance for web platforms
  /// These gateways are optimized for CORS support and reduced Cloudflare issues
  static const List<String> defaultWebOptimizedGateways = [
    'https://dweb.link/ipfs/', // IPFS Foundation - good CORS, subdomain resolution
    'https://gateway.pinata.cloud/ipfs/', // Pinata - reliable, NFT-focused
    'https://cloudflare-ipfs.com/ipfs/', // Cloudflare - fast CDN
    'https://nftstorage.link/ipfs/', // NFT Storage - specialized for NFTs
    'https://ipfs.io/ipfs/', // Standard IPFS Foundation gateway - fallback
  ];

  /// Standard gateways for non-web platforms (mobile, desktop)
  /// These gateways provide good reliability across different platforms
  static const List<String> defaultStandardGateways = [
    'https://ipfs.io/ipfs/',
    'https://dweb.link/ipfs/',
    'https://gateway.pinata.cloud/ipfs/',
  ];

  /// Circuit breaker cooldown duration for failed gateways
  static const Duration failureCooldown = Duration(minutes: 5);

  /// IPFS protocol identifier
  static const String ipfsProtocol = 'ipfs://';
}
