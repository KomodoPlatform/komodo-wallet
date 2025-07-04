import 'package:komodo_wallet/bloc/bitrefill/data/bitrefill_provider.dart';

class BitrefillRepository {
  final BitrefillProvider _bitrefillProvider = BitrefillProvider();

  /// Returns the supported coins for Bitrefill.
  List<String> get bitrefillSupportedCoins =>
      _bitrefillProvider.supportedCoinAbbrs;

  /// Returns the embedded Bitrefill url.
  String embeddedBitrefillUrl({String? coinAbbr, String? refundAddress}) {
    return _bitrefillProvider.embeddedBitrefillUrl(
      coinAbbr: coinAbbr,
      refundAddress: refundAddress,
    );
  }
}
