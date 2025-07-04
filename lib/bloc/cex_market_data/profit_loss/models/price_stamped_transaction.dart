import 'package:komodo_wallet/bloc/cex_market_data/profit_loss/models/fiat_value.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

class PriceStampedTransaction extends Transaction {
  final FiatValue fiatValue;

  PriceStampedTransaction({
    required Transaction transaction,
    required this.fiatValue,
  }) : super(
          id: transaction.id,
          internalId: transaction.internalId,
          assetId: transaction.assetId,
          timestamp: transaction.timestamp,
          confirmations: transaction.confirmations,
          blockHeight: transaction.blockHeight,
          from: transaction.from,
          to: transaction.to,
          fee: transaction.fee,
          txHash: transaction.txHash,
          memo: transaction.memo,
          balanceChanges: transaction.balanceChanges,
        );
}

class UsdPriceStampedTransaction extends PriceStampedTransaction {
  double get priceUsd => fiatValue.value;
  double get totalAmountUsd =>
      (balanceChanges.totalAmount.toDouble() * fiatValue.value).abs();
  double get balanceChangeUsd => amount.toDouble() * fiatValue.value;

  UsdPriceStampedTransaction(Transaction transaction, double priceUsd)
      : super(
          transaction: transaction,
          fiatValue: FiatValue.usd(priceUsd),
        );
}
