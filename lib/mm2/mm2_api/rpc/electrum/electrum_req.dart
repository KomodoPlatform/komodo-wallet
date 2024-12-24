import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/electrum.dart';

class ElectrumReq {
  ElectrumReq({
    this.mm2 = 1,
    required this.coin,
    required this.servers,
    this.swapContractAddress,
    this.fallbackSwapContract,
  });

  static const String method = 'electrum';
  final int mm2;
  final String coin;
  final List<Electrum> servers;
  final String? swapContractAddress;
  final String? fallbackSwapContract;
  late String userpass;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'coin': coin,
      'servers': servers.map((server) => server.toJson()).toList(),
      // limit the number of active connections to electrum servers to 1 to
      // reduce device load & request spamming. Use 3 connections on desktop
      // and 1 on mobile (web and native) using [isMobile] until a better
      // alternative is found
      // https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/coin_activation/#electrum-method
      'max_connected': isMobile ? 1 : 3,
      'userpass': userpass,
      'mm2': mm2,
      'tx_history': true,
      if (swapContractAddress != null)
        'swap_contract_address': swapContractAddress,
      if (fallbackSwapContract != null)
        'swap_contract_address': swapContractAddress,
    };
  }
}
