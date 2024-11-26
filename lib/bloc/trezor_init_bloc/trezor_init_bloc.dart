import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/bloc/trezor_init_bloc/trezor_init_event.dart';
import 'package:web_dex/bloc/trezor_init_bloc/trezor_init_state.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor/init_trezor_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor_status/init_trezor_status_response.dart';
import 'package:web_dex/model/authorize_mode.dart';
import 'package:web_dex/model/hw_wallet/init_trezor.dart';
import 'package:web_dex/model/hw_wallet/trezor_status.dart';
import 'package:web_dex/model/hw_wallet/trezor_status_error.dart';
import 'package:web_dex/model/hw_wallet/trezor_task.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/shared/utils/utils.dart';

class TrezorInitBloc extends Bloc<TrezorInitEvent, TrezorInitState> {
  TrezorInitBloc({
    required AuthRepository authRepo,
    required TrezorRepo trezorRepo,
  })  : _trezorRepo = trezorRepo,
        _authRepo = authRepo,
        super(TrezorInitState.initial()) {
    on<TrezorInitSubscribeStatus>(_onSubscribeStatus);
    on<TrezorInit>(_onInit);
    on<TrezorInitReset>(_onReset);
    on<TrezorInitUpdateStatus>(_onUpdateStatus);
    on<TrezorInitSuccess>(_onInitSuccess);
    on<TrezorInitSendPin>(_onSendPin);
    on<TrezorInitSendPassphrase>(_onSendPassphrase);
    on<TrezorInitUpdateAuthMode>(_onAuthModeChange);

    _authorizationSubscription = _authRepo.authMode.listen((event) {
      add(TrezorInitUpdateAuthMode(event));
    });
  }

  late StreamSubscription<AuthorizeMode> _authorizationSubscription;
  final TrezorRepo _trezorRepo;
  final AuthRepository _authRepo;
  Timer? _statusTimer;

  void _unsubscribeStatus() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  void _checkAndHandleSuccess(InitTrezorStatusData status) {
    final InitTrezorStatus trezorStatus = status.trezorStatus;
    final TrezorDeviceDetails? deviceDetails = status.details.deviceDetails;

    if (trezorStatus == InitTrezorStatus.ok && deviceDetails != null) {
      add(TrezorInitSuccess(deviceDetails));
    }
  }

  Future<void> _onInit(TrezorInit event, Emitter<TrezorInitState> emit) async {
    if (state.inProgress) return;
    emit(state.copyWith(inProgress: () => true));
    await _loginToHiddenMode();

    final InitTrezorRes response = await _trezorRepo.init();
    final String? responseError = response.error;
    final InitTrezorResult? responseResult = response.result;

    if (responseError != null) {
      emit(state.copyWith(
        error: () => TextError(error: responseError),
        inProgress: () => false,
      ));
      await _logoutFromHiddenMode();
      return;
    }
    if (responseResult == null) {
      emit(state.copyWith(
        error: () => TextError(error: LocaleKeys.somethingWrong.tr()),
        inProgress: () => false,
      ));
      await _logoutFromHiddenMode();
      return;
    }

    add(const TrezorInitSubscribeStatus());
    emit(state.copyWith(
      taskId: () => responseResult.taskId,
      inProgress: () => false,
    ));
  }

