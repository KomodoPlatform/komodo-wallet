part of 'trezor_init_bloc.dart';

class TrezorInitState extends Equatable {
  const TrezorInitState({
    required this.taskId,
    required this.status,
    this.kdfUser,
    this.error,
    required this.inProgress,
  });
  static TrezorInitState initial() => const TrezorInitState(
        taskId: null,
        kdfUser: null,
        error: null,
        status: null,
        inProgress: false,
      );

  TrezorInitState copyWith({
    int? Function()? taskId,
    KdfUser? kdfUser,
    TextError? Function()? error,
    InitTrezorStatusData? Function()? status,
    bool Function()? inProgress,
  }) =>
      TrezorInitState(
        taskId: taskId != null ? taskId() : this.taskId,
        kdfUser: kdfUser ?? this.kdfUser,
        status: status != null ? status() : this.status,
        error: error != null ? error() : this.error,
        inProgress: inProgress != null ? inProgress() : this.inProgress,
      );

  final int? taskId;
  final InitTrezorStatusData? status;
  final TextError? error;
  final bool inProgress;
  final KdfUser? kdfUser;

  @override
  List<Object?> get props => [taskId, kdfUser, status, error, inProgress];
}
