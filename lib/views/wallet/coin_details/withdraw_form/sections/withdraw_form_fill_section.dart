import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/fill_form_memo.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/fields.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/withdraw_form_source_item.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/withdraw_form_recipient_item.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/adaptive_dex_flip_button_overlapper.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/common/withdraw_preview_button.dart';
import 'package:web_dex/views/dex/common/form_plate.dart';
import '../helpers/analytics_helper.dart';
import 'package:komodo_ui/komodo_ui.dart';

class WithdrawFormFillSection extends StatelessWidget {
  const WithdrawFormFillSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        return FormPlate(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _SourceAndRecipientSection(state: state),
                const SizedBox(height: 16),
                ..._ConditionalFieldsSection(state: state).build(context),
                const SizedBox(height: 16),
                _MemoSection(state: state),
                const SizedBox(height: 24),
                ..._ErrorAndButtonSection(state: state).build(context),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SourceAndRecipientSection extends StatelessWidget {
  final WithdrawFormState state;

  const _SourceAndRecipientSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return AdaptiveDexFlipButtonWrapper(
      onTap: () async => false,
      topWidget: WithdrawFormSourceItem(
        asset: state.asset,
        pubkeys: state.pubkeys,
        selectedAddress: state.selectedSourceAddress,
        isLoading: state.pubkeys?.isEmpty ?? true,
        onChanged: (address) => _handleSourceChanged(context, address),
        amount: state.amount,
        onAmountChanged: (value) => _handleAmountChanged(context, value),
        onMaxToggled: (value) => _handleMaxAmountToggled(context, value),
        isMaxAmount: state.isMaxAmount,
      ),
      bottomWidget: WithdrawFormRecipientItem(
        address: state.recipientAddress,
        onChanged: (val) => _handleRecipientChanged(context, val),
        onQrScanned: (val) => _handleRecipientChanged(context, val),
        errorText: state.recipientAddressError == null
            ? null
            : () => state.recipientAddressError?.message,
      ),
    );
  }

  void _handleSourceChanged(BuildContext context, dynamic address) {
    if (address != null) {
      context.read<WithdrawFormBloc>().add(WithdrawFormSourceChanged(address));
    }
  }

  void _handleAmountChanged(BuildContext context, String value) {
    context.read<WithdrawFormBloc>().add(WithdrawFormAmountChanged(value));
  }

  void _handleMaxAmountToggled(BuildContext context, bool value) {
    context.read<WithdrawFormBloc>().add(WithdrawFormMaxAmountEnabled(value));
  }

  void _handleRecipientChanged(BuildContext context, String value) {
    context.read<WithdrawFormBloc>().add(WithdrawFormRecipientChanged(value));
  }
}

class _ConditionalFieldsSection {
  final WithdrawFormState state;

  const _ConditionalFieldsSection({required this.state});

  List<Widget> build(BuildContext context) {
    final widgets = <Widget>[];

    if (state.asset.protocol is TendermintProtocol) {
      widgets.addAll([
        const IbcTransferField(),
        if (state.isIbcTransfer) ...[
          const SizedBox(height: 16),
          const IbcChannelField(),
        ],
        const SizedBox(height: 16),
      ]);
    }

    if (state.isCustomFeeSupported) {
      widgets.addAll([
        const SizedBox(height: 16),
        _CustomFeeCheckbox(state: state),
        if (state.isCustomFee && state.customFee != null)
          ..._CustomFeeInput(state: state).build(context),
      ]);
    }

    return widgets;
  }
}

class _CustomFeeCheckbox extends StatelessWidget {
  final WithdrawFormState state;

  const _CustomFeeCheckbox({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: state.isCustomFee,
          onChanged: (enabled) => context
              .read<WithdrawFormBloc>()
              .add(WithdrawFormCustomFeeEnabled(enabled ?? false)),
        ),
        Text(LocaleKeys.customNetworkFee.tr()),
      ],
    );
  }
}

class _CustomFeeInput {
  final WithdrawFormState state;

  const _CustomFeeInput({required this.state});

  List<Widget> build(BuildContext context) {
    return [
      const SizedBox(height: 8),
      FeeInfoInput(
        asset: state.asset,
        selectedFee: state.customFee!,
        isCustomFee: true,
        onFeeSelected: (newFee) {
          context
              .read<WithdrawFormBloc>()
              .add(WithdrawFormCustomFeeChanged(newFee!));
        },
      ),
      if (state.customFeeError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            state.customFeeError!.message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ),
    ];
  }
}

class _MemoSection extends StatelessWidget {
  final WithdrawFormState state;

  const _MemoSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return WithdrawMemoField(
      memo: state.memo,
      onChanged: (value) => context
          .read<WithdrawFormBloc>()
          .add(WithdrawFormMemoChanged(value)),
    );
  }
}

class _ErrorAndButtonSection {
  final WithdrawFormState state;

  const _ErrorAndButtonSection({required this.state});

  List<Widget> build(BuildContext context) {
    return [
      if (state.hasPreviewError)
        ErrorDisplay(
          message: LocaleKeys.withdrawPreviewError.tr(),
          detailedMessage: state.previewError!.message,
        ),
      const SizedBox(height: 20),
      _PreviewButton(state: state),
    ];
  }
}

class _PreviewButton extends StatelessWidget {
  final WithdrawFormState state;

  const _PreviewButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return PreviewWithdrawButton(
      onPressed: state.isSending || state.hasValidationErrors
          ? null
          : () => _handlePreviewPressed(context),
      isSending: state.isSending,
    );
  }

  void _handlePreviewPressed(BuildContext context) {
    AnalyticsHelper.logSendInitiated(context, state);
    context
        .read<WithdrawFormBloc>()
        .add(const WithdrawFormPreviewSubmitted());
  }
}