import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/common/withdraw_error_card.dart';

class WithdrawFormFailedSection extends StatelessWidget {
  const WithdrawFormFailedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        return Column(
          children: [
            _FailedHeader(),
            const SizedBox(height: 24),
            _FailedMessage(),
            const SizedBox(height: 24),
            _ErrorDetailsCard(state: state),
            const SizedBox(height: 24),
            _FailedActionButtons(),
          ],
        );
      },
    );
  }
}

class _FailedHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Icon(
      Icons.error_outline,
      size: 64,
      color: theme.colorScheme.error,
    );
  }
}

class _FailedMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      LocaleKeys.transactionFailed.tr(),
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.error,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ErrorDetailsCard extends StatelessWidget {
  final WithdrawFormState state;

  const _ErrorDetailsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.transactionError == null) {
      return const SizedBox.shrink();
    }

    return WithdrawErrorCard(
      error: state.transactionError!,
    );
  }
}

class _FailedActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BackButton(),
        const SizedBox(width: 16),
        _TryAgainButton(),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _handleBackPressed(context),
      child: Text(LocaleKeys.back.tr()),
    );
  }

  void _handleBackPressed(BuildContext context) {
    context.read<WithdrawFormBloc>().add(const WithdrawFormStepReverted());
  }
}

class _TryAgainButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => _handleTryAgainPressed(context),
      child: Text(LocaleKeys.tryAgain.tr()),
    );
  }

  void _handleTryAgainPressed(BuildContext context) {
    context.read<WithdrawFormBloc>().add(const WithdrawFormReset());
  }
}