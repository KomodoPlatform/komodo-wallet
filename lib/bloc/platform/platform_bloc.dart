import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/platform/platform_event.dart';
import 'package:web_dex/bloc/platform/platform_state.dart';
import 'package:web_dex/services/platform_info/platform_info.dart';

class PlatformBloc extends Bloc<PlatformEvent, PlatformState> {
  PlatformBloc({
    PlatformInfo? platformInfo,
  })  : _platformInfo = platformInfo ?? PlatformInfo.getInstance(),
        super(const PlatformState()) {
    on<PlatformInitRequested>(_onPlatformInitRequested);
  }

  final PlatformInfo _platformInfo;

  Future<void> _onPlatformInitRequested(
    PlatformInitRequested event,
    Emitter<PlatformState> emit,
  ) async {
    emit(state.copyWith(status: PlatformBlocStatus.loading));

    try {
      final platformType = await _platformInfo.platformType;
      emit(
        state.copyWith(
          status: PlatformBlocStatus.success,
          platformType: platformType,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: PlatformBlocStatus.failure,
          platformType: PlatformType.unknown,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
