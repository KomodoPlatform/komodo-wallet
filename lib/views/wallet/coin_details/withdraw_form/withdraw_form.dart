import 'dart:async' show Timer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/headers/withdraw_form_header.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/ui/gradient_border.dart';
import 'package:app_theme/app_theme.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/listeners/withdraw_form_listeners.dart';

import 'package:web_dex/views/wallet/coin_details/withdraw_form/sections/withdraw_form_fill_section.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/sections/withdraw_form_confirm_section.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/sections/withdraw_form_success_section.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/sections/withdraw_form_failed_section.dart';


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
        listeners: WithdrawFormListeners.getListeners(),
        child: WithdrawFormContent(
          onBackButtonPressed: widget.onBackButtonPressed,
          onSuccess: widget.onSuccess,
        ),
      ),
    );
  }
}

class WithdrawFormContent extends StatelessWidget {
  final VoidCallback? onBackButtonPressed;
  final VoidCallback onSuccess;

  const WithdrawFormContent({
    this.onBackButtonPressed,
    required this.onSuccess,
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
              child: switch (state.step) {
                WithdrawFormStep.fill => _buildScrollableForm(),
                WithdrawFormStep.confirm => const WithdrawFormConfirmSection(),
                WithdrawFormStep.success => WithdrawFormSuccessSection(
                    onSuccess: onSuccess,
                  ),
                WithdrawFormStep.failed => const WithdrawFormFailedSection(),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildScrollableForm() {
    final scrollController = ScrollController();

    return DexScrollbar(
      isMobile: isMobile,
      scrollController: scrollController,
      child: SingleChildScrollView(
        key: const Key('withdraw-form-scroll'),
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 16),
            GradientBorder(
              innerColor: dexPageColors.frontPlate,
              gradient: dexPageColors.formPlateGradient,
              child: const WithdrawFormFillSection(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
    final theme = Theme.of(context);
    final maybeTxExplorer = asset.protocol.explorerTxUrl(result.txHash);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Successful',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your transaction has been submitted',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHashSection(context),
            const Divider(height: 32),
            _buildNetworkSection(context),
            if (maybeTxExplorer != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => openUrl(maybeTxExplorer),
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
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  result.txHash,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.content_copy,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // Copy to clipboard logic
                },
                tooltip: 'Copy transaction hash',
                visualDensity: VisualDensity.compact,
              ),
            ],
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
          LocaleKeys.network.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
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