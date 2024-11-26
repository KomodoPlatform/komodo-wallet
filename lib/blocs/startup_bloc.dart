import 'dart:async';

import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/coins_service/coins_service.dart';
import 'package:web_dex/shared/utils/utils.dart';

StartUpBloc startUpBloc = StartUpBloc();

class StartUpBloc implements BlocBase {
  bool _running = false;

  @override
  void dispose() {
    _runningController.close();
  }

  final StreamController<bool> _runningController =
      StreamController<bool>.broadcast();
  Sink<bool> get _inRunning => _runningController.sink;
  Stream<bool> get outRunning => _runningController.stream;

  bool get running => _running;
  set running(bool value) {
    _running = value;
    _inRunning.add(_running);
  }

  Future<void> run() async {
    await mm2.init();
    final wasAlreadyRunning = running;

    authRepo.authMode.listen((event) {
      makerFormBloc.onChangeAuthStatus(event);
    });
    coinsService.init();
    coinsBloc.subscribeOnPrice(cexService);
    running = true;
    tradingEntitiesBloc.runUpdate();
    routingState.selectedMenu = MainMenuValue.dex;
    if (!wasAlreadyRunning) await authRepo.logIn(AuthorizeMode.noLogin);

    log('Application has started');
  }
}
