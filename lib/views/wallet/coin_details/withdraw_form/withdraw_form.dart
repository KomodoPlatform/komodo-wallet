import 'dart:async' show Timer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/analytics/events/transaction_events.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/fill_form_memo.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/fields/fields.dart';
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
      child: MultiBlocListener(
        listeners: [
          BlocListener<WithdrawFormBloc, WithdrawFormState>(
            listenWhen: (prev, curr) =>
                prev.step != curr.step && curr.step == WithdrawFormStep.success,
            listener: (context, state) {
              final authBloc = context.read<AuthBloc>();
              final walletType =
                  authBloc.state.currentUser?.wallet.config.type.name ?? '';
              context.read<AnalyticsBloc>().logEvent(
                    SendSucceededEventData(
                      assetSymbol: state.asset.id.id,
                      network: state.asset.id.subClass.name,
                      amount: double.tryParse(state.amount) ?? 0.0,
                      walletType: walletType,
                    ),
                  );
              widget.onSuccess();
            },
          ),
          BlocListener<WithdrawFormBloc, WithdrawFormState>(
            listenWhen: (prev, curr) =>
                prev.step != curr.step && curr.step == WithdrawFormStep.failed,
            listener: (context, state) {
              final authBloc = context.read<AuthBloc>();
              final walletType =
                  authBloc.state.currentUser?.wallet.config.type.name ?? '';
              final reason = state.transactionError?.message ?? 'unknown';
              context.read<AnalyticsBloc>().logEvent(
                    SendFailedEventData(
                      assetSymbol: state.asset.id.id,
                      network: state.asset.protocol.subClass.name,
                      failReason: reason,
                      walletType: walletType,
                    ),
                  );
            },
          ),
        ],
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
      child: UiPrimaryButton(
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
            _buildRow(
              LocaleKeys.amount.tr(),
              preview.balanceChanges.netChange.toString(),
            ),
            const SizedBox(height: 8),
            _buildRow(LocaleKeys.fee.tr(), preview.fee.formatTotal()),
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
              LocaleKeys.transactionHash.tr(),
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
        final isSourceInputEnabled =
            // Enabled if the asset has multiple source addresses or if there is
            // no selected address and pubkeys are available.
            (state.pubkeys?.keys.length ?? 0) > 1 ||
                (state.selectedSourceAddress == null &&
                    (state.pubkeys?.isNotEmpty ?? false));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SourceAddressField(
              asset: state.asset,
              pubkeys: state.pubkeys,
              selectedAddress: state.selectedSourceAddress,
              isLoading: state.pubkeys?.isEmpty ?? true,
              onChanged: isSourceInputEnabled
                  ? (address) => address == null
                      ? null
                      : context
                          .read<WithdrawFormBloc>()
                          .add(WithdrawFormSourceChanged(address))
                  : null,
            ),
            const SizedBox(height: 16),
            RecipientAddressWithNotification(
              address: state.recipientAddress,
              isMixedAddress: state.isMixedCaseAddress,
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
            if (state.asset.protocol is TendermintProtocol) ...[
              const IbcTransferField(),
              if (state.isIbcTransfer) ...[
                const SizedBox(height: 16),
                const IbcChannelField(),
              ],
              const SizedBox(height: 16),
            ],
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
              ErrorDisplay(
                message: LocaleKeys.withdrawPreviewError.tr(),
                detailedMessage: state.previewError!.message,
              ),
            const SizedBox(height: 16),
            PreviewWithdrawButton(
              onPressed: state.isSending || state.hasValidationErrors
                  ? null
                  : () {
                      final authBloc = context.read<AuthBloc>();
                      final walletType =
                          authBloc.state.currentUser?.wallet.config.type.name ??
                              '';
                      context.read<AnalyticsBloc>().logEvent(
                            SendInitiatedEventData(
                              assetSymbol: state.asset.id.id,
                              network: state.asset.protocol.subClass.name,
                              amount: double.tryParse(state.amount) ?? 0.0,
                              walletType: walletType,
                            ),
                          );
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
          LocaleKeys.transactionHash.tr(),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SelectableText(
          result.txHash,
          style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Mono'),
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
          LocaleKeys.network.tr(),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AssetLogo.ofId(asset.id),
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
              LocaleKeys.transactionFailed.tr(),
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
                title: Text(LocaleKeys.technicalDetails.tr()),
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

/// Shows a temporary notification when the address is converted to mixed case.
/// This is to avoid confusion for users when the auto-conversion happens.
/// The notification will be shown for a short duration and then fade out.
class RecipientAddressWithNotification extends StatefulWidget {
  final String address;
  final bool isMixedAddress;
  final Duration notificationDuration;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onQrScanned;
  final String? Function()? errorText;

  const RecipientAddressWithNotification({
    required this.address,
    required this.onChanged,
    required this.onQrScanned,
    required this.isMixedAddress,
    this.notificationDuration = const Duration(seconds: 10),
    this.errorText,
    super.key,
  });

  @override
  State<RecipientAddressWithNotification> createState() =>
      _RecipientAddressWithNotificationState();
}

class _RecipientAddressWithNotificationState
    extends State<RecipientAddressWithNotification> {
  bool _showNotification = false;
  Timer? _notificationTimer;

  @override
  void didUpdateWidget(RecipientAddressWithNotification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMixedAddress && !oldWidget.isMixedAddress) {
      _showTemporaryNotification();
    } else if (!widget.isMixedAddress) {
      setState(() {
        _showNotification = false;
      });
    }
  }

  void _showTemporaryNotification() {
    _notificationTimer?.cancel();
    setState(() {
      _showNotification = true;
    });

    _notificationTimer = Timer(widget.notificationDuration, () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecipientAddressField(
          address: widget.address,
          onChanged: widget.onChanged,
          onQrScanned: widget.onQrScanned,
          errorText: widget.errorText,
        ),
        if (_showNotification)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1.0,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  LocaleKeys.addressConvertedToMixedCase.tr(),
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: statusColor),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
