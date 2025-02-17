import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/withdraw_form/withdraw_form_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallet/coin_details/constants.dart';
import 'package:web_dex/views/wallet/coin_details/withdraw_form/widgets/fill_form/send_form_preloader.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class FillFormFooter extends StatelessWidget {
  const FillFormFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WithdrawFormBloc, WithdrawFormState>(
      builder: (BuildContext context, WithdrawFormState state) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: withdrawWidth),
          child: state.isSending
              ?
              //TODO(@takenagain): Trezor SDK support
              // FillFormPreloader(state.trezorProgressStatus)
              const FillFormPreloader('Sending')
              : UiBorderButton(
                  key: const Key('send-enter-button'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  width: isMobile ? double.infinity : withdrawWidth,
                  height: isMobile ? 52 : 40,
                  onPressed: () {
                    context
                        .read<WithdrawFormBloc>()
                        .add(const WithdrawFormSubmitted());
                  },
                  text: LocaleKeys.send.tr(),
                ),
        );
      },
    );
  }
}
