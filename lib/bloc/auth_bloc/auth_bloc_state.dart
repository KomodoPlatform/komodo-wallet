part of 'auth_bloc.dart';

class AuthBlocState extends Equatable {
  const AuthBlocState({
    required this.mode,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  factory AuthBlocState.initial() =>
      const AuthBlocState(mode: AuthorizeMode.noLogin);
  factory AuthBlocState.loading() =>
      const AuthBlocState(mode: AuthorizeMode.noLogin, isLoading: true);
  factory AuthBlocState.error(String errorMessage) => AuthBlocState(
        mode: AuthorizeMode.noLogin,
        errorMessage: errorMessage,
      );
  factory AuthBlocState.loggedIn(KdfUser user) => AuthBlocState(
        mode: AuthorizeMode.logIn,
        currentUser: user,
      );

  final KdfUser? currentUser;
  final AuthorizeMode mode;
  final bool isLoading;
  final String? errorMessage;

  bool get isSignedIn => currentUser != null;

  @override
  List<Object?> get props => [mode, currentUser, isLoading, errorMessage];
}
