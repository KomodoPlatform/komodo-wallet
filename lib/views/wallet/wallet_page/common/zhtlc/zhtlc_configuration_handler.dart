import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show AssetId;
import 'package:web_dex/services/arrr_activation/arrr_activation_service.dart';
import 'package:web_dex/views/wallet/wallet_page/common/zhtlc/zhtlc_configuration_dialog.dart'
    show confirmZhtlcConfiguration;

/// Widget that handles ZHTLC configuration dialogs automatically
/// by listening to ArrrActivationService for configuration requests
class ZhtlcConfigurationHandler extends StatefulWidget {
  const ZhtlcConfigurationHandler({super.key, required this.child});

  final Widget child;

  @override
  State<ZhtlcConfigurationHandler> createState() =>
      _ZhtlcConfigurationHandlerState();
}

class _ZhtlcConfigurationHandlerState extends State<ZhtlcConfigurationHandler> {
  late StreamSubscription<ZhtlcConfigurationRequest> _configRequestSubscription;
  late final ArrrActivationService _arrrActivationService;
  StreamSubscription<AuthBlocState>? _authSubscription;
  final Logger _log = Logger('ZhtlcConfigurationHandler');

  @override
  void initState() {
    super.initState();
    _arrrActivationService = RepositoryProvider.of<ArrrActivationService>(
      context,
    );
    _listenToConfigurationRequests();
    _subscribeToAuthChanges();
  }

  @override
  void dispose() {
    _configRequestSubscription.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenToConfigurationRequests() {
    // Listen to configuration requests from the ArrrActivationService
    _log.info('Setting up configuration request listener');
    _configRequestSubscription = _arrrActivationService.configurationRequests
        .listen(
          (configRequest) {
            _log.info(
              'Received config request for ${configRequest.asset.id.id}',
            );
            if (mounted &&
                !_handlingConfigurations.contains(configRequest.asset.id)) {
              _log.info(
                'Showing configuration dialog for ${configRequest.asset.id.id}',
              );
              _showConfigurationDialog(context, configRequest);
            } else {
              _log.warning(
                'Skipping config request for ${configRequest.asset.id.id} '
                '(mounted: $mounted, already handling: ${_handlingConfigurations.contains(configRequest.asset.id)})',
              );
            }
          },
          onError: (error, stackTrace) {
            _log.severe(
              'Error in configuration request stream',
              error,
              stackTrace,
            );
          },
          onDone: () {
            _log.warning('Configuration request stream closed unexpectedly');
          },
        );
  }

  // Track which configuration requests are already being handled to prevent duplicates
  static final Set<AssetId> _handlingConfigurations = <AssetId>{};

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _showConfigurationDialog(
    BuildContext context,
    ZhtlcConfigurationRequest configRequest,
  ) async {
    _handlingConfigurations.add(configRequest.asset.id);
    _log.info('Starting configuration dialog for ${configRequest.asset.id.id}');

    try {
      if (!mounted || !context.mounted) {
        _log.warning(
          'Context not mounted, cancelling configuration for ${configRequest.asset.id.id}',
        );
        _arrrActivationService.cancelConfiguration(configRequest.asset.id);
        return;
      }

      final config = await confirmZhtlcConfiguration(
        context,
        asset: configRequest.asset,
      );

      if (config != null) {
        _log.info(
          'User provided configuration for ${configRequest.asset.id.id}',
        );
        await _arrrActivationService.submitConfiguration(
          configRequest.asset.id,
          config,
        );
      } else {
        _log.info(
          'User cancelled configuration for ${configRequest.asset.id.id}',
        );
        _arrrActivationService.cancelConfiguration(configRequest.asset.id);
      }
    } catch (e, stackTrace) {
      _log.severe(
        'Error in configuration dialog for ${configRequest.asset.id.id}',
        e,
        stackTrace,
      );
      _arrrActivationService.cancelConfiguration(configRequest.asset.id);
    } finally {
      _handlingConfigurations.remove(configRequest.asset.id);
      _log.info(
        'Finished handling configuration for ${configRequest.asset.id.id}',
      );
    }
  }

  /// Check if the configuration request listener is active
  bool get isListeningToConfigurationRequests =>
      !_configRequestSubscription.isPaused;

  void _subscribeToAuthChanges() {
    _authSubscription = context.read<AuthBloc>().stream.listen((state) {
      if (state.currentUser == null) {
        _handleSignedOut();
      }
    });
  }

  void _handleSignedOut() {
    if (_handlingConfigurations.isEmpty) {
      return;
    }

    _log.info('Auth signed out - clearing pending ZHTLC configuration state');
    final pendingAssetIds = List<AssetId>.of(_handlingConfigurations);
    _handlingConfigurations.clear();

    for (final assetId in pendingAssetIds) {
      _arrrActivationService.cancelConfiguration(assetId);
    }
  }
}
