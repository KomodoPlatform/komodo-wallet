import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_bloc.dart';
import 'package:web_dex/bloc/transaction_history/transaction_history_event.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/analytics/events/portfolio_events.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/coin_details_info.dart';
import 'package:web_dex/views/wallet/coin_details/coin_page_type.dart';
import 'package:web_dex/views/wallet/coin_details/rewards/kmd_reward_claim_success.dart';
import 'package:web_dex/views/wallet/coin_details/rewards/kmd_rewards_info.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/withdraw_form.dart';
import 'package:web_dex/shared/utils/utils.dart';

class CoinDetails extends StatefulWidget {
  const CoinDetails({
    super.key,
    required this.coin,
    required this.onBackButtonPressed,
  });

  final Coin coin;
  final VoidCallback onBackButtonPressed;

  @override
  State<CoinDetails> createState() => _CoinDetailsState();
}

class _CoinDetailsState extends State<CoinDetails> {
  late TransactionHistoryBloc _txHistoryBloc;
  CoinPageType _selectedPageType = CoinPageType.info;

  ColorScheme? _colorScheme;
  bool _loadingScheme = false;

  String _rewardValue = '';
  String _formattedUsdPrice = '';

  @override
  void initState() {
    _txHistoryBloc = context.read<TransactionHistoryBloc>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _txHistoryBloc.add(TransactionHistorySubscribe(coin: widget.coin));
      final walletType =
          context.read<AuthBloc>().state.currentUser?.wallet.config.type.name ??
              '';
      context.read<AnalyticsBloc>().logEvent(
            AssetViewedEventData(
              assetSymbol: widget.coin.abbr,
              assetNetwork: widget.coin.protocolType,
              walletType: walletType,
            ),
          );
    });
    super.initState();
  }

  Future<void> _loadSchemeIfNeeded(BuildContext context, bool enabled) async {
    if (!enabled) {
      if (_colorScheme != null) setState(() => _colorScheme = null);
      return;
    }
    if (_colorScheme != null || _loadingScheme) return;
    _loadingScheme = true;
    final ticker = abbr2Ticker(widget.coin.abbr).toLowerCase();
    final provider = AssetImage(
      'packages/komodo_defi_framework/assets/coin_icons/png/$ticker.png',
    );
    final brightness = Theme.of(context).brightness;
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: provider,
        brightness: brightness,
      );
      if (mounted) {
        setState(() {
          _colorScheme = scheme;
        });
      }
    } catch (_) {
      // ignore errors, fallback to default theme
    }
    _loadingScheme = false;
  }

  @override
  void dispose() {
    // _txHistoryBloc.add(TransactionHistoryUnsubscribe(coin: widget.coin));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        _loadSchemeIfNeeded(context, settings.coinThemeFromIcon);
        return BlocBuilder<CoinsBloc, CoinsState>(
          builder: (context, state) {
            Widget content = _buildContent();
            if (_colorScheme != null) {
              content = Theme(
                data: Theme.of(context).copyWith(colorScheme: _colorScheme!),
                child: content,
              );
            }
            return content;
          },
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedPageType) {
      case CoinPageType.info:
        return CoinDetailsInfo(
          coin: widget.coin,
          setPageType: _setPageType,
          onBackButtonPressed: widget.onBackButtonPressed,
        );

      case CoinPageType.send:
        return WithdrawForm(
          asset: widget.coin.toSdkAsset(context.read<KomodoDefiSdk>()),
          onSuccess: _openInfo,
          onBackButtonPressed: _openInfo,
        );

      case CoinPageType.claim:
        return KmdRewardsInfo(
          coin: widget.coin,
          onBackButtonPressed: _openInfo,
          onSuccess: (String reward, String formattedUsd) {
            _rewardValue = reward;
            _formattedUsdPrice = formattedUsd;
            _setPageType(CoinPageType.claimSuccess);
          },
        );

      case CoinPageType.claimSuccess:
        return KmdRewardClaimSuccess(
          reward: _rewardValue,
          formattedUsd: _formattedUsdPrice,
          onBackButtonPressed: _openInfo,
        );
    }
  }

  void _openInfo() => _setPageType(CoinPageType.info);

  void _setPageType(CoinPageType pageType) {
    setState(() => _selectedPageType = pageType);
  }
}
