import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/fill_form_memo.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/withdraw_form_header.dart';

class WithdrawForm extends StatefulWidget {
  final Asset asset;
  final VoidCallback onSuccess;
  final VoidCallback? onBackButtonPressed;

  const WithdrawForm({
    required this.asset,
    required this.onSuccess,
    this.onBackButtonPressed,
    super.key,
  });

  @override
  State<WithdrawForm> createState() => _WithdrawFormState();
}

class _WithdrawFormState extends State<WithdrawForm> {
  late final WithdrawFormBloc _formBloc;
  late final _sdk = context.read<KomodoDefiSdk>();

  @override
  void initState() {
    super.initState();
    _formBloc = WithdrawFormBloc(
      asset: widget.asset,
      sdk: _sdk,
    );
  }

  @override
  void dispose() {
    _formBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formBloc,
      child: BlocListener<WithdrawFormBloc, WithdrawFormState>(
        listenWhen: (prev, curr) =>
            prev.step != curr.step && curr.step == WithdrawFormStep.success,
        listener: (_, __) => widget.onSuccess(),
        child: WithdrawFormContent(
          onBackButtonPressed: widget.onBackButtonPressed,
        ),
      ),
    );
  }
}

class WithdrawFormContent extends StatelessWidget {
  final VoidCallback? onBackButtonPressed;

  const WithdrawFormContent({
    this.onBackButtonPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      buildWhen: (prev, curr) => prev.step != curr.step,
      builder: (context, state) {
        return Column(
          children: [
            WithdrawFormHeader(
              asset: state.asset,
              onBackButtonPressed: onBackButtonPressed,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _buildStep(state.step),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep(WithdrawFormStep step) {
    switch (step) {
      case WithdrawFormStep.fill:
        return const WithdrawFormFillSection();
      case WithdrawFormStep.confirm:
        return const WithdrawFormConfirmSection();
      case WithdrawFormStep.success:
        return const WithdrawFormSuccessSection();
      case WithdrawFormStep.failed:
        return const WithdrawFormFailedSection();
    }
  }
}

class NetworkErrorDisplay extends StatelessWidget {
  final TextError error;
  final VoidCallback? onRetry;

  const NetworkErrorDisplay({
    required this.error,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplay(
      message: error.message,
      icon: Icons.cloud_off,
      child: onRetry != null
          ? TextButton(
              onPressed: onRetry,
              child: Text(LocaleKeys.retryButtonText.tr()),
            )
          : null,
    );
  }
}

class TransactionErrorDisplay extends StatelessWidget {
  final TextError error;
  final VoidCallback? onDismiss;

  const TransactionErrorDisplay({
    required this.error,
    this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDisplay(
      message: error.message,
      icon: Icons.warning_amber_rounded,
      child: onDismiss != null
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
            )
          : null,
    );
  }
}

class PreviewWithdrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSending;

  const PreviewWithdrawButton({
    required this.onPressed,
    required this.isSending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        child: isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(LocaleKeys.previewWithdrawal.tr()),
      ),
    );
  }
}

class WithdrawPreviewDetails extends StatelessWidget {
  final WithdrawalPreview preview;

  const WithdrawPreviewDetails({
    required this.preview,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Amount', preview.balanceChanges.netChange.toString()),
            const SizedBox(height: 8),
            _buildRow('Fee', preview.fee.formatTotal()),
            // Add more preview details as needed
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value),
      ],
    );
  }
}

class WithdrawResultDetails extends StatelessWidget {
  final WithdrawalResult result;

  const WithdrawResultDetails({
    required this.result,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'Transaction Hash:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SelectableText(result.txHash),
            // Add more result details as needed
          ],
        ),
      ),
    );
  }
}