  Future<void> _onSubscribeStatus(
      TrezorInitSubscribeStatus event, Emitter<TrezorInitState> emit) async {
    add(const TrezorInitUpdateStatus());
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      add(const TrezorInitUpdateStatus());
    });
  }

  FutureOr<void> _onUpdateStatus(
      TrezorInitUpdateStatus event, Emitter<TrezorInitState> emit) async {
    final int? taskId = state.taskId;
    if (taskId == null) return;

    final InitTrezorStatusRes response = await _trezorRepo.initStatus(taskId);

    if (response.errorType == 'NoSuchTask') {
      _unsubscribeStatus();
      emit(state.copyWith(taskId: () => null));
      await _logoutFromHiddenMode();
      return;
    }

    final String? responseError = response.error;

    if (responseError != null) {
      emit(state.copyWith(error: () => TextError(error: responseError)));
      await _logoutFromHiddenMode();
      return;
    }

    final InitTrezorStatusData? initTrezorStatus = response.result;
    if (initTrezorStatus == null) {
      emit(state.copyWith(
          error: () =>
              TextError(error: 'Something went wrong. Empty init status.')));

      await _logoutFromHiddenMode();
      return;
    }

    _checkAndHandleSuccess(initTrezorStatus);
    if (_checkAndHandleInvalidPin(initTrezorStatus)) {
      emit(state.copyWith(taskId: () => null));
      _unsubscribeStatus();
    }

    emit(state.copyWith(status: () => initTrezorStatus));
  }

  Future<void> _onInitSuccess(
      TrezorInitSuccess event, Emitter<TrezorInitState> emit) async {
    _unsubscribeStatus();
    final deviceDetails = event.details;

    final String name = deviceDetails.name ?? 'My Trezor';
    final Wallet? wallet = await walletsBloc.importTrezorWallet(
      name: name,
      pubKey: deviceDetails.pubKey,
    );

    if (wallet == null) {
      emit(state.copyWith(
          error: () => TextError(
              error: LocaleKeys.trezorImportFailed.tr(args: [name]))));

      await _logoutFromHiddenMode();
      return;
    }

    await coinsBloc.deactivateWalletCoins();
    currentWalletBloc.wallet = wallet;
    routingState.selectedMenu = MainMenuValue.wallet;
    _authRepo.setAuthMode(AuthorizeMode.logIn);
    _trezorRepo.subscribeOnConnectionStatus(deviceDetails.pubKey);
    rebuildAll(null);
  }

  Future<void> _onSendPin(
      TrezorInitSendPin event, Emitter<TrezorInitState> emit) async {
    final int? taskId = state.taskId;

    if (taskId == null) return;
    await _trezorRepo.sendPin(
      event.pin,
      TrezorTask(
        taskId: taskId,
        type: TrezorTaskType.initTrezor,
      ),
    );
  }

  Future<void> _onSendPassphrase(
      TrezorInitSendPassphrase event, Emitter<TrezorInitState> emit) async {
    final int? taskId = state.taskId;

    if (taskId == null) return;

    await _trezorRepo.sendPassphrase(
      event.passphrase,
      TrezorTask(
        taskId: taskId,
        type: TrezorTaskType.initTrezor,
      ),
    );
  }

  FutureOr<void> _onReset(
      TrezorInitReset event, Emitter<TrezorInitState> emit) async {
    _unsubscribeStatus();
    final taskId = state.taskId;

    if (taskId != null) {
      await _trezorRepo.initCancel(taskId);
    }
    _logoutFromHiddenMode();
    emit(state.copyWith(
      taskId: () => null,
      status: () => null,
      error: () => null,
    ));
  }

  FutureOr<void> _onAuthModeChange(
      TrezorInitUpdateAuthMode event, Emitter<TrezorInitState> emit) {
    emit(state.copyWith(authMode: () => event.authMode));
  }

  Future<void> _loginToHiddenMode() async {
    final bool mm2SignedIn = await mm2.isSignedIn();
    if (state.authMode == AuthorizeMode.hiddenLogin && mm2SignedIn) return;

    if (mm2SignedIn) await _authRepo.logOut();
    await _authRepo.logIn(AuthorizeMode.hiddenLogin, seed: seedForHiddenLogin);
  }

  Future<void> _logoutFromHiddenMode() async {
    final bool mm2SignedIn = await mm2.isSignedIn();

    if (state.authMode != AuthorizeMode.hiddenLogin && mm2SignedIn) return;

    if (mm2SignedIn) await _authRepo.logOut();
    await _authRepo.logIn(AuthorizeMode.noLogin);
  }

  bool _checkAndHandleInvalidPin(InitTrezorStatusData status) {
    if (status.trezorStatus != InitTrezorStatus.error) return false;
    if (status.details.errorDetails == null) return false;
    if (status.details.errorDetails!.errorData !=
        TrezorStatusErrorData.invalidPin) return false;

    return true;
  }

  @override
  Future<void> close() {
    _unsubscribeStatus();
    _authorizationSubscription.cancel();
    _logoutFromHiddenMode();
    return super.close();
  }
}
