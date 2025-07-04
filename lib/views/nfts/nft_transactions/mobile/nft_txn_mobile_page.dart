import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/nft_transactions/bloc/nft_transactions_bloc.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/common/pages/nft_txn_empty_page.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/common/pages/nft_txn_failure_page.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/common/pages/nft_txn_loading_page.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/mobile/widgets/nft_txn_mobile_app_bar.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/mobile/widgets/nft_txn_mobile_card.dart';
import 'package:komodo_wallet/views/nfts/nft_transactions/mobile/widgets/nft_txn_mobile_filters.dart';

class NftTxnMobilePage extends StatelessWidget {
  const NftTxnMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftTransactionsBloc, NftTxnState>(
      builder: (context, state) {
        return Stack(
          children: [
            NftTxnMobileAppBar(
              filters: state.filters,
              onSettingsPressed: () => _onSettingsPressed(context),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Builder(
                builder: (context) {
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

                  return ListView.separated(
                    controller: ScrollController(),
                    key: const Key('nft-page-transactions-list'),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    itemCount: state.filteredTransactions.length,
                    itemBuilder: (context, int i) {
                      final data = state.filteredTransactions[i];

                      final txKey = data.getTxKey();
                      return NftTxnMobileCard(
                          key: Key(txKey),
                          transaction: data,
                          onPressed: () {
                            context
                                .read<NftTransactionsBloc>()
                                .add(NftTxReceiveDetailsEvent(data));
                          });
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSettingsPressed(BuildContext context) {
    final bloc = context.read<NftTransactionsBloc>();
    bloc.bottomSheetController = showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (generalContext) {
        return NftTxnMobileFilters(
          filters: bloc.state.filters,
          onApply: (filters) {
            // Navigator.of(context).pop();
            if (filters != null) {
              bloc.add(NftTxnEventFullFilterChanged(filters));
            }
          },
        );
      },
    );
  }
}
