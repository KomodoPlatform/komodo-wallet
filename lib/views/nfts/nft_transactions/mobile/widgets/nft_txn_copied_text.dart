import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/coins_bloc/coins_repo.dart';
import 'package:komodo_wallet/mm2/rpc/nft_transaction/nft_transactions_response.dart';
import 'package:komodo_wallet/model/coin.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/shared/widgets/hash_explorer_link.dart';

class NftTxnCopiedText extends StatelessWidget {
  const NftTxnCopiedText({
    super.key,
    required this.title,
    required this.transaction,
    required this.explorerType,
  });

  final String title;
  final NftTransaction transaction;
  final NftTxnExplorerType explorerType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    final textScheme = Theme.of(context).extension<TextThemeExtension>()!;
    final coin = _coin(context);
    final textStyle = textScheme.bodyXS.copyWith(color: colorScheme.s70);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textStyle),
        const SizedBox(height: 2),
        if (coin != null)
          HashExplorerLink(
            hash: _exploreValue,
            coin: coin,
            type: _explorerType,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Coin? _coin(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    return coinsRepository.getCoin(transaction.chain.coinAbbr());
  }

  String get _exploreValue {
    switch (explorerType) {
      case NftTxnExplorerType.tx:
        return transaction.transactionHash;
      case NftTxnExplorerType.from:
        return transaction.fromAddress;
      case NftTxnExplorerType.to:
        return transaction.toAddress;
    }
  }

  HashExplorerType get _explorerType {
    switch (explorerType) {
      case NftTxnExplorerType.tx:
        return HashExplorerType.tx;
      case NftTxnExplorerType.from:
      case NftTxnExplorerType.to:
        return HashExplorerType.address;
    }
  }
}

enum NftTxnExplorerType {
  tx,
  from,
  to,
}
