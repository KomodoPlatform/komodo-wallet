import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/balance/trezor_balance_init/trezor_balance_init_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/balance/trezor_balance_init/trezor_balance_init_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/balance/trezor_balance_status/trezor_balance_status_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/balance/trezor_balance_status/trezor_balance_status_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/enable_utxo/trezor_enable_utxo/trezor_enable_utxo_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/enable_utxo/trezor_enable_utxo/trezor_enable_utxo_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/enable_utxo/trezor_enable_utxo_status/trezor_enable_utxo_status_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/enable_utxo/trezor_enable_utxo_status/trezor_enable_utxo_status_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/get_new_address/get_new_address_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/get_new_address/get_new_address_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor/init_trezor_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor/init_trezor_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor_cancel/init_trezor_cancel_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor_status/init_trezor_status_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor_status/init_trezor_status_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/trezor_connection_status/trezor_connection_status_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/trezor_passphrase/trezor_passphrase_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/trezor_pin/trezor_pin_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw/trezor_withdraw_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw/trezor_withdraw_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw_cancel/trezor_withdraw_cancel_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw_status/trezor_withdraw_status_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/withdraw/trezor_withdraw_status/trezor_withdraw_status_response.dart';
import 'package:web_dex/model/hw_wallet/trezor_connection_status.dart';
import 'package:web_dex/shared/utils/utils.dart';

class Mm2ApiTrezor {
  Mm2ApiTrezor(this.call);

  final Future<JsonMap> Function(dynamic) call;

  Future<InitTrezorRes> init(InitTrezorReq request) async {
    try {
      return InitTrezorRes.fromJson(await call(request));
    } catch (e) {
      return InitTrezorRes(
        error: e.toString(),
      );
    }
  }

  Future<InitTrezorStatusRes> initStatus(InitTrezorStatusReq request) async {
    try {
      return InitTrezorStatusRes.fromJson(await call(request));
    } catch (e) {
      return InitTrezorStatusRes(error: e.toString());
    }
  }

  Future<void> initCancel(InitTrezorCancelReq request) async {
    try {
      await call(request);
    } catch (e) {
      log(e.toString(), path: 'api => initTrezorCancel', isError: true)
          .ignore();
    }
  }

  Future<void> pin(TrezorPinRequest request) async {
    try {
      await call(request);
    } catch (e) {
      log(e.toString(), path: 'api => trezorPin', isError: true).ignore();
    }
  }

  Future<void> passphrase(TrezorPassphraseRequest request) async {
    try {
      await call(request);
    } catch (e) {
      log(e.toString(), path: 'api => trezorPassphrase', isError: true)
          .ignore();
    }
  }

  Future<TrezorEnableUtxoResponse> enableUtxo(
    TrezorEnableUtxoReq request,
  ) async {
    try {
      return TrezorEnableUtxoResponse.fromJson(await call(request));
    } catch (e) {
      return TrezorEnableUtxoResponse(error: e.toString());
    }
  }

  Future<TrezorEnableUtxoStatusResponse> enableUtxoStatus(
    TrezorEnableUtxoStatusReq request,
  ) async {
    try {
      return TrezorEnableUtxoStatusResponse.fromJson(await call(request));
    } catch (e) {
      return TrezorEnableUtxoStatusResponse(error: e.toString());
    }
  }

  Future<TrezorBalanceInitResponse> balanceInit(
    TrezorBalanceInitRequest request,
  ) async {
    try {
      return TrezorBalanceInitResponse.fromJson(await call(request));
    } catch (e) {
      return TrezorBalanceInitResponse(error: e.toString());
    }
  }

  Future<TrezorBalanceStatusResponse> balanceStatus(
    TrezorBalanceStatusRequest request,
  ) async {
    try {
      return TrezorBalanceStatusResponse.fromJson(await call(request));
    } catch (e) {
      return TrezorBalanceStatusResponse(error: e.toString());
    }
  }

  Future<TrezorGetNewAddressInitResponse> initNewAddress(String coin) async {
    try {
      final JsonMap response =
          await call(TrezorGetNewAddressInitReq(coin: coin));
      return TrezorGetNewAddressInitResponse.fromJson(response);
    } catch (e) {
      return TrezorGetNewAddressInitResponse(error: e.toString());
    }
  }

  Future<GetNewAddressResponse> getNewAddressStatus(int taskId) async {
    try {
      final JsonMap response =
          await call(TrezorGetNewAddressStatusReq(taskId: taskId));
      return GetNewAddressResponse.fromJson(response);
    } catch (e) {
      return GetNewAddressResponse(error: e.toString());
    }
  }

  Future<void> cancelGetNewAddress(int taskId) async {
    try {
      await call(TrezorGetNewAddressCancelReq(taskId: taskId));
    } catch (e) {
      log(e.toString(), path: 'api_trezor => getNewAddressCancel').ignore();
    }
  }

  Future<TrezorWithdrawResponse> withdraw(TrezorWithdrawRequest request) async {
    try {
      return TrezorWithdrawResponse.fromJson(await call(request));
    } catch (e) {
      return TrezorWithdrawResponse(error: e.toString());
    }
  }

  Future<TrezorWithdrawStatusResponse> withdrawStatus(
    TrezorWithdrawStatusRequest request,
  ) async {
    try {
      return TrezorWithdrawStatusResponse.fromJson(await call(request));
    } catch (e) {
      return TrezorWithdrawStatusResponse(error: e.toString());
    }
  }

  Future<void> withdrawCancel(TrezorWithdrawCancelRequest request) async {
    try {
      await call(request);
    } catch (e) {
      log(e.toString(), path: 'api => withdrawCancel', isError: true).ignore();
    }
  }

  Future<TrezorConnectionStatus> getConnectionStatus(String pubKey) async {
    try {
      final JsonMap responseJson =
          await call(TrezorConnectionStatusRequest(pubKey: pubKey));
      final String? status = responseJson['result']?['status'] as String?;
      if (status == null) return TrezorConnectionStatus.unknown;
      return TrezorConnectionStatus.fromString(status);
    } catch (e, s) {
      log(
        'Error getting trezor status: $e',
        path: 'api => trezorConnectionStatus',
        trace: s,
        isError: true,
      ).ignore();
      return TrezorConnectionStatus.unknown;
    }
  }
}
