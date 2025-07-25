import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/nft_transactions/nft_txn_repository.dart';
import 'package:web_dex/bloc/nfts/nft_main_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events/nft_events.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/router/state/nfts_state.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/nfts/details_page/nft_details_page.dart';
import 'package:web_dex/views/nfts/nft_main/nft_main.dart';
import 'package:web_dex/views/nfts/nft_receive/nft_receive_page.dart';
import 'package:web_dex/views/nfts/nft_transactions/nft_txn_page.dart';

class NftPage extends StatelessWidget {
  const NftPage({super.key, required this.pageState, required this.uuid});

  final NFTSelectedState pageState;
  final String uuid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final isLightTheme = state.themeMode == ThemeMode.light;
        final data = isLightTheme ? newThemeLight : newThemeDark;
        return Theme(
          data: data,
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<NftTxnRepository>(
                create: (context) => NftTxnRepository(
                  api: RepositoryProvider.of<Mm2Api>(context).nft,
                  coinsRepo: RepositoryProvider.of<CoinsRepo>(context),
                ),
              ),
            ],
            child: NFTPageView(
              pageState: pageState,
              uuid: uuid,
            ),
          ),
        );
      },
    );
  }
}

class NFTPageView extends StatefulWidget {
  final NFTSelectedState pageState;
  final String uuid;
  const NFTPageView({super.key, required this.pageState, required this.uuid});

  @override
  State<NFTPageView> createState() => _NFTPageViewState();
}

class _NFTPageViewState extends State<NFTPageView> {
  late NftMainBloc _nftMainBloc;
  late final Stopwatch _loadStopwatch;
  bool _loggedOpen = false;
  @override
  void initState() {
    _nftMainBloc = context.read<NftMainBloc>();
    _loadStopwatch = Stopwatch()..start();
    _nftMainBloc.add(const NftMainChainUpdateRequested());
    _nftMainBloc.add(const NftMainUpdateNftsStarted());
    super.initState();
  }

  @override
  void dispose() {
    _nftMainBloc.add(const NftMainUpdateNftsStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NftMainBloc, NftMainState>(
      listenWhen: (prev, curr) =>
          !_loggedOpen && curr.isInitialized && !prev.isInitialized,
      listener: (context, state) {
        _loggedOpen = true;
        final count = state.nftCount.values
            .fold<int>(0, (sum, item) => sum + (item ?? 0));
        context.read<AnalyticsBloc>().logEvent(
              NftGalleryOpenedEventData(
                nftCount: count,
                loadTimeMs: _loadStopwatch.elapsedMilliseconds,
              ),
            );
      },
      child: PageLayout(
        header: null,
        content: Expanded(
          child: Container(
            margin: isMobile ? const EdgeInsets.only(top: 14) : null,
            child: Builder(builder: (context) {
              switch (widget.pageState) {
                case NFTSelectedState.details:
                case NFTSelectedState.send:
                  return NftDetailsPage(
                    uuid: widget.uuid,
                    isSend: widget.pageState == NFTSelectedState.send,
                  );
                case NFTSelectedState.receive:
                  return const NftReceivePage();
                case NFTSelectedState.transactions:
                  return const NftListOfTransactionsPage();
                case NFTSelectedState.none:
                  return const NftMain();
              }
            }),
          ),
        ),
      ),
    );
  }
}
