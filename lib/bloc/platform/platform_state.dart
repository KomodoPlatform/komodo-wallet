import 'package:equatable/equatable.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';

enum PlatformBlocStatus {
  initial,
  loading,
  success,
  failure,
}

class PlatformState extends Equatable {
  const PlatformState({
    this.status = PlatformBlocStatus.initial,
    this.platformType = PlatformType.unknown,
    this.errorMessage,
  });

  final PlatformBlocStatus status;
  final PlatformType platformType;
  final String? errorMessage;

  /// Checks if the current platform is supported for Trezor
  ///
  /// Trezor is supported on:
  /// - Chrome browser (web)
  /// - Desktop platforms (Windows, macOS, Linux)
  /// - Mobile platforms (Android, iOS)
  ///
  /// Trezor is NOT supported on:
  /// - Brave browser (explicitly disabled due to security restrictions
  /// and known issues)
  /// - Other web browsers (Firefox, Safari, Opera, etc.)
  bool get isTrezorSupported {
    switch (platformType) {
      // Supported platforms
      case PlatformType.chrome:
      case PlatformType.edge:
      case PlatformType.windows:
      case PlatformType.mac:
      case PlatformType.linux:
      case PlatformType.android:
      case PlatformType.ios:
        return true;

      // Explicitly unsupported platforms
      case PlatformType.brave:
      case PlatformType.firefox:
      case PlatformType.safari:
      case PlatformType.opera:
        return false;

      // Unknown platforms default to supported (fail-safe approach)
      case PlatformType.unknown:
        return true;
    }
  }

  PlatformState copyWith({
    PlatformBlocStatus? status,
    PlatformType? platformType,
    String? errorMessage,
  }) {
    return PlatformState(
      status: status ?? this.status,
      platformType: platformType ?? this.platformType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, platformType, errorMessage];
}
