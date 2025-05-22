import 'package:easy_localization/easy_localization.dart';
import 'package:web/web.dart';
import 'package:web_dex/bloc/auth_bloc/auth_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/auth_checker/auth_checker.dart';

const _appCloseCommandKey = 'web_dex_command';

class WebAuthChecker implements AuthChecker {
  WebAuthChecker({required AuthRepository authRepo}) : _authRepo = authRepo {
    _initListeners();
  }

  String? _currentSeed;
  final AuthRepository _authRepo;

  @override
  Future<bool> askConfirmLoginIfNeeded(String encryptedSeed) async {
    final String localStorageValue = window.localStorage[encryptedSeed] ?? '0';
    final isLoggedIn = int.tryParse(localStorageValue) ?? 0;
    if (isLoggedIn == 0) {
      return true;
    }

    final confirmAnswer = window.confirm(
      LocaleKeys.confirmLogoutOnAnotherTab.tr(),
    );
    if (confirmAnswer) {
      window.localStorage[_appCloseCommandKey] = encryptedSeed;
      window.localStorage.remove(_appCloseCommandKey);

      _currentSeed = encryptedSeed;
      return true;
    }

    return false;
  }

  @override
  void removeSession(String encryptedSeed) {
    if (_currentSeed == encryptedSeed) {
      window.localStorage.remove(encryptedSeed);
      _currentSeed = null;
    }
  }

  @override
  void addSession(String encryptedSeed) {
    window.localStorage.addAll({encryptedSeed: '1'});
    _currentSeed = encryptedSeed;
  }

  void _initListeners() {
    window.addEventListener('storage', _onStorageListener.toJS);

    window.addEventListener('beforeunload', _onBeforeUnloadListener.toJS);
  }

  Future<void> _onStorageListener(Event event) async {
    if (event is! StorageEvent) return;

    if (event.key != _appCloseCommandKey) {
      return;
    }

    if (event.newValue != null && event.newValue == _currentSeed) {
      _currentSeed = null;
      await _authRepo.logOut();
    }
  }

  void _onBeforeUnloadListener(Event event) {
    if (event is! BeforeUnloadEvent) return;
    final currentSeed = _currentSeed;
    if (currentSeed != null) {
      removeSession(currentSeed);
    }
  }
}