class WithdrawFormFillSection extends StatelessWidget {
  const WithdrawFormFillSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.asset.supportsMultipleAddresses) ...[
              SourceAddressField(
                asset: state.asset,
                pubkeys: state.pubkeys,
                selectedAddress: state.selectedSourceAddress,
                onChanged: (address) => address == null
                    ? null
                    : context
                        .read<WithdrawFormBloc>()
                        .add(WithdrawFormSourceChanged(address)),
              ),
              const SizedBox(height: 16),
            ],
            RecipientAddressField(
              address: state.recipientAddress,
              onChanged: (value) => context
                  .read<WithdrawFormBloc>()
                  .add(WithdrawFormRecipientChanged(value)),
              onQrScanned: (value) => context
                  .read<WithdrawFormBloc>()
                  .add(WithdrawFormRecipientChanged(value)),
              errorText: state.recipientAddressError == null
                  ? null
                  : () => state.recipientAddressError?.message,
            ),
            const SizedBox(height: 16),
            WithdrawAmountField(
              asset: state.asset,
              amount: state.amount,
              isMaxAmount: state.isMaxAmount,
              onChanged: (value) => context
                  .read<WithdrawFormBloc>()
                  .add(WithdrawFormAmountChanged(value)),
              onMaxToggled: (value) => context
                  .read<WithdrawFormBloc>()
                  .add(WithdrawFormMaxAmountEnabled(value)),
              amountError: state.amountError?.message,
            ),
            if (state.isCustomFeeSupported) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: state.isCustomFee,
                    onChanged: (enabled) => context
                        .read<WithdrawFormBloc>()
                        .add(WithdrawFormCustomFeeEnabled(enabled ?? false)),
                  ),
                  Text(LocaleKeys.customNetworkFee.tr()),
                ],
              ),
              if (state.isCustomFee && state.customFee != null) ...[
                const SizedBox(height: 8),

                FeeInfoInput(
                  asset: state.asset,
                  selectedFee: state.customFee!,
                  isCustomFee: true, // indicates user can edit it
                  onFeeSelected: (newFee) {
                    context
                        .read<WithdrawFormBloc>()
                        .add(WithdrawFormCustomFeeChanged(newFee!));
                  },
                ),

                // If the bloc has an error for custom fees:
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
              ],
            ],
            const SizedBox(height: 16),
            WithdrawMemoField(
              memo: state.memo,
              onChanged: (value) => context
                  .read<WithdrawFormBloc>()
                  .add(WithdrawFormMemoChanged(value)),
            ),
            const SizedBox(height: 24),
            // TODO! Refactor to use Formz and replace with the appropriate
            // error state value.
            if (state.hasPreviewError)
              ErrorDisplay(message: state.previewError!.message),
            const SizedBox(height: 16),
            PreviewWithdrawButton(
              onPressed: state.isSending || state.hasValidationErrors
                  ? null
                  : () {
                      context
                          .read<WithdrawFormBloc>()
                          .add(const WithdrawFormPreviewSubmitted());
                    },
              isSending: state.isSending,
            ),
          ],
        );
      },
    );
  }
}

class WithdrawFormConfirmSection extends StatelessWidget {
  const WithdrawFormConfirmSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        if (state.preview == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WithdrawPreviewDetails(preview: state.preview!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context
                        .read<WithdrawFormBloc>()
                        .add(const WithdrawFormCancelled()),
                    child: Text(LocaleKeys.back.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: state.isSending
                        ? null
                        : () {
                            context
                                .read<WithdrawFormBloc>()
                                .add(const WithdrawFormSubmitted());
                          },
                    child: state.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(LocaleKeys.confirm.tr()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class WithdrawFormSuccessSection extends StatelessWidget {
  const WithdrawFormSuccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              LocaleKeys.transactionSuccessful.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            WithdrawResultDetails(result: state.result!),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocaleKeys.done.tr()),
            ),
          ],
        );
      },
    );
  }
}

class WithdrawResultCard extends StatelessWidget {
  final WithdrawalResult result;
  final Asset asset;

  const WithdrawResultCard({
    required this.result,
    required this.asset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final maybeTxEplorer = asset.protocol.explorerTxUrl(result.txHash);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHashSection(context),
            const Divider(height: 32),
            _buildNetworkSection(context),
            if (maybeTxEplorer != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => openUrl(maybeTxEplorer),
                icon: const Icon(Icons.open_in_new),
                label: Text(LocaleKeys.viewOnExplorer.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHashSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Hash',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SelectableText(
          result.txHash,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AssetIcon(asset.id),
            const SizedBox(width: 8),
            Text(
              asset.id.name,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ],
    );
  }
}

class WithdrawFormFailedSection extends StatelessWidget {
  const WithdrawFormFailedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        return Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Transaction Failed',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (state.transactionError != null)
              WithdrawErrorCard(
                error: state.transactionError!,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context
                      .read<WithdrawFormBloc>()
                      .add(const WithdrawFormStepReverted()),
                  child: Text(LocaleKeys.back.tr()),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => context
                      .read<WithdrawFormBloc>()
                      .add(const WithdrawFormReset()),
                  child: Text(LocaleKeys.tryAgain.tr()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class WithdrawErrorCard extends StatelessWidget {
  final BaseError error;

  const WithdrawErrorCard({
    required this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.errorDetails.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              error.message,
              style: theme.textTheme.bodyMedium,
            ),
            if (error is TextError) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(LocaleKeys.withdrawErrorCardTileTitle.tr()),
                children: [
                  SelectableText(
                    (error as TextError).error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Mono',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
