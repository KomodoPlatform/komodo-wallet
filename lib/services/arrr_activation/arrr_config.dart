import 'package:equatable/equatable.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';

/// ARRR activation result for Future-based API
abstract class ArrrActivationResult {
  const ArrrActivationResult();

  T when<T>({
    required T Function(Stream<ActivationProgress> progress) success,
    required T Function(
      String coinId,
      List<ActivationSettingDescriptor> requiredSettings,
    )
    needsConfiguration,
    required T Function(String message) error,
  }) {
    if (this is ArrrActivationResultSuccess) {
      final self = this as ArrrActivationResultSuccess;
      return success(self.progress);
    } else if (this is ArrrActivationResultNeedsConfig) {
      final self = this as ArrrActivationResultNeedsConfig;
      return needsConfiguration(self.coinId, self.requiredSettings);
    } else if (this is ArrrActivationResultError) {
      final self = this as ArrrActivationResultError;
      return error(self.message);
    }
    throw StateError('Unknown ArrrActivationResult type: $runtimeType');
  }
}

class ArrrActivationResultSuccess extends ArrrActivationResult {
  const ArrrActivationResultSuccess(this.progress);

  final Stream<ActivationProgress> progress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArrrActivationResultSuccess && other.progress == progress;
  }

  @override
  int get hashCode => progress.hashCode;
}

class ArrrActivationResultNeedsConfig extends ArrrActivationResult {
  const ArrrActivationResultNeedsConfig({
    required this.coinId,
    required this.requiredSettings,
  });

  final String coinId;
  final List<ActivationSettingDescriptor> requiredSettings;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArrrActivationResultNeedsConfig &&
        other.coinId == coinId &&
        other.requiredSettings == requiredSettings;
  }

  @override
  int get hashCode => Object.hash(coinId, requiredSettings);
}

class ArrrActivationResultError extends ArrrActivationResult {
  const ArrrActivationResultError(this.message);

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArrrActivationResultError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// ARRR activation status for UI caching
abstract class ArrrActivationStatus extends Equatable {
  const ArrrActivationStatus();

  T when<T>({
    required T Function(
      AssetId assetId,
      DateTime startTime,
      int? progressPercentage,
      ActivationStep? currentStep,
      String? statusMessage,
    )
    inProgress,
    required T Function(AssetId assetId, DateTime completionTime) completed,
    required T Function(
      AssetId assetId,
      String errorMessage,
      DateTime errorTime,
    )
    error,
  }) {
    if (this is ArrrActivationStatusInProgress) {
      final self = this as ArrrActivationStatusInProgress;
      return inProgress(
        self.assetId,
        self.startTime,
        self.progressPercentage,
        self.currentStep,
        self.statusMessage,
      );
    } else if (this is ArrrActivationStatusCompleted) {
      final self = this as ArrrActivationStatusCompleted;
      return completed(self.assetId, self.completionTime);
    } else if (this is ArrrActivationStatusError) {
      final self = this as ArrrActivationStatusError;
      return error(self.assetId, self.errorMessage, self.errorTime);
    }
    throw StateError('Unknown ArrrActivationStatus type: $runtimeType');
  }
}

class ArrrActivationStatusInProgress extends ArrrActivationStatus {
  const ArrrActivationStatusInProgress({
    required this.assetId,
    required this.startTime,
    this.progressPercentage,
    this.currentStep,
    this.statusMessage,
  });

  final AssetId assetId;
  final DateTime startTime;
  final int? progressPercentage;
  final ActivationStep? currentStep;
  final String? statusMessage;

  ArrrActivationStatusInProgress copyWith({
    AssetId? assetId,
    DateTime? startTime,
    int? progressPercentage,
    ActivationStep? currentStep,
    String? statusMessage,
  }) {
    return ArrrActivationStatusInProgress(
      assetId: assetId ?? this.assetId,
      startTime: startTime ?? this.startTime,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      currentStep: currentStep ?? this.currentStep,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [
    assetId,
    startTime,
    progressPercentage,
    currentStep,
    statusMessage,
  ];
}

class ArrrActivationStatusCompleted extends ArrrActivationStatus {
  const ArrrActivationStatusCompleted({
    required this.assetId,
    required this.completionTime,
  });

  final AssetId assetId;
  final DateTime completionTime;

  @override
  List<Object?> get props => [assetId, completionTime];
}

class ArrrActivationStatusError extends ArrrActivationStatus {
  const ArrrActivationStatusError({
    required this.assetId,
    required this.errorMessage,
    required this.errorTime,
  });

  final AssetId assetId;
  final String errorMessage;
  final DateTime errorTime;

  @override
  List<Object?> get props => [assetId, errorMessage, errorTime];
}
