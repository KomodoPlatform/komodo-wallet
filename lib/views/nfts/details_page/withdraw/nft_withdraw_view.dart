import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/nft_withdraw/nft_withdraw_bloc.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/model/nft.dart';
import 'package:komodo_wallet/views/nfts/details_page/withdraw/nft_withdraw_confirmation.dart';
import 'package:komodo_wallet/views/nfts/details_page/withdraw/nft_withdraw_footer.dart';
import 'package:komodo_wallet/views/nfts/details_page/withdraw/nft_withdraw_form.dart';
import 'package:komodo_wallet/views/nfts/details_page/withdraw/nft_withdraw_success.dart';

class NftWithdrawView extends StatefulWidget {
  const NftWithdrawView({
    super.key,
    required this.nft,
  });
  final NftToken nft;

  @override
  State<NftWithdrawView> createState() => _NftWithdrawViewState();
}

class _NftWithdrawViewState extends State<NftWithdrawView> {
  @override
  void initState() {
    final bloc = context.read<NftWithdrawBloc>();
    bloc.add(const NftWithdrawInit());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NftWithdrawBloc, NftWithdrawState>(
      builder: (context, state) {
        if (isMobile) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Builder(builder: (context) {
                switch (state) {
                  case NftWithdrawFillState():
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 28.0),
                      child: NftWithdrawForm(state: state),
                    );
                  case NftWithdrawConfirmState():
                    return NftWithdrawConfirmation(state: state);
                  case NftWithdrawSuccessState():
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 64.0),
                      child: NftWithdrawSuccess(state: state),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              }),
              const SizedBox(height: 12),
              const NftWithdrawFooter(),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (state is! NftWithdrawSuccessState) const Spacer(),
            Builder(builder: (context) {
              switch (state) {
                case NftWithdrawFillState():
                  return NftWithdrawForm(state: state);
                case NftWithdrawConfirmState():
                  return NftWithdrawConfirmation(state: state);
                case NftWithdrawSuccessState():
                  return NftWithdrawSuccess(state: state);
                default:
                  return const SizedBox.shrink();
              }
            }),
            if (state is NftWithdrawSuccessState)
              const Spacer()
            else
              SizedBox(height: state is NftWithdrawFillState ? 44 : 12),
            const NftWithdrawFooter(),
          ],
        );
      },
    );
  }
}
