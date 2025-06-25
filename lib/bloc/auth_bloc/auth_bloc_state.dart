part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
  trezorInitializing,
  trezorAwaitingConfirmation,
  trezorPinRequired,
  trezorPassphraseRequired,
  trezorReady,
}

class AuthBlocState extends Equatable {
  const AuthBlocState({
    required this.mode,
    this.currentUser,
    this.status = AuthStatus.initial,
    this.authError,
    this.message,
    this.taskId,
  });

  factory AuthBlocState.initial() =>
      const AuthBlocState(mode: AuthorizeMode.noLogin);
  factory AuthBlocState.loading() => const AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.loading,
      );
  factory AuthBlocState.error(AuthException authError) => AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.failure,
        authError: authError,
      );
  factory AuthBlocState.loggedIn(KdfUser user) => AuthBlocState(
        mode: AuthorizeMode.logIn,
        status: AuthStatus.success,
        currentUser: user,
      );
  factory AuthBlocState.trezorInitializing({String? message, int? taskId}) =>
      AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.trezorInitializing,
        message: message,
        taskId: taskId,
      );
  factory AuthBlocState.trezorAwaitingConfirmation(
          {String? message, int? taskId}) =>
      AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.trezorAwaitingConfirmation,
        message: message,
        taskId: taskId,
      );
  factory AuthBlocState.trezorPinRequired(
          {String? message, required int taskId}) =>
      AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.trezorPinRequired,
        message: message,
        taskId: taskId,
      );
  factory AuthBlocState.trezorPassphraseRequired(
          {String? message, required int taskId}) =>
      AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.trezorPassphraseRequired,
        message: message,
        taskId: taskId,
      );
  factory AuthBlocState.trezorReady() => const AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.trezorReady,
      );

  final KdfUser? currentUser;
  final AuthorizeMode mode;
  final AuthStatus status;
  final AuthException? authError;
  final String? message;
  final int? taskId;

  bool get isSignedIn => currentUser != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.failure;

  @override
  List<Object?> get props =>
      [mode, currentUser, status, authError, message, taskId];
}
