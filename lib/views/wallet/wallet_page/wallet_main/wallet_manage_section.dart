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
    final ThemeData theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.all(0),
      elevation: pinned ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WalletManagerSearchField(onChange: onSearchChange),
                Spacer(),
                HiddenWithoutWallet(
                  child: CoinsWithBalanceCheckbox(
                    withBalance: withBalance,
                    onWithBalanceChange: onWithBalanceChange,
                  ),
                ),
                SizedBox(width: 24),
                HiddenWithoutWallet(
                  child: UiPrimaryButton(
                    buttonKey: const Key('add-assets-button'),
                    onPressed: () => _onAddAssetsPress(context),
                    text: LocaleKeys.addAssets.tr(),
                    height: 36,
                    width: 147,
                    borderRadius: 10,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Spacer(),
            CoinsListHeader(isAuth: mode == AuthorizeMode.logIn),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Row(
                      children: [
                        UiPrimaryButton(
                          buttonKey: const Key('add-assets-button'),
                          onPressed: () => _onAddAssetsPress(context),
                          text: LocaleKeys.addAssets.tr(),
                          height: 36,
                          width: 147,
                          borderRadius: 10,
                          textStyle: theme.textTheme.bodySmall,
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
