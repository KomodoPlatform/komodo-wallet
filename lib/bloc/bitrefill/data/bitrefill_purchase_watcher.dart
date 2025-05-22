import 'dart:async';
import 'dart:convert';

import 'package:web/web.dart' as web;
import 'package:web_dex/bloc/bitrefill/models/bitrefill_payment_intent_event.dart';

class BitrefillPurchaseWatcher {
  bool _isDisposed = false;

  /// Watches for the payment intent event from the Bitrefill checkout page
  /// using a [scheduleMicrotask] to listen for events asynchronously.
  ///
  /// NB: This will only work if the Bitrefill page was opened from the app -
  /// similar to [RampPurchaseWatcher]. JavaScript's `window.opener.postMessage`
  /// is used to send the payment intent data to the app.
  /// I.e. If the user copies the checkout URL and opens it in a new tab,
  /// we will not receive events.
  Stream<BitrefillPaymentIntentEvent> watchPaymentIntent() {
    _assertNotDisposed();

    final StreamController<BitrefillPaymentIntentEvent> controller =
        StreamController<BitrefillPaymentIntentEvent>();
    scheduleMicrotask(() async {
      final Stream<Map<String, dynamic>> stream = watchBitrefillPaymentIntent()
          .takeWhile((Map<String, dynamic> element) => !controller.isClosed);
      try {
        await for (final Map<String, dynamic> event in stream) {
          final BitrefillPaymentIntentEvent paymentIntentEvent =
              BitrefillPaymentIntentEvent.fromJson(event);
          controller.add(paymentIntentEvent);
        }
      } catch (e) {
        controller.addError(e);
      } finally {
        _cleanup();
      }
    });

    return controller.stream;
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

  /// Watches for the payment intent event from the Bitrefill checkout page.
  ///
  /// NB: This will only work if the Bitrefill page was opened from the app -
  /// similar to [RampPurchaseWatcher]. JavaScript's `window.opener.postMessage`
  /// is used to send the payment intent data to the app.
  /// I.e. If the user copies the checkout URL and opens it in a new tab,
  /// we will not receive events.
  Stream<Map<String, dynamic>> watchBitrefillPaymentIntent() async* {
    final StreamController<Map<String, dynamic>> paymentIntentsController =
        StreamController<Map<String, dynamic>>();

    void handlerFunction(web.Event event) {
      if (paymentIntentsController.isClosed) {
        return;
      }
      final web.MessageEvent messageEvent = event as web.MessageEvent;
      if (messageEvent.data is String) {
        try {
          // TODO(Francois): convert to a model here (payment intent or invoice created atm)
          final Map<String, dynamic> dataJson =
              jsonDecode(messageEvent.data as String) as Map<String, dynamic>;
          paymentIntentsController.add(dataJson);
        } catch (e) {
          paymentIntentsController.addError(e);
        }
      }
    }

    try {
      web.window.addEventListener('message', handlerFunction.toJS);

      yield* paymentIntentsController.stream;
    } catch (e) {
      paymentIntentsController.addError(e);
    } finally {
      web.window.removeEventListener('message', handlerFunction.toJS);

      if (!paymentIntentsController.isClosed) {
        await paymentIntentsController.close();
      }
    }
  }
}
