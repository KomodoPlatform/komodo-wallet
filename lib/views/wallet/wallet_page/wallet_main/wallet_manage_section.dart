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
import 'package:web_dex/views/wallet/wallet_page/common/coins_list_header.dart';
import 'package:web_dex/views/wallet/wallet_page/wallet_main/wallet_manager_search_field.dart';

class WalletManageSection extends StatelessWidget {
  const WalletManageSection({
    required this.mode,
    required this.withBalance,
    required this.onSearchChange,
    required this.onWithBalanceChange,
    required this.pinned,
    this.collapseProgress = 0.0,
    super.key,
  });
  final bool withBalance;
  final AuthorizeMode mode;
  final Function(bool) onWithBalanceChange;
  final Function(String) onSearchChange;
  final bool pinned;
  final double collapseProgress;

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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                const Spacer(),
                CoinsWithBalanceCheckbox(
                  withBalance: withBalance,
                  onWithBalanceChange: onWithBalanceChange,
                ),
                const SizedBox(width: 24),
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
          // Collapse the column headers on desktop
          //! TODO.c if (collapseProgress < 1.0) ...[
          //   SizedBox(height: (1.0 - collapseProgress) * 8),
          //   Opacity(
          //     opacity: 1.0 - collapseProgress,
          //     child: CoinsListHeader(isAuth: mode == AuthorizeMode.logIn),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildMobileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search row - always visible
          Row(
            children: [
              Expanded(
                child: WalletManagerSearchField(onChange: onSearchChange),
              ),
            ],
          ),
          // Collapsible row with zero-balance toggle
          // Only show if authenticated (since HiddenWithoutWallet hides content when not authenticated)
          if (isAuthenticated && collapseProgress < 1.0) ...[
            SizedBox(height: (1.0 - collapseProgress) * 12),
            SizedBox(
              height: (1.0 - collapseProgress) * 36,
              child: Opacity(
                opacity: 1.0 - collapseProgress,
                child: Row(
                  children: [
                    CoinsWithBalanceCheckbox(
                      withBalance: withBalance,
                      onWithBalanceChange: onWithBalanceChange,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
