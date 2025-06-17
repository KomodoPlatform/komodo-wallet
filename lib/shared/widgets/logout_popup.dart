import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/wallet.dart';

class LogOutPopup extends StatelessWidget {
  const LogOutPopup({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        final currentWallet = state.currentUser?.wallet;
        return Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                LocaleKeys.logoutPopupTitle.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (currentWallet?.config.type == WalletType.iguana ||
                  currentWallet?.config.type == WalletType.hdwallet)
                SelectableText(
                  context.watch<TradingStatusBloc>().state is! TradingEnabled
                      ? LocaleKeys.logoutPopupDescriptionWalletOnly.tr()
                      : LocaleKeys.logoutPopupDescription.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 25),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiUnderlineTextButton(
                    key: const Key('popup-cancel-logout-button'),
                    width: 120,
                    height: 36,
                    text: LocaleKeys.cancel.tr(),
                    onPressed: onCancel,
                  ),
                  const SizedBox(width: 12),
                  UiPrimaryButton(
                    key: const Key('popup-confirm-logout-button'),
                    width: 120,
                    height: 36,
                    text: LocaleKeys.logOut.tr(),
                    onPressed: () => _onConfirmLogout(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _onConfirmLogout(BuildContext context) {
    // stop listening to balance updates before logging out
    context.read<CoinsBloc>().add(CoinsSessionEnded());
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    onConfirm();
  }
}
