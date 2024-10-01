import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';
import 'package:web_dex/model/withdraw_details/fee_details.dart';

Transaction createBuyTransaction(
  double balanceChange, {
  int timeStamp = 1708646400, // $50,740.50 usd
}) {
  final String value = balanceChange.toString();
  return Transaction(
    blockHeight: 10000,
    coin: 'BTC',
    confirmations: 6,
    feeDetails: FeeDetails(type: 'utxo', coin: 'BTC'),
    from: ['1ABC...'],
    internalId: 'internal1',
    myBalanceChange: value,
    receivedByMe: value,
    spentByMe: '0.0',
    timestamp: timeStamp,
    to: ['1XYZ...'],
    totalAmount: value,
    txHash: 'hash1',
    txHex: 'hex1',
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
    blockHeight: 100200,
    coin: 'BTC',
    confirmations: 6,
    feeDetails: FeeDetails(type: 'utxo', coin: 'BTC'),
    from: ['1XYZ...'],
    internalId: 'internal3',
    myBalanceChange: value,
    receivedByMe: '0.0',
    spentByMe: adjustedBalanceChange.abs().toString(),
    timestamp: timeStamp,
    to: ['1GHI...'],
    totalAmount: value,
    txHash: 'hash3',
    txHex: 'hex3',
    memo: 'Sell 0.5 BTC',
  );
}
