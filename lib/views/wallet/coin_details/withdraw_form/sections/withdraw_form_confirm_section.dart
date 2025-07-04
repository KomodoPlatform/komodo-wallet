import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/shared/ui/gradient_border.dart';
import 'package:web_dex/views/dex/common/form_plate.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:app_theme/app_theme.dart';
import 'package:web_dex/common/screen.dart';
import 'package:komodo_ui/komodo_ui.dart';

class WithdrawFormConfirmSection extends StatelessWidget {
  const WithdrawFormConfirmSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        if (state.preview == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return _ConfirmScrollableContent(state: state);
      },
    );
  }
}

class _ConfirmScrollableContent extends StatelessWidget {
  final WithdrawFormState state;

  const _ConfirmScrollableContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return DexScrollbar(
      isMobile: isMobile,
      scrollController: scrollController,
      child: SingleChildScrollView(
        key: const Key('withdraw-confirm-scroll'),
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 16),
            GradientBorder(
              innerColor: dexPageColors.frontPlate,
              gradient: dexPageColors.formPlateGradient,
              child: _ConfirmFormContent(state: state),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ConfirmFormContent extends StatelessWidget {
  final WithdrawFormState state;

  const _ConfirmFormContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return FormPlate(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ConfirmHeader(),
            const SizedBox(height: 24),
            _TransactionDetailsCard(state: state),
            const SizedBox(height: 24),
            _PreviewDetailsCard(preview: state.preview!),
            const SizedBox(height: 32),
            _ConfirmActionButtons(state: state),
          ],
        ),
      ),
    );
  }
}

class _ConfirmHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.confirmWithdrawal.tr(),
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }
}

class _TransactionDetailsCard extends StatelessWidget {
  final WithdrawFormState state;

  const _TransactionDetailsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.transactionDetails.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _DetailField(
          label: LocaleKeys.transactionFrom.tr(),
          value: state.selectedSourceAddress?.address ?? '',
        ),
        const SizedBox(height: 16),
        _DetailField(
          label: LocaleKeys.transactionTo.tr(),
          value: state.recipientAddress,
        ),
        const SizedBox(height: 16),
        _DetailField(
          label: LocaleKeys.transactionAmount.tr(),
          value: '${state.amount} ${state.asset.id.id}',
          valueColor: theme.colorScheme.primary,
          valueFontWeight: FontWeight.bold,
        ),
        if (state.memo?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _DetailField(
            label: LocaleKeys.transactionMemo.tr(),
            value: state.memo!,
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: valueFontWeight ?? FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PreviewDetailsCard extends StatelessWidget {
  final WithdrawalPreview preview;

  const _PreviewDetailsCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.networkFeeAndTotal.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _FeeRow(
            label: LocaleKeys.networkFee.tr(),
            value: preview.fee.formatTotal(),
          ),
          const Divider(height: 32),
          _FeeRow(
            label: LocaleKeys.totalAmount.tr(),
            value: preview.balanceChanges.netChange.toString(),
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _FeeRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isTotal ? 16 : null,
          ),
        ),
      ],
    );
  }
}

class _ConfirmActionButtons extends StatelessWidget {
  final WithdrawFormState state;

  const _ConfirmActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConfirmButton(state: state),
        const SizedBox(height: 12),
        _BackButton(state: state),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final WithdrawFormState state;

  const _ConfirmButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: state.isSending
            ? null
            : () => _handleConfirmPressed(context),
        child: state.isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(LocaleKeys.confirmWithdrawal.tr()),
      ),
    );
  }

  void _handleConfirmPressed(BuildContext context) {
    context.read<WithdrawFormBloc>().add(const WithdrawFormSubmitted());
  }
}

class _BackButton extends StatelessWidget {
  final WithdrawFormState state;

  const _BackButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: state.isSending
            ? null
            : () => _handleBackPressed(context),
        child: Text(LocaleKeys.back.tr()),
      ),
    );
  }

  void _handleBackPressed(BuildContext context) {
    context.read<WithdrawFormBloc>().add(const WithdrawFormCancelled());
  }
}