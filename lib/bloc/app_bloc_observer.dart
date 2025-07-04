import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    if (kDebugMode) {
      // print(change);
    }

    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    if (kDebugMode) {
      // print(transition);
    }

    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType}: $error', trace: stackTrace, isError: true);

    // ignore: avoid_print
    print('\x1B[31mAppBlocObserver -> onError\x1B[0m');
    // ignore: avoid_print
    print('\x1B[31m${bloc.runtimeType}: $error\x1B[0m');
    // ignore: avoid_print
    print('\x1B[31mTrace: $stackTrace\x1B[0m');

    super.onError(bloc, error, stackTrace);
  }
}
