import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/shared/utils/password.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/trezor_bloc/trezor_repo.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor/init_trezor_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trezor/init/init_trezor_status/init_trezor_status_response.dart';
import 'package:web_dex/model/hw_wallet/init_trezor.dart';
import 'package:web_dex/model/hw_wallet/trezor_status.dart';
import 'package:web_dex/model/hw_wallet/trezor_status_error.dart';
import 'package:web_dex/model/hw_wallet/trezor_task.dart';
import 'package:web_dex/model/kdf_auth_metadata_extension.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/model/wallet.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:komodo_defi_rpc_methods/komodo_defi_rpc_methods.dart'
    show PrivateKeyPolicy;

part 'trezor_init_event.dart';
part 'trezor_init_state.dart';

const String _trezorPasswordKey = 'trezor_wallet_password';

class TrezorInitBloc extends Bloc<TrezorInitEvent, TrezorInitState> {
  TrezorInitBloc({
    required KomodoDefiSdk kdfSdk,
    required TrezorRepo trezorRepo,
    required CoinsRepo coinsRepository,
    FlutterSecureStorage? secureStorage,
  })  : _trezorRepo = trezorRepo,
        _kdfSdk = kdfSdk,
        _coinsRepository = coinsRepository,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(TrezorInitState.initial()) {
    on<TrezorInitSubscribeStatus>(_onSubscribeStatus);
    on<TrezorInit>(_onInit);
    on<TrezorInitReset>(_onReset);
    on<TrezorInitUpdateStatus>(_onUpdateStatus);
    on<TrezorInitSuccess>(_onInitSuccess);
    on<TrezorInitSendPin>(_onSendPin);
    on<TrezorInitSendPassphrase>(_onSendPassphrase);
    on<TrezorInitUpdateAuthMode>(_onAuthModeChange);

    _authorizationSubscription = _kdfSdk.auth.watchCurrentUser().listen((user) {
      add(TrezorInitUpdateAuthMode(user));
    });
  }

  late StreamSubscription<KdfUser?> _authorizationSubscription;
  final TrezorRepo _trezorRepo;
  final KomodoDefiSdk _kdfSdk;
  final CoinsRepo _coinsRepository;
  final FlutterSecureStorage _secureStorage;
  Timer? _statusTimer;

  void _unsubscribeStatus() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  bool _checkAndHandleSuccess(InitTrezorStatusData status) {
    final InitTrezorStatus trezorStatus = status.trezorStatus;
    final TrezorDeviceDetails? deviceDetails = status.details.deviceDetails;

    if (trezorStatus == InitTrezorStatus.ok && deviceDetails != null) {
      add(TrezorInitSuccess(status));
      return true;
    }

    return false;
  }

  Future<void> _onInit(TrezorInit event, Emitter<TrezorInitState> emit) async {
    if (state.inProgress) return;
    emit(state.copyWith(inProgress: () => true));
    try {
      // device status isn't available until after trezor init completes, but
      // requires kdf to be running with a seed value.
      // Alternative is to use a static 'hidden-login' to init trezor, then logout
      // and log back in to another account using the obtained trezor device
      // details
      await _loginToTrezorWallet();
    } catch (e, s) {
      log(
        'Failed to login to hidden mode: $e',
        path: 'trezor_init_bloc => _loginToHiddenMode',
        isError: true,
        trace: s,
      ).ignore();
      emit(
        state.copyWith(
          error: () => TextError(error: LocaleKeys.somethingWrong.tr()),
          inProgress: () => false,
        ),
      );
      return;
    }

    final InitTrezorRes response = await _trezorRepo.init();
    final String? responseError = response.error;
    final InitTrezorResult? responseResult = response.result;

    if (responseError != null) {
      emit(
        state.copyWith(
          error: () => TextError(error: responseError),
          inProgress: () => false,
        ),
      );
      await _logout();
      return;
    }
    if (responseResult == null) {
      emit(
        state.copyWith(
          error: () => TextError(error: LocaleKeys.somethingWrong.tr()),
          inProgress: () => false,
        ),
      );
      await _logout();
      return;
    }

    add(const TrezorInitSubscribeStatus());
    emit(
      state.copyWith(
        taskId: () => responseResult.taskId,
        inProgress: () => false,
      ),
    );
  }

