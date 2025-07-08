import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/common/page_header/page_header.dart';

class NftDetailsHeaderMobile extends StatelessWidget {
  const NftDetailsHeaderMobile({super.key, required this.close});
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NftWithdrawBloc>();
    final state = bloc.state;
    if (state is NftWithdrawSuccessState) return const SizedBox.shrink();

    return PageHeader(
      title: _title(state),
      onBackButtonPressed: () => _onBackButtonPressed(bloc),
    );
  }

  String _title(NftWithdrawState state) {
    if (state is NftWithdrawFillState) {
      return LocaleKeys.sendingProcess.tr();
    } else if (state is NftWithdrawConfirmState) {
      return LocaleKeys.confirmSend.tr();
    }
    return '';
  }

  void _onBackButtonPressed(NftWithdrawBloc bloc) {
    final state = bloc.state;
    if (state is NftWithdrawFillState) {
      close();
    } else if (state is NftWithdrawConfirmState) {
      bloc.add(const NftWithdrawShowFillStep());
    }
  }
}
