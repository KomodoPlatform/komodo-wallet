import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/nft_transactions/bloc/nft_transactions_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/views/nfts/common/widgets/nft_no_login.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/common/pages/nft_txn_empty_page.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/common/pages/nft_txn_failure_page.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/common/pages/nft_txn_loading_page.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/desktop/widgets/nft_txn_desktop_card.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/desktop/widgets/nft_txn_desktop_filters.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/desktop/widgets/nft_txn_desktop_header.dart';

class NftTxnDesktopPage extends StatelessWidget {
  const NftTxnDesktopPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<NftTransactionsBloc, NftTxnState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NftTxnDesktopFilters(),
              const SizedBox(height: 24),
              const NftTxnDesktopHeader(),
              const SizedBox(height: 4),
              const Divider(height: 1),
              Builder(
                builder: (context) {
                  if (state.status == NftTxnStatus.noLogin) {
                    return SizedBox(
                      height: 250,
                      child: NftNoLogin(
                        key: const Key('nft-transactions-nologin-msg'),
                        text: LocaleKeys.transactionsNoLoginCAT.tr(),
                      ),
                    );
                  }
                  if (state.status == NftTxnStatus.loading) {
                    return const NftTxnLoading();
                  }
                  if (state.status == NftTxnStatus.failure) {
                    return NftTxnFailurePage(
                      message: state.errorMessage ?? '--',
                      onReload: () {
                        context
                            .read<NftTransactionsBloc>()
                            .add(const NftTxnReceiveEvent());
                      },
                    );
                  }

                  if (state.filteredTransactions.isEmpty) {
                    return const NftTxnEmpty();
                  }
                  final scrollController = ScrollController();
                  return Flexible(
                    child: DexScrollbar(
                      isMobile: isMobile,
                      scrollController: scrollController,
                      child: ListView.separated(
                        controller: scrollController,
                        key: const Key('nft-page-transactions-list'),
                        shrinkWrap: true,
                        padding: isMobile
                            ? const EdgeInsets.only(top: 5)
                            : const EdgeInsets.only(top: 8),
                        itemCount: state.filteredTransactions.length,
                        itemBuilder: (context, int i) {
                          final data = state.filteredTransactions[i];
                          final txKey = data.getTxKey();

                          return NftTxnDesktopCard(
                            key: Key(txKey),
                            transaction: data,
                            onPressed: () {
                              context
                                  .read<NftTransactionsBloc>()
                                  .add(NftTxReceiveDetailsEvent(data));
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
