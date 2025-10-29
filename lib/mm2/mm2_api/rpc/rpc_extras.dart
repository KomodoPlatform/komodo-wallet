/// Provides coin-specific RPC parameter extensions for MM2 API calls.
///
/// This adapter centralizes coin-specific requirements that need to be added
/// to RPC requests, preventing duplication and keeping coin logic isolated.
class RpcExtras {
  /// Default amount value for KMD rewards when claiming.
  static const String kDefaultKmdRewardsAmount = '0';

  /// Returns coin-specific extra parameters for withdrawal requests.
  ///
  /// These parameters are merged into the 'params' section of the RPC request.
  /// Currently handles:
  /// - KMD: Adds kmd_rewards object with claimed_by_me flag
  ///
  /// Returns an empty map if no coin-specific parameters are needed.
  static Map<String, dynamic> withdrawForCoin(String coin) {
    final normalizedCoin = coin.toUpperCase();
    
    if (normalizedCoin == 'KMD') {
      return {
        'kmd_rewards': {
          'amount': kDefaultKmdRewardsAmount,
          'claimed_by_me': true,
        },
      };
    }
    
    return const {};
  }
}
