import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:web_dex/bloc/fiat/fiat_order_status.dart';

class RampPurchaseWatcher {
  FiatOrderStatus? _lastStatus;
  bool _isDisposed = false;

  /// Watches the status of new Ramp purchases.
  ///
  /// NB: Will only work if the Ramp checkout tab was opened by the app. I.e.
  /// the user copies the checkout URL and opens it in a new tab, we will not
  /// be able to track the status of that purchase. Implementing a microservice
  /// that can receive webhooks is a possible solution.
  ///
  /// [watchFirstPurchaseOnly] - if true, will only listen for status updates
  /// for the first purchase. If false, will we will no longer listen for
  /// status updates of the first purchase and will start listening for status
  /// updates of the new purchase. The ramp purchase is created in one of the
  /// last checkout steps, so if the user creates the purchase and goes back to
  /// the first step, Ramp will create a new purchase.
  Stream<FiatOrderStatus> watchOrderStatus({
    bool watchFirstPurchaseOnly = false,
  }) {
    _assertNotDisposed();

    RampPurchaseDetails? purchaseDetails;

    final controller = StreamController<FiatOrderStatus>();

    scheduleMicrotask(() async {
      StreamSubscription? subscription;

      final stream = watchNewRampOrdersCreated().takeWhile(
        (purchase) =>
            !controller.isClosed &&
            (purchaseDetails == null || !watchFirstPurchaseOnly),
      );
      try {
        subscription = stream.listen(
          (newPurchaseJson) =>
              purchaseDetails = RampPurchaseDetails.tryFromMessage(
                newPurchaseJson,
              ),
          cancelOnError: false,
        );

        while (!controller.isClosed) {
          if (purchaseDetails != null) {
            final status = await _getPurchaseStatus(purchaseDetails!);
            if (status != _lastStatus) {
              _lastStatus = status;
              controller.add(status);
            }

            if (status.isTerminal || controller.isClosed) break;
          }
          await Future.delayed(const Duration(seconds: 10));
        }
      } catch (e) {
        controller.addError(e);
        debugPrint('RampOrderWatcher: Error: $e');
      } finally {
        subscription?.cancel().ignore();
        _cleanup();
      }
    });

    return controller.stream;
  }

  Stream<Map<String, dynamic>> watchNewRampOrdersCreated() async* {
    _assertNotDisposed();

    final purchaseStartedController = StreamController<Map<String, dynamic>>();

    void handlerFunction(web.Event event) {
      if (purchaseStartedController.isClosed) return;
      final messageEvent = event as web.MessageEvent;
      if (messageEvent.data is Map) {
        try {
          final dataJson = (messageEvent.data as Map).cast<String, dynamic>();

          if (_isRampNewPurchaseMessage(dataJson)) {
            purchaseStartedController.add(dataJson);
          }
        } catch (e) {
          purchaseStartedController.addError(e);
        }
      }
    }

    final handler = handlerFunction;

    try {
      web.window.addEventListener('message', handler.toJS);

      yield* purchaseStartedController.stream;
    } catch (e) {
      purchaseStartedController.addError(e);
    } finally {
      web.window.removeEventListener('message', handler.toJS);

      if (!purchaseStartedController.isClosed) {
        await purchaseStartedController.close();
      }
    }
  }

  /// Checks if the JS message is a new Ramp purchase message.
  bool _isRampNewPurchaseMessage(Map data) {
    return data.containsKey('type') && data['type'] == 'PURCHASE_CREATED';
  }

