import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/shared/widgets/coin_item/coin_item_body.dart';

class CoinDropdown extends StatefulWidget {
  final List<AssetId> coins;
  final Widget? child;
  final Function(AssetId) onItemSelected;

  const CoinDropdown({
    super.key,
    required this.coins,
    required this.onItemSelected,
    this.child,
  });

  @override
  State<CoinDropdown> createState() => _CoinDropdownState();
}

class _CoinDropdownState extends State<CoinDropdown> {
  AssetId? selectedAssetId;

  void _showSearch() async {
    final selectedCoin = await showCoinSearch(
      context,
      coins: widget.coins,
    );

    if (selectedCoin != null && mounted) {
      setState(() {
        selectedAssetId = selectedCoin;
      });
      widget.onItemSelected(selectedCoin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coinsRepository = RepositoryProvider.of<CoinsRepo>(context);
    final coin = selectedAssetId == null
        ? null
        : coinsRepository.getCoinFromId(selectedAssetId!);

    return InkWell(
      onTap: _showSearch,
      child: widget.child ??
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: CoinItemBody(coin: coin),
          ),
    );
  }
}
