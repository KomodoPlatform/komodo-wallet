class HdAccount {
  HdAccount({
    required this.accountIndex,
    required this.addresses,
    this.derivationPath,
    this.totalBalance,
  });

  factory HdAccount.fromJson(Map<String, dynamic> json) {
    return HdAccount(
      accountIndex: json['account_index'],
      derivationPath: json['derivation_path'],
      totalBalance: HdBalance.fromJson(json['total_balance']),
      addresses: json['addresses']
          .map<HdAddress>((dynamic item) => HdAddress.fromJson(item))
          .toList(),
    );
  }

  final int accountIndex;
  final String? derivationPath;
  final HdBalance? totalBalance;
  final List<HdAddress> addresses;
}

class HdAddress {
  HdAddress({
    required this.address,
    required this.derivationPath,
    required this.chain,
    required this.balance,
  });

  factory HdAddress.fromJson(Map<String, dynamic> json) {
    return HdAddress(
      address: json['address'],
      derivationPath: json['derivation_path'],
      chain: json['chain'],
      balance: HdBalance.fromJson(json['balance']),
    );
  }

  final String address;
  final String derivationPath;
  final String chain;
  final HdBalance balance;
}

class HdBalance {
  HdBalance({
    required this.spendable,
    required this.unspendable,
  });

  factory HdBalance.fromJson(Map<String, dynamic> coinBalanceMap) {
    // Left in for backwards compatibility, but is no longer necessary from
    // KDF v2.3.0-beta onwards
    if (coinBalanceMap['spendable'] != null) {
      return HdBalance(
        spendable: double.tryParse(coinBalanceMap['spendable'].toString()) ?? 0,
        unspendable:
            double.tryParse(coinBalanceMap['unspendable'].toString()) ?? 0,
      );
    }

    final balances =
        coinBalanceMap.values.fold<({double spendable, double unspendable})>(
      (spendable: 0.0, unspendable: 0.0),
      (({double spendable, double unspendable}) sum, dynamic value) => (
        spendable: sum.spendable +
            (double.tryParse(value['spendable']?.toString() ?? '0') ?? 0),
        unspendable: sum.unspendable +
            (double.tryParse(value['unspendable']?.toString() ?? '0') ?? 0),
      ),
    );

    return HdBalance(
      spendable: balances.spendable,
      unspendable: balances.unspendable,
    );
  }

  double spendable;
  double unspendable;
}
