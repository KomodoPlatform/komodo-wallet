import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/bitrefill/bloc/bitrefill_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/views/bitrefill/bitrefill_transaction_completed_dialog.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/withdraw_form_index.dart';

class WithdrawForm extends StatelessWidget {
  const WithdrawForm({
    super.key,
    required this.coin,
    required this.onBackButtonPressed,
    required this.onSuccess,
  });
  final Coin coin;
  final VoidCallback onBackButtonPressed;
  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WithdrawFormBloc>(
      create: (BuildContext context) => WithdrawFormBloc(
        coin: coin,
        coinsRepository: RepositoryProvider.of<CoinsRepo>(context),
        api: RepositoryProvider.of<Mm2Api>(context),
        goBack: onBackButtonPressed,
      ),
      child: isBitrefillIntegrationEnabled
          ? BlocConsumer<BitrefillBloc, BitrefillState>(
              listener: (BuildContext context, BitrefillState state) {
                if (state is BitrefillPaymentSuccess) {
                  onSuccess();
                  _showBitrefillPaymentSuccessDialog(context, state);
                }
              },
              builder: (BuildContext context, BitrefillState state) {
                final BitrefillPaymentInProgress? paymentState =
                    state is BitrefillPaymentInProgress ? state : null;

                final String? paymentAddress =
                    paymentState?.paymentIntent.paymentAddress;
                final String? paymentAmount =
                    paymentState?.paymentIntent.paymentAmount.toString();

                return WithdrawFormIndex(
                  coin: coin,
                  address: paymentAddress,
                  amount: paymentAmount,
                );
              },
            )
          : WithdrawFormIndex(
              coin: coin,
            ),
    );
  }

  void _showBitrefillPaymentSuccessDialog(
    BuildContext context,
    BitrefillPaymentSuccess state,
  ) {
    showDialog<BitrefillTransactionCompletedDialog>(
      context: context,
      builder: (BuildContext context) {
        return BitrefillTransactionCompletedDialog(
          title: LocaleKeys.bitrefillPaymentSuccessfull.tr(),
          message: LocaleKeys.bitrefillPaymentSuccessfullInstruction.tr(
            args: <String>[state.invoiceId],
          ),
          onViewInvoicePressed: () {},
        );
      },
    );
  }
}
