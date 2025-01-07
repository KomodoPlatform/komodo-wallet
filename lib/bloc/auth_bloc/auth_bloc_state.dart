part of 'auth_bloc.dart';

class AuthBlocState extends Equatable {
  const AuthBlocState({required this.mode, this.currentUser});

  factory AuthBlocState.initial() =>
      const AuthBlocState(mode: AuthorizeMode.noLogin);

  final KdfUser? currentUser;
  final AuthorizeMode mode;

  bool get isSignedIn => currentUser != null;

  @override
  List<Object?> get props => [mode, currentUser];
}
