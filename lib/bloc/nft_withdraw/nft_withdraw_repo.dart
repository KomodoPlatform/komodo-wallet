import 'package:easy_localization/easy_localization.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/errors.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/withdraw/withdraw_nft_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/nft/withdraw/withdraw_nft_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/send_raw_transaction/send_raw_transaction_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/validateaddress/validateaddress_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/withdraw/withdraw_errors.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/utils/utils.dart';

class NftWithdrawRepo {
  const NftWithdrawRepo({required Mm2Api api}) : _api = api;

  final Mm2Api _api;
  Future<WithdrawNftResponse> withdraw({
    required NftToken nft,
    required String address,
    int? amount,
  }) async {
    final request = WithdrawNftRequest(
      type: nft.contractType,
      chain: nft.chain,
      toAddress: address,
      tokenAddress: nft.tokenAddress,
      tokenId: nft.tokenId,
      amount: amount,
    );
    final Map<String, dynamic> json = await _api.nft.withdraw(request);
    if (json['error'] != null) {
      log(
        json['error'] as String? ?? 'unknown error',
        path: 'nft_main_repo => getNfts',
        isError: true,
      ).ignore();
      final BaseError error =
          withdrawErrorFactory.getError(json, nft.parentCoin.abbr);
      throw ApiError(message: error.message);
    }

    if (json['result'] == null) {
      throw ApiError(message: LocaleKeys.somethingWrong.tr());
    }

    try {
      final WithdrawNftResponse response = WithdrawNftResponse.fromJson(json);

      return response;
    } catch (e) {
      throw ParsingApiJsonError(message: e.toString());
    }
  }

  Future<SendRawTransactionResponse> confirmSend(
    String coin,
    String txHex,
  ) async {
    try {
      final request = SendRawTransactionRequest(coin: coin, txHex: txHex);
      final response = await _api.sendRawTransaction(request);
      return response;
    } catch (e) {
      return SendRawTransactionResponse(
        txHash: null,
        error: TextError(error: LocaleKeys.somethingWrong.tr()),
      );
    }
  }

  Future<ValidateAddressResponse> validateAddress(
    Coin coin,
    String address,
  ) async {
    try {
      final Map<String, dynamic>? responseRaw =
          await _api.validateAddress(coin.abbr, address);
      if (responseRaw == null) {
        throw ApiError(message: LocaleKeys.somethingWrong.tr());
      }
      return ValidateAddressResponse.fromJson(responseRaw);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }
}
