import 'package:decimal/decimal.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

Transaction createBuyTransaction(
  double balanceChange, {
  int timeStamp = 1708646400, // $50,740.50 usd
}) {
  final String value = balanceChange.toString();
  return Transaction(
    id: '0',
    blockHeight: 10000,
    assetId: AssetId(
      id: 'BTC',
      name: 'Bitcoin',
      symbol: AssetSymbol(assetConfigId: 'BTC'),
      chainId: AssetChainId(chainId: 9),
      derivationPath: '',
      subClass: CoinSubClass.utxo,
    ),
    confirmations: 6,
    balanceChanges: BalanceChanges(
      netChange: Decimal.parse(value),
      receivedByMe: Decimal.parse(value),
      spentByMe: Decimal.zero,
      totalAmount: Decimal.parse(value),
    ),
    from: const ['1ABC...'],
    internalId: 'internal1',
    timestamp: DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000),
    to: const ['1XYZ...'],
    txHash: 'hash1',
    memo: 'Buy 1 BTC',
  );
}

Transaction createSellTransaction(
  double balanceChange, {
  int timeStamp = 1714435200, // $60,666.60 usd
}) {
  double adjustedBalanceChange = balanceChange;
  if (!adjustedBalanceChange.isNegative) {
    adjustedBalanceChange = -adjustedBalanceChange;
  }
  final String value = adjustedBalanceChange.toString();

  return Transaction(
    id: '0',
    blockHeight: 100200,
    assetId: AssetId(
      id: 'BTC',
      name: 'Bitcoin',
      symbol: AssetSymbol(assetConfigId: 'BTC'),
      chainId: AssetChainId(chainId: 9),
      derivationPath: '',
      subClass: CoinSubClass.utxo,
    ),
    confirmations: 6,
    balanceChanges: BalanceChanges(
      netChange: Decimal.parse(value),
      receivedByMe: Decimal.zero,
      spentByMe: Decimal.parse(adjustedBalanceChange.abs().toString()),
      totalAmount: Decimal.parse(value),
    ),
    from: const ['1ABC...'],
    internalId: 'internal3',
    timestamp: DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000),
    to: const ['1GHI...'],
    txHash: 'hash3',
    memo: 'Sell 0.5 BTC',
  );
}
