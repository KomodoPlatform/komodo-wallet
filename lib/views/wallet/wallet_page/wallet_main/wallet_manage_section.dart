import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/router/state/wallet_state.dart';
import 'package:web_dex/shared/widgets/hidden_without_wallet.dart';
import 'package:web_dex/views/wallet/wallet_page/common/coins_list_header.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/wallet_manager_search_field.dart';

class WalletManageSection extends StatelessWidget {
  const WalletManageSection({
    required this.mode,
    required this.withBalance,
    required this.onSearchChange,
    required this.onWithBalanceChange,
    required this.pinned,
    super.key,
  });
  final bool withBalance;
  final AuthorizeMode mode;
  final Function(bool) onWithBalanceChange;
  final Function(String) onSearchChange;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? _buildMobileSection(context)
        : _buildDesktopSection(context);
  }

  Widget _buildDesktopSection(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.all(0),
      elevation: pinned ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HiddenWithoutWallet(
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: theme.custom.walletEditButtonsBackgroundColor,
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UiPrimaryButton(
                          buttonKey: const Key('add-assets-button'),
                          onPressed: () => _onAddAssetsPress(context),
                          text: LocaleKeys.addAssets.tr(),
                          height: 30.0,
                          width: 110,
                          backgroundColor: themeData.colorScheme.surface,
                          textStyle: TextStyle(
                            color: themeData.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 3.0),
                          child: UiPrimaryButton(
                            buttonKey: const Key('remove-assets-button'),
                            onPressed: () => _onRemoveAssetsPress(context),
                            text: LocaleKeys.removeAssets.tr(),
                            height: 30.0,
                            width: 125,
                            backgroundColor: themeData.colorScheme.surface,
                            textStyle: TextStyle(
                              color: themeData.textTheme.labelLarge?.color
                                  ?.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    HiddenWithoutWallet(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 30.0),
                        child: CoinsWithBalanceCheckbox(
                          withBalance: withBalance,
                          onWithBalanceChange: onWithBalanceChange,
                        ),
                      ),
                    ),
                    WalletManagerSearchField(onChange: onSearchChange),
                  ],
                ),
              ],
            ),
          ),
          const CoinsListHeader(),
        ],
      ),
    );
  }

  Widget _buildMobileSection(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Column(
        children: [
          HiddenWithoutWallet(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 17.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.portfolio.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: themeData.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Row(
                      children: [
                        UiPrimaryButton(
                          buttonKey: const Key('add-assets-button'),
                          onPressed: () => _onAddAssetsPress(context),
                          text: LocaleKeys.addAssets.tr(),
                          height: 25.0,
                          width: 110,
                          backgroundColor: themeData.colorScheme.onSurface,
                          textStyle: TextStyle(
                            color: themeData.colorScheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 3.0),
                          child: UiPrimaryButton(
                            buttonKey: const Key('remove-assets-button'),
                            onPressed: () => _onRemoveAssetsPress(context),
                            text: LocaleKeys.remove.tr(),
                            height: 25.0,
                            width: 80,
                            backgroundColor: themeData.colorScheme.onSurface,
                            textStyle: TextStyle(
                              color: themeData.textTheme.labelLarge?.color
                                  ?.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HiddenWithoutWallet(
                child: CoinsWithBalanceCheckbox(
                  withBalance: withBalance,
                  onWithBalanceChange: onWithBalanceChange,
                ),
              ),
              WalletManagerSearchField(onChange: onSearchChange),
            ],
          ),
        ],
      ),
    );
  }

  void _onAddAssetsPress(BuildContext context) {
    context
        .read<CoinsManagerBloc>()
        .add(const CoinsManagerCoinsListReset(CoinsManagerAction.add));
    routingState.walletState.action = coinsManagerRouteAction.addAssets;
  }

  void _onRemoveAssetsPress(BuildContext context) {
    context
        .read<CoinsManagerBloc>()
        .add(const CoinsManagerCoinsListReset(CoinsManagerAction.remove));
    routingState.walletState.action = coinsManagerRouteAction.removeAssets;
  }
}

class CoinsWithBalanceCheckbox extends StatelessWidget {
  const CoinsWithBalanceCheckbox({
    required this.withBalance,
    required this.onWithBalanceChange,
    super.key,
  });

  final bool withBalance;
  final Function(bool) onWithBalanceChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UiCheckbox(
          key: const Key('coins-with-balance-checkbox'),
          value: withBalance,
          text: LocaleKeys.withBalance.tr(),
          onChanged: onWithBalanceChange,
        ),
      ],
    );
  }
}
