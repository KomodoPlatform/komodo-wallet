import 'package:komodo_wallet/model/hd_account/hd_account.dart';
import 'package:komodo_wallet/model/hw_wallet/trezor_status.dart';

class TrezorBalanceStatusResponse {
  TrezorBalanceStatusResponse({this.result, this.error});

  static TrezorBalanceStatusResponse fromJson(Map<String, dynamic> json) {
    return TrezorBalanceStatusResponse(
        result: TrezorBalanceStatusResult.fromJson(json['result']));
  }

  final TrezorBalanceStatusResult? result;
  final dynamic error;
}

class TrezorBalanceStatusResult {
  TrezorBalanceStatusResult({
    required this.status,
    required this.balanceDetails,
  });

  static TrezorBalanceStatusResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final status = InitTrezorStatus.fromJson(json['status']);
    return TrezorBalanceStatusResult(
      status: status,
      balanceDetails: status == InitTrezorStatus.ok
          ? TrezorBalanceDetails.fromJson(json['details'])
          : null,
    );
  }

  final InitTrezorStatus status;
  final TrezorBalanceDetails? balanceDetails;
}

class TrezorBalanceDetails {
  TrezorBalanceDetails({
    required this.totalBalance,
    required this.accounts,
  });

  static TrezorBalanceDetails? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return TrezorBalanceDetails(
        totalBalance: HdBalance.fromJson(json['total_balance']),
        // Current api version (89c2b7050) only supports single (index == 0)
        // HD account for every asset.
        // But since trezor enable_utxo rpc returns list of accounts
        // (with a single element in it), and also there is a possibility of
        // adding multiple accounts support, we'll store list of accounts in our
        // model, although trezor balance rpc returns data for first account only.
        accounts: [
          HdAccount(
            accountIndex: json['account_index'],
            // Since we only support single account, its balance is the same
            // as total asset balance
            totalBalance: HdBalance.fromJson(json['total_balance']),
            addresses: json['addresses']
                .map<HdAddress>((dynamic item) => HdAddress.fromJson(item))
                .toList(),
          )
        ]);
  }

  final HdBalance? totalBalance;
  final List<HdAccount> accounts;
}
