import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';

part 'version_info_event.dart';
part 'version_info_state.dart';

class VersionInfoBloc extends Bloc<VersionInfoEvent, VersionInfoState> {
  VersionInfoBloc({
    required Mm2Api mm2Api,
    required KomodoDefiSdk komodoDefiSdk,
  }) : _mm2Api = mm2Api,
       _komodoDefiSdk = komodoDefiSdk,
       super(const VersionInfoInitial()) {
    on<LoadVersionInfo>(_onLoadVersionInfo);
    on<StartPeriodicPolling>(_onStartPeriodicPolling);
    on<StopPeriodicPolling>(_onStopPeriodicPolling);
    _logger.info('VersionInfoBloc initialized');
  }

  final Mm2Api _mm2Api;
  final KomodoDefiSdk _komodoDefiSdk;
  StreamSubscription<void>? _pollSubscription;
  static final Logger _logger = Logger('VersionInfoBloc');
  static const Duration _pollInterval = Duration(minutes: 5);

  Future<void> _onLoadVersionInfo(
    LoadVersionInfo event,
    Emitter<VersionInfoState> emit,
  ) async {
    _logger.info('Loading version information started');
    emit(const VersionInfoLoading());

    try {
      // Get basic app version info
      final appVersion = packageInformation.packageVersion;
      final commitHash =
          _tryParseCommitHash(packageInformation.commitHash) ??
          packageInformation.commitHash;

      _logger.info(
        'Basic app info retrieved - Version: $appVersion, Commit: $commitHash',
      );

      // Initialize with basic info - handle nullable values
      var loadedState = VersionInfoLoaded(
        appVersion: appVersion,
        commitHash: commitHash,
      );

      emit(loadedState);
      _logger.info('Initial state emitted with basic app information');

      // Load API version asynchronously
      try {
        _logger.info('Loading MM2 API version...');
        final apiVersion = await _mm2Api.version();
        final apiCommitHash = _tryParseCommitHash(apiVersion);
        loadedState = loadedState.copyWith(apiCommitHash: apiCommitHash);
        emit(loadedState);
        _logger.info(
          'MM2 API version loaded successfully - Version: $apiVersion, Commit: $apiCommitHash',
        );
      } catch (e) {
        _logger.warning('Failed to load MM2 API version: $e');
        // Continue without API version if it fails
      }

      // Load current and latest coins commits
      try {
        _logger.info('Loading SDK coins commits...');
        final currentCommit = await _komodoDefiSdk.assets.currentCoinsCommit;
        final latestCommit = await _komodoDefiSdk.assets.latestCoinsCommit;
        loadedState = loadedState.copyWith(
          currentCoinsCommit: _tryParseCommitHash(currentCommit),
          latestCoinsCommit: _tryParseCommitHash(latestCommit),
        );
        emit(loadedState);
        _logger.info(
          'SDK coins commits loaded successfully - Current: $currentCommit, Latest: $latestCommit',
        );
      } catch (e) {
        _logger.warning('Failed to load SDK coins commits: $e');
        // Continue without SDK commits if it fails
      }

      _logger.info('Version information loading completed successfully');
    } catch (e) {
      _logger.severe('Failed to load version information: $e');
      emit(VersionInfoError('Failed to load version information: $e'));
    }
  }

  Future<void> _onStartPeriodicPolling(
    StartPeriodicPolling event,
    Emitter<VersionInfoState> emit,
  ) async {
    _logger.info('Starting periodic polling for version updates');

    // Stop any existing subscription
    await _pollSubscription?.cancel();

    // Create periodic stream and emit state updates
    final pollStream = Stream.periodic(_pollInterval)
        .asyncMap((_) async {
          try {
            _logger.fine('Polling for latest commit hash update');
            final latestCommit = await _komodoDefiSdk.assets.latestCoinsCommit;
            final currentCommit =
                await _komodoDefiSdk.assets.currentCoinsCommit;

            final parsedLatest = _tryParseCommitHash(latestCommit);
            final parsedCurrent = _tryParseCommitHash(currentCommit);

            if (state is VersionInfoLoaded) {
              final currentState = state as VersionInfoLoaded;
              if (currentState.latestCoinsCommit != parsedLatest ||
                  currentState.currentCoinsCommit != parsedCurrent) {
                _logger.info(
                  'Commit hash update detected - Current: $parsedCurrent, Latest: $parsedLatest',
                );
                return currentState.copyWith(
                  currentCoinsCommit: parsedCurrent,
                  latestCoinsCommit: parsedLatest,
                );
              }
            }
            return null; // No update needed
          } catch (e) {
            _logger.warning('Failed to poll commit hash updates: $e');
            return null;
          }
        })
        .where((newState) => newState != null)
        .cast<VersionInfoState>();

    emit.forEach(
      pollStream,
      onData: (newState) => newState,
      onError: (error, stackTrace) {
        _logger.severe(
          'Error in periodic polling stream: $error',
          error,
          stackTrace,
        );
        return state; // Return current state on error
      },
    );
  }

  Future<void> _onStopPeriodicPolling(
    StopPeriodicPolling event,
    Emitter<VersionInfoState> emit,
  ) async {
    _logger.info('Stopping periodic polling for version updates');
    await _pollSubscription?.cancel();
    _pollSubscription = null;
  }

  @override
  Future<void> close() async {
    await _pollSubscription?.cancel();
    return super.close();
  }

  String? _tryParseCommitHash(String? result) {
    if (result == null) {
      _logger.fine('Commit hash parsing skipped - input is null');
      return null;
    }

    _logger.fine('Parsing commit hash from: $result');

    final RegExp regExp = RegExp(r'[0-9a-fA-F]{7,40}');
    final Match? match = regExp.firstMatch(result);

    if (match == null) {
      _logger.fine('No valid commit hash pattern found in: $result');
      return null;
    }

    // Only take first 7 characters of the first match
    final parsedHash = match.group(0)?.substring(0, 7);
    _logger.fine(
      'Commit hash parsed successfully: $parsedHash (from: ${match.group(0)})',
    );

    return parsedHash;
  }
}
