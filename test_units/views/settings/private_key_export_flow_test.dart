import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_bloc.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_event.dart';
import 'package:web_dex/bloc/security_settings/private_key_export_state.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';
import 'package:web_dex/views/settings/widgets/security_settings/private_key_settings/private_key_export_flow_listener.dart';
import 'package:web_dex/views/settings/widgets/security_settings/private_key_settings/private_key_export_password_dialog.dart';
import 'package:web_dex/views/settings/widgets/security_settings/private_key_settings/private_key_show.dart';
import 'package:web_dex/views/wallet/coin_details/receive/qr_code_address.dart';

import '../../services/security/private_key_export_test_support.dart';

void main() => testPrivateKeyExportFlow();

void testPrivateKeyExportFlow() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Private key export screen lifecycle', () {
    late FakePrivateKeyExportService service;
    late PrivateKeyExportBloc bloc;
    late SecuritySettingsBloc navigation;
    var ownsBloc = false;

    tearDown(() async {
      if (!ownsBloc && !bloc.isClosed) await bloc.close();
      await navigation.close();
      await service.changes.close();
    });

    Future<void> pump(
      WidgetTester tester, {
      bool pending = false,
      bool ownExportBloc = false,
    }) async {
      ownsBloc = ownExportBloc;
      service = FakePrivateKeyExportService();
      if (pending) service.pendingExport = Completer<PrivateKeyExportResult>();
      bloc = PrivateKeyExportBloc(
        service: service,
        delivery: FakePrivateKeyExportDelivery(),
      );
      navigation = SecuritySettingsBloc(
        SecuritySettingsState.initialState(),
        kdfSdk: null,
      );
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          startLocale: const Locale('en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _ExportTestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: MultiBlocProvider(
                providers: [
                  if (ownExportBloc)
                    BlocProvider<PrivateKeyExportBloc>(create: (_) => bloc)
                  else
                    BlocProvider.value(value: bloc),
                  BlocProvider.value(value: navigation),
                ],
                child: const Scaffold(
                  body: PrivateKeyExportFlowListener(
                    child: SingleChildScrollView(child: PrivateKeyShow()),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> ready(WidgetTester tester) async {
      await pump(tester);
      bloc.add(PrivateKeyExportRequested());
      await tester.pumpAndSettle();
      expect(bloc.state.phase, PrivateKeyExportPhase.awaitingPassword);
      expect(find.byType(PrivateKeyExportPasswordDialog), findsOneWidget);
      bloc.add(
        PrivateKeyExportPasswordSubmitted(
          bloc.state.operationId,
          SensitiveString(exportPasswordSentinel),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PrivateKeyExportPasswordDialog), findsNothing);
      expect(bloc.state.phase, PrivateKeyExportPhase.ready);
    }

    testWidgets('explains limited coverage and shows no raw key by default', (
      tester,
    ) async {
      await ready(tester);
      expect(
        find.textContaining('only the currently activated address'),
        findsWidgets,
      );
      expect(find.textContaining('addresses 0–10'), findsOneWidget);
      expect(find.textContaining('still activating'), findsOneWidget);
      expect(find.text(exportKeySentinel), findsNothing);
      expect(
        tester
            .widget<ActionChip>(
              find.byKey(const Key('private-key-export-copy')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'authentication epoch removes an open QR and displayed results',
      (tester) async {
        await ready(tester);
        bloc.add(const PrivateKeyExportVisibilityChanged(true));
        await tester.pumpAndSettle();
        bloc.add(PrivateKeyExportQrRequested(exportTestAsset('BTC'), 0));
        await tester.pumpAndSettle();
        expect(find.byType(QRCodeAddress), findsOneWidget);
        expect(find.text(exportKeySentinel), findsOneWidget);
        service.current = false;
        service.changes.add(null);
        await tester.pumpAndSettle();
        expect(find.byType(QRCodeAddress), findsNothing);
        expect(find.text(exportKeySentinel), findsNothing);
        expect(bloc.state.result, isNull);
        expect(navigation.state.step, SecuritySettingsStep.securityMain);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'cancel during fetch closes only its prompt and ignores late keys',
      (tester) async {
        await pump(tester, pending: true);
        bloc.add(PrivateKeyExportRequested());
        await tester.pumpAndSettle();
        bloc.add(
          PrivateKeyExportPasswordSubmitted(
            bloc.state.operationId,
            SensitiveString(exportPasswordSentinel),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('private-key-export-password-cancel')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PrivateKeyExportPasswordDialog), findsNothing);
        service.pendingExport!.complete(exportTestResult());
        await tester.pumpAndSettle();
        expect(bloc.state.result, isNull);
        expect(navigation.state.step, SecuritySettingsStep.securityMain);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'disposing its owner clears the prompt and rejects late export results',
      (tester) async {
        await pump(tester, pending: true, ownExportBloc: true);
        bloc.add(PrivateKeyExportRequested());
        await tester.pumpAndSettle();
        bloc.add(
          PrivateKeyExportPasswordSubmitted(
            bloc.state.operationId,
            SensitiveString(exportPasswordSentinel),
          ),
        );
        await tester.pump();
        // Match production ownership: removing the host disposes its BLoC
        // and the listener removes any separately owned password route.
        await tester.pumpWidget(const SizedBox.shrink());
        expect(bloc.state.result, isNull);
        expect(bloc.state.phase, PrivateKeyExportPhase.idle);
        service.pendingExport!.complete(exportTestResult());
        await tester.pumpAndSettle();
        expect(find.byType(PrivateKeyExportPasswordDialog), findsNothing);
        expect(find.text(exportKeySentinel), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _ExportTestTranslations extends AssetLoader {
  const _ExportTestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/en.json').readAsStringSync())
          as Map<String, dynamic>;
}
