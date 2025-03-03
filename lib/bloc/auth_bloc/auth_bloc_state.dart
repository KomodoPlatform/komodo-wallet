part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthBlocState extends Equatable {
  const AuthBlocState({
    required this.mode,
    this.currentUser,
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  factory AuthBlocState.initial() =>
      const AuthBlocState(mode: AuthorizeMode.noLogin);
  factory AuthBlocState.loading() => const AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.loading,
      );
  factory AuthBlocState.error(String errorMessage) => AuthBlocState(
        mode: AuthorizeMode.noLogin,
        status: AuthStatus.failure,
        errorMessage: errorMessage,
      );
  factory AuthBlocState.loggedIn(KdfUser user) => AuthBlocState(
        mode: AuthorizeMode.logIn,
        status: AuthStatus.success,
        currentUser: user,
      );

  final KdfUser? currentUser;
  final AuthorizeMode mode;
  final AuthStatus status;
  final String? errorMessage;

  bool get isSignedIn => currentUser != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.failure;

  @override
  List<Object?> get props => [mode, currentUser, status, errorMessage];
}
