import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/bloc_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/get_new_address/get_new_address_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw/trezor_withdraw_request.dart';
import 'package:web_dex/model/hd_account/hd_account.dart';
import 'package:web_dex/model/hw_wallet/init_trezor.dart';
import 'package:web_dex/model/hw_wallet/trezor_progress_status.dart';
import 'package:web_dex/model/hw_wallet/trezor_status.dart';
import 'package:web_dex/model/hw_wallet/trezor_task.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/withdraw_details/withdraw_details.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/show_trezor_passphrase_dialog.dart';
import 'package:web_dex/views/common/hw_wallet_dialog/show_trezor_pin_dialog.dart';

class TrezorCoinsBloc {
  TrezorCoinsBloc({
    required this.trezorRepo,
  });

  final TrezorRepo trezorRepo;
  Timer? _initNewAddressStatusTimer;

  Future<int?> initNewAddress(Asset asset) async {
    final TrezorGetNewAddressInitResponse response =
        await trezorRepo.initNewAddress(asset.id.id);
    final result = response.result;

    return result?.taskId;
  }

  void subscribeOnNewAddressStatus(
    int taskId,
    Asset asset,
    void Function(GetNewAddressResponse) callback,
  ) {
    _initNewAddressStatusTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      final GetNewAddressResponse initNewAddressStatus =
        await trezorRepo.getNewAddressStatus(taskId, asset);
      callback(initNewAddressStatus);
    });
  }

  void unsubscribeFromNewAddressStatus() {
    _initNewAddressStatusTimer?.cancel();
    _initNewAddressStatusTimer = null;
  }

  Future<List<HdAccount>> activateCoin(Asset asset) async {
    switch (asset.id.subClass) {
      case CoinSubClass.utxo:
      case CoinSubClass.smartChain:
        return await _enableUtxo(asset);
      default:
        return List.empty();
    }
  }

  Future<List<HdAccount>> _enableUtxo(Asset asset) async {
    final enableResponse = await trezorRepo.enableUtxo(asset);
    final taskId = enableResponse.result?.taskId;
    if (taskId == null) return List.empty();

    while (await trezorRepo.isTrezorWallet()) {
      final statusResponse = await trezorRepo.getEnableUtxoStatus(taskId);
      final InitTrezorStatus? status = statusResponse.result?.status;

      switch (status) {
        case InitTrezorStatus.error:
          return List.empty();

        case InitTrezorStatus.userActionRequired:
          final TrezorUserAction? action = statusResponse.result?.actionDetails;
          if (action == TrezorUserAction.enterTrezorPin) {
            // TODO! :(
            await showTrezorPinDialog(TrezorTask(
              taskId: taskId,
              type: TrezorTaskType.enableUtxo,
            ));
          } else if (action == TrezorUserAction.enterTrezorPassphrase) {
            // TODO! :(
            await showTrezorPassphraseDialog(TrezorTask(
              taskId: taskId,
              type: TrezorTaskType.enableUtxo,
            ));
          }
          break;

        case InitTrezorStatus.ok:
          final details = statusResponse.result?.details;
          if (details != null) {
            return details.accounts;
          }

        default:
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return List.empty();
  }

  Future<BlocResponse<WithdrawDetails, BaseError>> withdraw(
    TrezorWithdrawRequest request, {
    required void Function(TrezorProgressStatus?) onProgressUpdated,
  }) async {
    final withdrawResponse = await trezorRepo.withdraw(request);

    if (withdrawResponse.error != null) {
      return BlocResponse(
        result: null,
        error: TextError(error: withdrawResponse.error!),
      );
    }

    final int? taskId = withdrawResponse.result?.taskId;
    if (taskId == null) {
      return BlocResponse(
        result: null,
        error: TextError(error: LocaleKeys.somethingWrong.tr()),
      );
    }

    final int started = nowMs;
    while (nowMs - started < 1000 * 60 * 3) {
      final statusResponse = await trezorRepo.getWithdrawStatus(taskId);

      if (statusResponse.error != null) {
        return BlocResponse(
          result: null,
          error: TextError(error: statusResponse.error!),
        );
      }

      final InitTrezorStatus? status = statusResponse.result?.status;

      switch (status) {
        case InitTrezorStatus.error:
          return BlocResponse(
            result: null,
            error: TextError(
                error: statusResponse.result?.errorDetails?.error ??
                    LocaleKeys.somethingWrong.tr()),
          );

        case InitTrezorStatus.inProgress:
          final TrezorProgressStatus? progressDetails =
              statusResponse.result?.progressDetails;

          onProgressUpdated(progressDetails);
          break;

        case InitTrezorStatus.userActionRequired:
          final TrezorUserAction? action = statusResponse.result?.actionDetails;
          if (action == TrezorUserAction.enterTrezorPin) {
            await showTrezorPinDialog(TrezorTask(
              taskId: taskId,
              type: TrezorTaskType.withdraw,
            ));
          } else if (action == TrezorUserAction.enterTrezorPassphrase) {
            await showTrezorPassphraseDialog(TrezorTask(
              taskId: taskId,
              type: TrezorTaskType.enableUtxo,
            ));
          }
          break;

        case InitTrezorStatus.ok:
          return BlocResponse(
            result: statusResponse.result?.details,
            error: null,
          );

        default:
      }

      await Future<dynamic>.delayed(const Duration(milliseconds: 500));
    }

    await trezorRepo.cancelWithdraw(taskId);
    return BlocResponse(
      result: null,
      error: TextError(error: LocaleKeys.timeout.tr()),
    );
  }
}
