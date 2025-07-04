import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/coins_manager/coins_manager_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/model/authorize_mode.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';
import 'package:komodo_wallet/router/state/wallet_state.dart';
import 'package:komodo_wallet/shared/widgets/hidden_without_wallet.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/common/coins_list_header.dart';
import 'package:komodo_wallet/views/wallet/wallet_page/wallet_main/wallet_manager_search_field.dart';

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
    return Card(
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.all(0),
        elevation: pinned ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: isMobile
            ? _buildMobileSection(context)
            : _buildDesktopSection(context));
  }

  bool get isAuthenticated => mode == AuthorizeMode.logIn;
  Widget _buildDesktopSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: WalletManagerSearchField(onChange: onSearchChange),
                ),
              ),
              if (isAuthenticated) ...[
                Spacer(),
                CoinsWithBalanceCheckbox(
                  withBalance: withBalance,
                  onWithBalanceChange: onWithBalanceChange,
                ),
                SizedBox(width: 24),
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
            ],
          ),
          Spacer(),
          CoinsListHeader(isAuth: mode == AuthorizeMode.logIn),
        ],
      ),
    );
  }

  Widget _buildMobileSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Portfolio',
                style: theme.textTheme.titleLarge,
              ),
              Spacer(),
              if (isAuthenticated)
                UiPrimaryButton(
                  buttonKey: const Key('asset-management-button'),
                  onPressed: () => _onAddAssetsPress(context),
                  text: 'Add assets',
                  height: 36,
                  width: 147,
                  borderRadius: 10,
                  textStyle: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: WalletManagerSearchField(onChange: onSearchChange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              HiddenWithoutWallet(
                child: CoinsWithBalanceCheckbox(
                  withBalance: withBalance,
                  onWithBalanceChange: onWithBalanceChange,
                ),
              ),
            ],
          ),
          Spacer(),
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