  Future<void> _onSubscribeStatus(
    TrezorInitSubscribeStatus event,
    Emitter<TrezorInitState> emit,
  ) async {
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      add(const TrezorInitUpdateStatus());
    });
  }

  FutureOr<void> _onUpdateStatus(
    TrezorInitUpdateStatus event,
    Emitter<TrezorInitState> emit,
  ) async {
    final int? taskId = state.taskId;
    if (taskId == null) return;

    final InitTrezorStatusRes response = await _trezorRepo.initStatus(taskId);

    if (response.errorType == 'NoSuchTask') {
      _unsubscribeStatus();
      emit(state.copyWith(taskId: () => null));
      await _logout();
      return;
    }

    final String? responseError = response.error;

    if (responseError != null) {
      emit(state.copyWith(error: () => TextError(error: responseError)));
      await _logout();
      return;
    }

    final InitTrezorStatusData? initTrezorStatus = response.result;
    if (initTrezorStatus == null) {
      emit(
        state.copyWith(
          error: () =>
              TextError(error: 'Something went wrong. Empty init status.'),
        ),
      );

      await _logout();
      return;
    }

    if (!_checkAndHandleSuccess(initTrezorStatus)) {
      emit(state.copyWith(status: () => initTrezorStatus));
    }

    if (_checkAndHandleInvalidPin(initTrezorStatus)) {
      emit(state.copyWith(taskId: () => null));
      _unsubscribeStatus();
    }
  }

  Future<void> _onInitSuccess(
    TrezorInitSuccess event,
    Emitter<TrezorInitState> emit,
  ) async {
    _unsubscribeStatus();
    final deviceDetails = event.status.details.deviceDetails!;

    // final String name = deviceDetails.name ?? 'My Trezor';

    try {
      await _coinsRepository
          .deactivateCoinsSync(await _coinsRepository.getEnabledCoins());
    } catch (e) {
      // ignore
    }
    _trezorRepo.subscribeOnConnectionStatus(deviceDetails.pubKey);
    emit(
      state.copyWith(
        inProgress: () => false,
        kdfUser: await _kdfSdk.auth.currentUser,
        status: () => event.status,
      ),
    );
  }

  Future<void> _onSendPin(
    TrezorInitSendPin event,
    Emitter<TrezorInitState> emit,
  ) async {
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
    TrezorInitSendPassphrase event,
    Emitter<TrezorInitState> emit,
  ) async {
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
    TrezorInitReset event,
    Emitter<TrezorInitState> emit,
  ) async {
    _unsubscribeStatus();
    final taskId = state.taskId;

    if (taskId != null) {
      await _trezorRepo.initCancel(taskId);
    }
    _logout();
    emit(
      state.copyWith(
        taskId: () => null,
        status: () => null,
        error: () => null,
      ),
    );
  }

  FutureOr<void> _onAuthModeChange(
    TrezorInitUpdateAuthMode event,
    Emitter<TrezorInitState> emit,
  ) {
    emit(state.copyWith(kdfUser: event.kdfUser));
  }

  /// KDF has to be running with a seed/wallet to init a trezor, so this signs
  /// into a static 'hidden' wallet to init trezor
  Future<void> _loginToTrezorWallet({
    String walletName = 'My Trezor',
    String? password,
    AuthOptions authOptions = const AuthOptions(
      derivationMethod: DerivationMethod.hdWallet,
      privKeyPolicy: PrivateKeyPolicy.trezor(),
    ),
  }) async {
    try {
      password ??= await _secureStorage.read(key: _trezorPasswordKey);
    } catch (e, s) {
      log(
        'Failed to read trezor password from secure storage: $e',
        path: 'trezor_init_bloc => _loginToTrezorWallet',
        isError: true,
        trace: s,
      ).ignore();
      // If reading fails, password will remain null and a new one will be generated
    }

    if (password == null) {
      password = generatePassword();
      try {
        await _secureStorage.write(key: _trezorPasswordKey, value: password);
      } catch (e, s) {
        log(
          'Failed to write trezor password to secure storage: $e',
          path: 'trezor_init_bloc => _loginToTrezorWallet',
          isError: true,
          trace: s,
        ).ignore();
        // Continue with generated password even if storage write fails
      }
    }

    final bool mm2SignedIn = await _kdfSdk.auth.isSignedIn();
    if (state.kdfUser != null && mm2SignedIn) {
      return;
    }

    final existingWallets = await _kdfSdk.auth.getUsers();
    if (existingWallets.any((wallet) => wallet.walletId.name == walletName)) {
      await _kdfSdk.auth.signIn(
        walletName: walletName,
        password: password,
        options: authOptions,
      );
      await _kdfSdk.setWalletType(WalletType.trezor);
      await _kdfSdk.confirmSeedBackup();
      await _kdfSdk.addActivatedCoins(enabledByDefaultTrezorCoins);
      return;
    }

    await _kdfSdk.auth.register(
      walletName: walletName,
      password: password,
      options: authOptions,
    );
    await _kdfSdk.setWalletType(WalletType.trezor);
    await _kdfSdk.confirmSeedBackup();
    await _kdfSdk.addActivatedCoins(enabledByDefaultTrezorCoins);
  }

  Future<void> _logout() async {
    final bool isSignedIn = await _kdfSdk.auth.isSignedIn();
    if (!isSignedIn && state.kdfUser == null) {
      return;
    }

    await _kdfSdk.auth.signOut();
  }

  bool _checkAndHandleInvalidPin(InitTrezorStatusData status) {
    if (status.trezorStatus != InitTrezorStatus.error) return false;
    if (status.details.errorDetails == null) return false;
    if (status.details.errorDetails!.errorData !=
        TrezorStatusErrorData.invalidPin) {
      return false;
    }

    return true;
  }

  @override
  Future<void> close() async {
    _unsubscribeStatus();
    await _authorizationSubscription.cancel();
    return super.close();
  }
}
