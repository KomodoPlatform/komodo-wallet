import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/cex_market_data/portfolio_growth/portfolio_growth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/profit_loss/profit_loss_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_tx_history/transaction.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/auto_scroll_text.dart';
import 'package:web_dex/shared/widgets/coin_fiat_balance.dart';
import 'package:web_dex/shared/widgets/segwit_icon.dart';
import 'package:web_dex/views/common/page_header/disable_coin_button.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';
import 'package:web_dex/views/common/pages/page_layout.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/portfolio_growth_chart.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/charts/portfolio_profit_loss_chart.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/coin_details_common_buttons.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/coin_details_info_fiat.dart';
import 'package:web_dex/views/wallet/coin_details/coin_page_type.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/faucet_button.dart';
import 'package:web_dex/views/wallet/coin_details/transactions/transaction_table.dart';

class CoinDetailsInfo extends StatefulWidget {
  const CoinDetailsInfo({
    required this.coin,
    required this.setPageType,
    required this.onBackButtonPressed,
    super.key,
  });
  final Coin coin;
  final void Function(CoinPageType) setPageType;
  final VoidCallback onBackButtonPressed;

  @override
  State<CoinDetailsInfo> createState() => _CoinDetailsInfoState();
}

class _CoinDetailsInfoState extends State<CoinDetailsInfo>
    with SingleTickerProviderStateMixin {
  Transaction? _selectedTransaction;
  late TabController _tabController;

  String? get _walletId => currentWalletBloc.wallet?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    const selectedDurationInitial = Duration(hours: 1);
    final growthBloc = context.read<PortfolioGrowthBloc>();

    growthBloc.add(
      PortfolioGrowthLoadRequested(
        coins: [widget.coin],
        fiatCoinId: 'USDT',
        selectedPeriod: selectedDurationInitial,
        walletId: _walletId!,
      ),
    );

    final ProfitLossBloc profitLossBloc = context.read<ProfitLossBloc>();

    profitLossBloc.add(
      ProfitLossPortfolioChartLoadRequested(
        coins: [widget.coin],
        selectedPeriod: const Duration(hours: 1),
        fiatCoinId: 'USDT',
        walletId: _walletId!,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      header: PageHeader(
        title: widget.coin.name,
        widgetTitle: widget.coin.mode == CoinMode.segwit
            ? const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: SegwitIcon(height: 22),
              )
            : null,
        backText: _backText,
        onBackButtonPressed: _onBackButtonPressed,
        actions: [_buildDisableButton()],
      ),
      content: Expanded(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isMobile) {
      return _MobileContent(
        coin: widget.coin,
        selectedTransaction: _selectedTransaction,
        setPageType: widget.setPageType,
        setTransaction: _selectTransaction,
        tabController: _tabController,
      );
    }
    return _DesktopContent(
      coin: widget.coin,
      selectedTransaction: _selectedTransaction,
      setPageType: widget.setPageType,
      setTransaction: _selectTransaction,
      tabController: _tabController,
    );
  }

  Widget _buildDisableButton() {
    if (_haveTransaction) return const SizedBox();

    return DisableCoinButton(
      onClick: () async {
        await coinsBloc.deactivateCoin(widget.coin);
        widget.onBackButtonPressed();
      },
    );
  }

  void _selectTransaction(Transaction? tx) {
    setState(() {
      _selectedTransaction = tx;
    });
  }

  void _onBackButtonPressed() {
    if (_haveTransaction) {
      _selectTransaction(null);
      return;
    }
    widget.onBackButtonPressed();
  }

  String get _backText {
    if (_haveTransaction) return LocaleKeys.back.tr();
    return LocaleKeys.backToWallet.tr();
  }

  bool get _haveTransaction => _selectedTransaction != null;
}

class _DesktopContent extends StatelessWidget {
  const _DesktopContent({
    required this.coin,
    required this.selectedTransaction,
    required this.setPageType,
    required this.setTransaction,
    required this.tabController,
  });

