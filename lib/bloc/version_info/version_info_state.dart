part of 'version_info_bloc.dart';

abstract class VersionInfoState extends Equatable {
  const VersionInfoState();
}

class VersionInfoInitial extends VersionInfoState {
  const VersionInfoInitial();

  @override
  List<Object?> get props => [];
}

class VersionInfoLoading extends VersionInfoState {
  const VersionInfoLoading();

  @override
  List<Object?> get props => [];
}

class VersionInfoLoaded extends VersionInfoState {
  const VersionInfoLoaded({
    required this.appVersion,
    required this.commitHash,
    this.apiCommitHash,
    this.currentCoinsCommit,
    this.latestCoinsCommit,
  });

  final String? appVersion;
  final String? commitHash;
  final String? apiCommitHash;
  final String? currentCoinsCommit;
  final String? latestCoinsCommit;

  VersionInfoLoaded copyWith({
    String? appVersion,
    String? commitHash,
    String? apiCommitHash,
    String? currentCoinsCommit,
    String? latestCoinsCommit,
  }) {
    return VersionInfoLoaded(
      appVersion: appVersion ?? this.appVersion,
      commitHash: commitHash ?? this.commitHash,
      apiCommitHash: apiCommitHash ?? this.apiCommitHash,
      currentCoinsCommit: currentCoinsCommit ?? this.currentCoinsCommit,
      latestCoinsCommit: latestCoinsCommit ?? this.latestCoinsCommit,
    );
  }

  @override
  List<Object?> get props => [
    appVersion,
    commitHash,
    apiCommitHash,
    currentCoinsCommit,
    latestCoinsCommit,
  ];
}

class VersionInfoError extends VersionInfoState {
  const VersionInfoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
