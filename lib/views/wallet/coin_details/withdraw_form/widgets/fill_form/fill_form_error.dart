import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/shared/widgets/copied_text.dart';
import 'package:web_dex/shared/widgets/details_dropdown.dart';

class FillFormError extends StatelessWidget {
  const FillFormError({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (ctx, state) {
        if (!state.hasTransactionError) {
          return const SizedBox();
        }
        final BaseError sendError = state.transactionError!;
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SelectableText(
                sendError.message,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            if (sendError is ErrorWithDetails)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: DetailsDropdown(
                  summary: LocaleKeys.showMore.tr(),
                  content: SingleChildScrollView(
                    controller: ScrollController(),
                    child: CopiedText(
                      copiedValue: (sendError as ErrorWithDetails).details,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
