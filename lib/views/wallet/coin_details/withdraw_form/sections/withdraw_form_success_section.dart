import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/common/app_assets.dart';
import 'package:web_dex/views/dex/common/front_plate.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/headers/simple_form_header.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:app_theme/app_theme.dart';
import 'package:web_dex/common/screen.dart';

class WithdrawFormSuccessSection extends StatelessWidget {
  final VoidCallback onSuccess;

  const WithdrawFormSuccessSection({required this.onSuccess, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        return _SuccessScrollableContent(
          state: state,
          onSuccess: onSuccess,
        );
      },
    );
  }
}

class _SuccessScrollableContent extends StatelessWidget {
  final WithdrawFormState state;
  final VoidCallback onSuccess;

  const _SuccessScrollableContent({
    required this.state,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return DexScrollbar(
      isMobile: isMobile,
      scrollController: scrollController,
      child: SingleChildScrollView(
        key: const Key('withdraw-success-scroll'),
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 24),
            _SuccessHeader(state: state),
            const SizedBox(height: 24),
            _SuccessContent(state: state, onSuccess: onSuccess),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  final WithdrawFormState state;

  const _SuccessHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _AmountDisplay(state: state),
        Text(
          '≈ \$0.00',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        DexSvgImage(
          path: Assets.withdrawSuccessBadge,
        ),
      ],
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final WithdrawFormState state;

  const _AmountDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: state.amount,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          TextSpan(
            text: ' ${state.asset.id.name}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final WithdrawFormState state;
  final VoidCallback onSuccess;

  const _SuccessContent({
    required this.state,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: theme.custom.dexFormWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TransactionDetailsSection(state: state),
            const SizedBox(height: 24),
            _SuccessActionButtons(state: state, onSuccess: onSuccess),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailsSection extends StatelessWidget {
  final WithdrawFormState state;

  const _TransactionDetailsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SentAssetCard(state: state),
        const SizedBox(height: 24),
        _RecipientCard(state: state),
      ],
    );
  }
}

class _SentAssetCard extends StatelessWidget {
  final WithdrawFormState state;

  const _SentAssetCard({required this.state});

  @override
  Widget build(BuildContext context) {

    return FrontPlate(
      child: Column(
        children: [
          SimpleFormHeader(title: LocaleKeys.sendFrom.tr()),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AssetInfoSection(state: state),
                const SizedBox(width: 5),
                _AmountSection(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetInfoSection extends StatelessWidget {
  final WithdrawFormState state;

  const _AssetInfoSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetIcon(state.asset.id, size: 40),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.asset.id.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                state.asset.id.id,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 9),
        ],
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  final WithdrawFormState state;

  const _AmountSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 18, top: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              state.amount.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '≈ \$0.00',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final WithdrawFormState state;

  const _RecipientCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return FrontPlate(
      child: Column(
        children: [
          SimpleFormHeader(title: LocaleKeys.to.tr()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _RecipientAddressRow(address: state.recipientAddress),
          ),
        ],
      ),
    );
  }
}

class _RecipientAddressRow extends StatelessWidget {
  final String address;

  const _RecipientAddressRow({required this.address});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: SelectableText(
            address,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: -0.5,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.content_copy,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => _handleCopyAddress(context),
          tooltip: LocaleKeys.copyAddress.tr(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _handleCopyAddress(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.copyAddressSuccess.tr()),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _SuccessActionButtons extends StatelessWidget {
  final WithdrawFormState state;
  final VoidCallback onSuccess;

  const _SuccessActionButtons({
    required this.state,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maybeTxExplorer = state.asset.protocol.explorerTxUrl(state.result?.txHash ?? '');

    return Row(
      children: [
        Expanded(
          child: _CloseButton(
            onPressed: onSuccess,
            backgroundColor: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ViewExplorerButton(
            explorerUrl: maybeTxExplorer,
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _CloseButton({
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return UiPrimaryButton(
      onPressed: onPressed,
      text: LocaleKeys.close.tr(),
      height: 48,
      backgroundColor: backgroundColor,
    );
  }
}

class _ViewExplorerButton extends StatelessWidget {
  final Uri? explorerUrl;

  const _ViewExplorerButton({this.explorerUrl});

  @override
  Widget build(BuildContext context) {
    return UiPrimaryButton(
      onPressed: explorerUrl != null ? () => openUrl(explorerUrl!) : null,
      text: LocaleKeys.viewOnExplorer.tr(),
      height: 48,
      prefix: const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: Icon(
          Icons.open_in_new,
          size: 18,
        ),
      ),
    );
  }
}