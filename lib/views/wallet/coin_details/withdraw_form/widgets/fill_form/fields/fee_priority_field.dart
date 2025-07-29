import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';

class FeePriorityField extends StatelessWidget {
  const FeePriorityField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (context, state) {
        final options = state.feeOptions;
        if (options == null) {
          return const SizedBox.shrink();
        }

        return SegmentedButton<WithdrawalFeeLevel>(
          segments: [
            ButtonSegment(
              value: WithdrawalFeeLevel.low,
              label: Text(options.low.displayNameOrDefault),
            ),
            ButtonSegment(
              value: WithdrawalFeeLevel.medium,
              label: Text(options.medium.displayNameOrDefault),
            ),
            ButtonSegment(
              value: WithdrawalFeeLevel.high,
              label: Text(options.high.displayNameOrDefault),
            ),
          ],
          selected: {state.feePriority},
          onSelectionChanged: (values) {
            if (values.isNotEmpty) {
              context
                  .read<WithdrawFormBloc>()
                  .add(WithdrawFormFeePriorityChanged(values.first));
            }
          },
        );
      },
    );
  }
}