  final Coin coin;
  final Transaction? selectedTransaction;
  final void Function(CoinPageType) setPageType;
  final Function(Transaction?) setTransaction;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 20.0, 0, 20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: CustomScrollView(
        slivers: <Widget>[
          if (selectedTransaction == null)
            SliverToBoxAdapter(
              child: _DesktopCoinDetails(
                coin: coin,
                setPageType: setPageType,
                tabController: tabController,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
          TransactionTable(
            coin: coin,
            selectedTransaction: selectedTransaction,
            setTransaction: setTransaction,
          ),
        ],
      ),
    );
  }
}

class _DesktopCoinDetails extends StatelessWidget {
  const _DesktopCoinDetails({
    required this.coin,
    required this.setPageType,
    required this.tabController,
  });

  final Coin coin;
  final void Function(CoinPageType) setPageType;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final portfolioGrowthState = context.watch<PortfolioGrowthBloc>().state;
    final profitLossState = context.watch<ProfitLossBloc>().state;
    final isPortfolioGrowthSupported =
        portfolioGrowthState is! PortfolioGrowthChartUnsupported;
    final isProfitLossSupported =
        profitLossState is! PortfolioProfitLossChartUnsupported;
    final areChartsSupported =
        isPortfolioGrowthSupported || isProfitLossSupported;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 12, 0),
                child: CoinIcon(
                  coin.abbr,
                  size: 50,
                ),
              ),
              _Balance(coin: coin),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: _SpecificButton(
                  coin: coin,
                  selectWidget: setPageType,
                ),
              ),
              const Spacer(),
              CoinDetailsInfoFiat(
                coin: coin,
                isMobile: false,
              ),
            ],
          ),
          if (MainMenuValue.dex.isEnabledInCurrentMode())
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 28.0, 0, 0),
              child: CoinDetailsCommonButtons(
                isMobile: false,
                selectWidget: setPageType,
                clickSwapButton: () => _goToSwap(context, coin),
                coin: coin,
              ),
            ),
          const Gap(16),
          if (areChartsSupported)
            Card(
              child: TabBar(
                controller: tabController,
                tabs: [
                  if (isPortfolioGrowthSupported)
                    Tab(text: LocaleKeys.growth.tr()),
                  if (isProfitLossSupported)
                    Tab(text: LocaleKeys.profitAndLoss.tr()),
                ],
              ),
            ),
          if (areChartsSupported)
            SizedBox(
              height: 340,
              child: TabBarView(
                controller: tabController,
                children: [
                  if (isPortfolioGrowthSupported)
                    SizedBox(
                      width: double.infinity,
                      height: 340,
                      child: PortfolioGrowthChart(initialCoins: [coin]),
                    ),
                  if (isProfitLossSupported)
                    SizedBox(
                      width: double.infinity,
                      height: 340,
                      child: PortfolioProfitLossChart(initialCoins: [coin]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent({
    required this.coin,
    required this.selectedTransaction,
    required this.setPageType,
    required this.setTransaction,
    required this.tabController,
  });

  final Coin coin;
  final Transaction? selectedTransaction;
  final void Function(CoinPageType) setPageType;
  final Function(Transaction?) setTransaction;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        if (selectedTransaction == null)
          SliverToBoxAdapter(
            child: _buildMobileTopContent(context),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
        TransactionTable(
          coin: coin,
          selectedTransaction: selectedTransaction,
          setTransaction: setTransaction,
        ),
      ],
    );
  }

  Widget _buildMobileTopContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
      decoration: BoxDecoration(
        color: isMobile ? Theme.of(context).cardColor : null,
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Column(
        children: [
          CoinIcon(
            coin.abbr,
            size: 35,
          ),
          const SizedBox(height: 8),
          _Balance(coin: coin),
          const SizedBox(height: 12),
          _SpecificButton(coin: coin, selectWidget: setPageType),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: CoinDetailsInfoFiat(
              coin: coin,
              isMobile: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 14.0),
            child: CoinDetailsCommonButtons(
              isMobile: true,
              selectWidget: setPageType,
              clickSwapButton: () => _goToSwap(context, coin),
              coin: coin,
            ),
          ),
          if (coin.hasFaucet)
            FaucetButton(
              onPressed: () => setPageType(CoinPageType.faucet),
            ),
          Card(
            child: TabBar(
              controller: tabController,
              tabs: [
                Tab(text: LocaleKeys.growth.tr()),
                Tab(text: LocaleKeys.profitAndLoss.tr()),
              ],
            ),
          ),
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: tabController,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 340,
                  child: PortfolioGrowthChart(initialCoins: [coin]),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 340,
                  child: PortfolioProfitLossChart(initialCoins: [coin]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaucetButton extends StatelessWidget {
  const _FaucetButton({
    required this.coin,
    required this.openFaucet,
  });

  final Coin coin;
  final VoidCallback openFaucet;

  @override
  Widget build(BuildContext context) {
    if (!_isShown) return const SizedBox.shrink();

    return FocusDecorator(
      child: InkWell(
        onTap: coin.isSuspended ? null : openFaucet,
        child: Opacity(
          opacity: coin.isSuspended ? 0.4 : 1,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 55),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.custom.specificButtonBorderColor),
              color: theme.custom.specificButtonBackgroundColor,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 7,
            ),
            child: Text(
              LocaleKeys.faucet.tr(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isShown => coin.defaultAddress != null;
}

class _Balance extends StatelessWidget {
  const _Balance({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final value = doubleToString(coin.balance);

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMobile)
          const SizedBox.shrink()
        else
          Text(
            LocaleKeys.yourBalance.tr(),
            style: themeData.textTheme.titleMedium!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.custom.headerFloatBoxColor,
            ),
          ),
        Flexible(
          child: Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Flexible(
                child: AutoScrollText(
                  key: const Key('coin-details-balance'),
                  text: value,
                  isSelectable: true,
                  style: themeData.textTheme.titleMedium!.copyWith(
                    fontSize: isMobile ? 25 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.custom.headerFloatBoxColor,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                Coin.normalizeAbbr(coin.abbr),
                style: themeData.textTheme.titleSmall!.copyWith(
                  fontSize: isMobile ? 25 : 20,
                  fontWeight: FontWeight.w500,
                  color: theme.custom.headerFloatBoxColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) _FiatBalance(coin: coin),
      ],
    );
  }
}

class _FiatBalance extends StatelessWidget {
  const _FiatBalance({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Text(
            LocaleKeys.fiatBalance.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: CoinFiatBalance(
              coin,
              isSelectable: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecificButton extends StatelessWidget {
  const _SpecificButton({required this.coin, required this.selectWidget});
  final Coin coin;
  final void Function(CoinPageType) selectWidget;

  @override
  Widget build(BuildContext context) {
    final walletType = currentWalletBloc.wallet?.config.type;

    if (coin.abbr == 'KMD' && walletType == WalletType.iguana) {
      return _GetRewardsButton(
        coin: coin,
        onTap: () => selectWidget(CoinPageType.claim),
      );
    }
    if (coin.hasFaucet) {
      return _FaucetButton(
        coin: coin,
        openFaucet: () => selectWidget(CoinPageType.faucet),
      );
    }
    return const SizedBox.shrink();
  }
}

class _GetRewardsButton extends StatelessWidget {
  const _GetRewardsButton({required this.coin, required this.onTap});
  final Coin coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusDecorator(
      child: InkWell(
        onTap: coin.isSuspended ? null : onTap,
        child: Opacity(
          opacity: coin.isSuspended ? 0.4 : 1,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 110),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.custom.specificButtonBorderColor),
              color: theme.custom.specificButtonBackgroundColor,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: SvgPicture.asset(
                    '$assetsPath/ui_icons/rewards.svg',
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.labelLarge?.color ??
                          Colors.white,
                      BlendMode.srcIn,
                    ),
                    allowDrawingOutsideViewBox: true,
                  ),
                ),
                Text(
                  LocaleKeys.getRewards.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _goToSwap(BuildContext context, Coin coin) {
  context.read<TakerBloc>().add(TakerSetSellCoin(coin));
  routingState.selectedMenu = MainMenuValue.dex;
}
