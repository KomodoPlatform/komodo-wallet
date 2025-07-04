import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_wallet/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/router/state/nfts_state.dart';
import 'package:komodo_wallet/router/state/routing_state.dart';

class NftWithdrawFooter extends StatelessWidget {
  const NftWithdrawFooter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftWithdrawBloc, NftWithdrawState>(
      builder: (context, state) {
        final bool isSending =
            (state is NftWithdrawFillState && state.isSending) ||
                (state is NftWithdrawConfirmState && state.isSending);
        final isSuccess = state is NftWithdrawSuccessState;
        if (isSuccess) {
          return _buildSuccessFooter(context, state);
        }

        return Row(
          children: [
            if (!isMobile)
              Flexible(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _SecondaryButton(
                    onPressed: () => _onBack(context),
                    text: LocaleKeys.back.tr(),
                  ),
                ),
              ),
            Flexible(
              flex: isMobile ? 10 : 6,
              child: _PrimaryButton(
                text: state is NftWithdrawConfirmState
                    ? LocaleKeys.confirmSend.tr()
                    : LocaleKeys.send.tr(),
                onPressed: () => _onSend(context),
                isSending: isSending,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessFooter(
    BuildContext context,
    NftWithdrawSuccessState state,
  ) {
    return _PrimaryButton(
      text: LocaleKeys.done.tr(),
      onPressed: () => routingState.nftsState.pageState = NFTSelectedState.none,
      isSending: false,
    );
  }

  void _onSend(BuildContext context) {
    final bloc = context.read<NftWithdrawBloc>();
    final NftWithdrawState state = bloc.state;

    if (state is NftWithdrawFillState) {
      bloc.add(
        const NftWithdrawSendEvent(),
      );
    } else if (state is NftWithdrawConfirmState) {
      bloc.add(const NftWithdrawConfirmSendEvent());
    }
  }

  void _onBack(BuildContext context) {
    final bloc = context.read<NftWithdrawBloc>();
    final NftWithdrawState state = bloc.state;
    if (state is NftWithdrawFillState) {
      routingState.nftsState.setDetailsAction(state.nft.uuid, false);
    } else {
      bloc.add(const NftWithdrawShowFillStep());
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.isSending,
    required this.onPressed,
  });
  final String text;
  final bool isSending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    return UiPrimaryButton(
      text: text,
      prefix: isSending
          ? Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: UiSpinner(
                color: colorScheme.secondary,
              ),
            )
          : null,
      height: 40,
      onPressed: isSending ? null : onPressed,
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.text,
    required this.onPressed,
  });
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<ColorSchemeExtension>()!;
    return UiBorderButton(
        height: 40,
        text: text,
        textColor: colorScheme.secondary,
        borderColor: colorScheme.secondary,
        backgroundColor: colorScheme.surfContLowest,
        borderWidth: 2,
        onPressed: onPressed);
  }
}