  void _cleanup() {
    _isDisposed = true;
    // Close any other resources if necessary
  }

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw Exception('RampOrderWatcher has already been disposed');
    }
  }

  static Future<FiatOrderStatus> _getPurchaseStatus(
    RampPurchaseDetails purchase,
  ) async {
    final response = await http.get(purchase.purchaseUrl);

    if (response.statusCode != 200) {
      throw Exception('Could not get Ramp purchase status');
    }

    final data = json.decode(response.body) as _JsonMap;
    final rampStatus = data['status'] as String;
    final status = _mapRampStatusToFiatOrderStatus(rampStatus);
    if (status != null) {
      return status;
    } else {
      throw Exception('Could not parse Ramp status: $rampStatus');
    }
  }

  static FiatOrderStatus? _mapRampStatusToFiatOrderStatus(String rampStatus) {
    // See here for all possible statuses:
    // https://docs.ramp.network/sdk-reference#on-ramp-purchase-status
    switch (rampStatus) {
      case 'INITIALIZED':
      case 'PAYMENT_STARTED':
      case 'PAYMENT_IN_PROGRESS':
        return FiatOrderStatus.pending;

      case 'FIAT_SENT':
      case 'FIAT_RECEIVED':
      case 'RELEASING':
        return FiatOrderStatus.inProgress;
      case 'PAYMENT_EXECUTED':
      case 'RELEASED':
        return FiatOrderStatus.success;
      case 'PAYMENT_FAILED':
      case 'EXPIRED':
      case 'CANCELLED':
        return FiatOrderStatus.failed;
      default:
        return null;
    }
  }
}

typedef _JsonMap = Map<String, dynamic>;

class RampPurchaseDetails {
  RampPurchaseDetails({
    required this.orderId,
    required this.apiUrl,
    required this.purchaseViewToken,
  });

  final String orderId;
  final String apiUrl;
  final String purchaseViewToken;

  Uri get purchaseUrl =>
      Uri.parse('$apiUrl/host-api/purchase/$orderId?secret=$purchaseViewToken');

  static RampPurchaseDetails? tryFromMessage(Map<String, dynamic> message) {
    if (!message.containsKey('type') || message['type'] != 'PURCHASE_CREATED') {
      return null;
    }

    try {
      final payload = message['payload'] as Map;
      final Map<String, dynamic> purchase = Map<String, dynamic>.from(
        payload['purchase'] as Map,
      );
      final String purchaseViewToken = payload['purchaseViewToken'] as String;
      final String apiUrl = payload['apiUrl'] as String;
      final String orderId = purchase['id'] as String;

      return RampPurchaseDetails(
        orderId: orderId,
        apiUrl: apiUrl,
        purchaseViewToken: purchaseViewToken,
      );
    } catch (e) {
      debugPrint('RampOrderWatcher: Error parsing RampPurchaseDetails: $e');
      return null;
    }
  }

  //==== RampPurchase MESSAGE FORMAT:
  // {
  //   type: 'PURCHASE_CREATED',
  //   payload: {
  //     purchase: RampPurchase,
  //     purchaseViewToken: string,
  //     apiUrl: string
  //   },
  //   widgetInstanceId: string,
  // }

  //==== RampPurchase MESSAGE EXAMPLE:
  // {
  //     "type": "PURCHASE_CREATED",
  //     "payload": {
  //         "purchase": {
  //             "endTime": "2023-11-26T13:24:20.177Z",
  //             "cryptoAmount": "110724180593676737247",
  //             "fiatCurrency": "GBP",
  //             "fiatValue": 100,
  //             "assetExchangeRateEur": 1,
  //             "fiatExchangeRateEur": 1.1505242363683013,
  //             "baseRampFee": 3.753282987574591,
  //             "networkFee": 0.00869169,
  //             "appliedFee": 3.761974677574591,
  //             "createdAt": "2023-11-23T13:24:20.271Z",
  //             "updatedAt": "2023-11-23T13:24:21.040Z",
  //             "id": "s73gxbn6jotrvqj",
  //             "asset": {
  //                 "address": "0x5248dDdC7857987A2EfD81522AFBA1fCb017A4b7",
  //                 "symbol": "MATIC_TEST",
  //                 "apiV3Symbol": "TEST",
  //                 "name": "Test Token on Polygon Mumbai",
  //                 "decimals": 18,
  //                 "type": "MATIC_ERC20",
  //                 "apiV3Type": "ERC20",
  //                 "chain": "MATIC"
  //             },
  //             "receiverAddress": "0xbbabc29087c7ef37a59da76896d7740a43dcb371",
  //             "assetExchangeRate": 0.869169,
  //             "purchaseViewToken": "56grvvsvu3mae27t",
  //             "status": "INITIALIZED",
  //             "paymentMethodType": "CARD_PAYMENT"
  //         },
  //         "purchaseViewToken": "56grvvsvu3mae27t",
  //         "apiUrl": "https://api.demo.ramp.network/api"
  //     },
  //     "widgetInstanceId": "KNWgVtLoPwMM0v2sllOeE"
  // }
}
