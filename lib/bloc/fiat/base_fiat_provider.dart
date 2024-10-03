import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';

const String domain = "https://fiat-ramps-proxy.komodo.earth";

class Currency {
  final String symbol;
  final String name;
  final CoinType? chainType;
  final bool isFiat;

  Currency(this.symbol, this.name, {this.chainType, required this.isFiat});

  String getAbbr() {
    if (chainType == null) return symbol;

    final t = chainType;
    if (t == null ||
        t == CoinType.utxo ||
        (t == CoinType.cosmos && symbol == 'ATOM') ||
        (t == CoinType.cosmos && symbol == 'ATOM') ||
        (t == CoinType.erc20 && symbol == 'ETH') ||
        (t == CoinType.bep20 && symbol == 'BNB') ||
        (t == CoinType.avx20 && symbol == 'AVAX') ||
        (t == CoinType.etc && symbol == 'ETC') ||
        (t == CoinType.ftm20 && symbol == 'FTM') ||
        (t == CoinType.arb20 && symbol == 'ARB') ||
        (t == CoinType.hrc20 && symbol == 'ONE') ||
        (t == CoinType.plg20 && symbol == 'MATIC') ||
        (t == CoinType.mvr20 && symbol == 'MOVR')) return symbol;

    return '$symbol-${getCoinTypeName(chainType!).replaceAll('-', '')}';
  }

  /// Returns the short name of the coin including the chain type (if any).
  String formatNameShort() {
    return '$name${chainType != null ? ' (${getCoinTypeName(chainType!)})' : ''}';
  }
}

abstract class BaseFiatProvider {
  String getProviderId();

  String get providerIconPath;

  Stream<FiatOrderStatus> watchOrderStatus(String orderId);

  Future<List<Currency>> getFiatList();

  Future<List<Currency>> getCoinList();

  Future<List<Map<String, dynamic>>> getPaymentMethodsList(
    String source,
    Currency target,
    String sourceAmount,
  );

  Future<Map<String, dynamic>> getPaymentMethodPrice(
    String source,
    Currency target,
    String sourceAmount,
    Map<String, dynamic> paymentMethod,
  );

  Future<Map<String, dynamic>> buyCoin(
    String accountReference,
    String source,
    Currency target,
    String walletAddress,
    String paymentMethodId,
    String sourceAmount,
    String returnUrlOnSuccess,
  );

  @protected

  /// Makes an API request to the fiat provider. Uses the test mode if the app
  /// is in debug mode.
  Future<dynamic> apiRequest(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    final domainUri = Uri.parse(domain);
    Uri url;

    // Remove the leading '/' if it exists in /api/fiats kind of an endpoint
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    // Add `is_test_mode` query param to all requests if we are in debug mode
    final passedQueryParams = <String, dynamic>{}
      ..addAll(queryParams ?? {})
      ..addAll({
        'is_test_mode': kDebugMode ? 'true' : 'false',
      });

    url = Uri(
      scheme: domainUri.scheme,
      host: domainUri.host,
      path: endpoint,
      query: Uri(queryParameters: passedQueryParams).query,
    );

    final headers = {'Content-Type': 'application/json'};

    http.Response response;
    try {
      if (method == 'GET') {
        response = await http.get(
          url,
          headers: headers,
        );
      } else {
        response = await http.post(
          url,
          headers: headers,
          body: json.encode(body),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        return Future.error(
          json.decode(response.body),
        );
      }
    } catch (e) {
      return Future.error("Network error: $e");
    }
  }

  String? getCoinChainId(Currency currency) {
    switch (currency.chainType) {
      // These exist in the current fiat provider coin lists:
      case CoinType.utxo:
        // BTC, BCH, DOGE, LTC
        return currency.symbol;
      case CoinType.erc20:
        return 'ETH';
      case CoinType.bep20:
        return 'BSC'; // It is BNB for some providers like Banxa
      case CoinType.cosmos:
        return 'ATOM';
      case CoinType.avx20:
        return 'AVAX';
      case CoinType.etc:
        return 'ETC';
      case CoinType.ftm20:
        return 'FTM';
      case CoinType.arb20:
        return 'ARB';
      case CoinType.hrc20:
        return 'HARMONY';
      case CoinType.plg20:
        return 'MATIC';
      case CoinType.mvr20:
        return 'MOVR';
      default:
        return null;
    }

    // These are not offered yet by the providers:
    /*
    case CoinType.qrc20:
      return 'QRC-20';
    case CoinType.smartChain:
      return 'Smart Chain';
    case CoinType.hco20:
      return 'HCO-20';
    case CoinType.sbch:
      return 'SmartBCH';
    case CoinType.ubiq:
      return 'Ubiq';
    case CoinType.krc20:
      return 'KRC-20';
    case CoinType.iris:
      return 'Iris';
    case CoinType.slp:
      return 'SLP';
      */

    // These exist in coin config but not in CoinType structure yet:
    // ARBITRUM

    // These chain IDs are not supported yet by Komodo Wallet:
    // ADA / CARDANO
    // AVAX-X
    // ALGO
    // ARWEAVE
    // ASTR
    // BAJU
    // BNC
    // BOBA
    // BSV
    // BSX
    // CELO
    // CRO
    // DINGO
    // DOT
    // EGLD
    // ELROND
    // EOS
    // FIL
    // FLOW
    // FLR
    // GOERLI
    // GLMR
    // HBAR
    // KDA
    // KINT
    // KSM
    // KUSAMA
    // LOOPRING
    // MCK
    // METIS
    // MOB
    // NEAR
    // POLKADOT
    // RON
    // SEPOLIA
    // SOL
    // SOLANA
    // STARKNET
    // TERNOA
    // TERRA
    // TEZOS
    // TRON
    // WAX
    // XCH
    // XDAI
    // XLM
    // XPRT
    // XRP
    // XTZ
    // ZILLIQA
  }

  CoinType? getCoinType(String chain) {
    switch (chain) {
      case "BTC":
      case "BCH":
      case "DOGE":
      case "LTC":
        return CoinType.utxo;
      case "ETH":
        return CoinType.erc20;
      case "BSC":
      case "BNB":
        return CoinType.bep20;
      case "ATOM":
        return CoinType.cosmos;
      case "AVAX":
        return CoinType.avx20;
      case "ETC":
        return CoinType.etc;
      case "FTM":
        return CoinType.ftm20;
      case "ARB":
        return CoinType.arb20;
      case "HARMONY":
        return CoinType.hrc20;
      case "MATIC":
        return CoinType.plg20;
      case "MOVR":
        return CoinType.mvr20;
      default:
        return null;
    }
  }
}
