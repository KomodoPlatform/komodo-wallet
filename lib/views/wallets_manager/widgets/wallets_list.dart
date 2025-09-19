import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/model/wallets_manager_models.dart';
import 'package:web_dex/views/wallets_manager/widgets/wallet_list_item.dart';

class WalletsList extends StatelessWidget {
  const WalletsList(
      {Key? key, required this.walletType, required this.onWalletClick})
      : super(key: key);
  final WalletType walletType;
  final void Function(Wallet, WalletsManagerExistWalletAction) onWalletClick;
  @override
  Widget build(BuildContext context) {
    final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
    return StreamBuilder<List<Wallet>>(
      initialData: walletsRepository.wallets,
      stream: walletsRepository.getWallets().asStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Wallet>> snapshot) {
        final List<Wallet> wallets = snapshot.data ?? [];
        final List<Wallet> filteredWallets = wallets
            .where((w) =>
                w.config.type == walletType ||
                (walletType == WalletType.iguana &&
                    w.config.type == WalletType.hdwallet))
            .toList();
        if (wallets.isEmpty) {
          return const SizedBox(width: 0, height: 0);
        }
        final scrollController = ScrollController();
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: DexScrollbar(
            isMobile: isMobile,
            scrollController: scrollController,
            child: ListView.builder(
                controller: scrollController,
                itemCount: filteredWallets.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int i) {
                  return WalletListItem(
                    wallet: filteredWallets[i],
                    onClick: onWalletClick,
                  );
                }),
          ),
        );
      },
    );
  }
}
