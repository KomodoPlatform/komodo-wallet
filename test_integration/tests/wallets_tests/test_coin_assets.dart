// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/main.dart' as app;

import '../../helpers/accept_alpha_warning.dart';
import '../../helpers/restore_wallet.dart';

Future<void> testCoinIcons(WidgetTester tester) async {
  print('🔍 COIN ICONS: Starting coin icons test');
  
  final Finder walletTab = find.byKey(const Key('main-menu-wallet'));
  final Finder addAssetsButton = find.byKey(const Key('add-assets-button'));

  await tester.tap(walletTab);
  print('🔍 COIN ICONS: Tapped wallet tab');
  await tester.pumpAndSettle();
  
  await tester.tap(addAssetsButton);
  print('🔍 COIN ICONS: Tapped add assets button');
  await tester.pumpAndSettle();

  final listFinder = find.byKey(const Key('coins-manager-list'));

  bool keepScrolling = true;
  print('🔍 COIN ICONS: Starting icon verification loop');
  
  int pageCount = 0;
  // Scroll down the list until we reach the end
  while (keepScrolling) {
    pageCount++;
    print('🔍 COIN ICONS: Checking page $pageCount');
    
    // Check the icons before scrolling
    final coinIcons = find
        .descendant(of: listFinder, matching: find.byType(AssetIcon))
        .evaluate()
        .map((e) => e.widget as AssetIcon);

    for (final coinIcon in coinIcons) {
      final coinAbr = coinIcon.assetId?.symbol.configSymbol.toLowerCase();
      final assetPath = '$coinsAssetsPath/coin_icons/png/$coinAbr.png';
      final assetExists = await canLoadAsset(assetPath);
      print('🔍 COIN ICONS: Checking asset for $coinAbr: ${assetExists ? "✓" : "✗"}');
      expect(assetExists, true, reason: 'Asset $coinsAssetsPath does not exist');
    }

    // Scroll the list
    await tester.drag(listFinder, const Offset(0, -500));
    print('🔍 COIN ICONS: Scrolled to next page');
    await tester.pumpAndSettle();

    // Check if we reached the end of the list
    final scrollable = listFinder.evaluate().first.widget as ListView;
    final currentPosition = scrollable.controller!.position.pixels;
    final maxScrollExtent = scrollable.controller!.position.maxScrollExtent;
    keepScrolling = currentPosition < maxScrollExtent;
  }
  
  print('🔍 COIN ICONS: Completed verification of all coin icons');
}

Future<bool> canLoadAsset(String assetPath) async {
  bool assetExists = true;
  try {
    final _ = await rootBundle.load(assetPath);
  } catch (e) {
    print('🔍 ASSET CHECK: Failed to load asset: $assetPath');
    assetExists = false;
  }
  return assetExists;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Run coin icons tests:', (WidgetTester tester) async {
    print('🔍 MAIN: Starting coin icons test suite');
    tester.testTextInput.register();
    await app.main();
    await tester.pumpAndSettle();
    
    print('🔍 MAIN: Accepting alpha warning');
    await acceptAlphaWarning(tester);
    
    await restoreWalletToTest(tester);
    print('🔍 MAIN: Wallet restored');
    
    await testCoinIcons(tester);
    await tester.pumpAndSettle();

    print('🔍 MAIN: Coin icons tests completed successfully');
  }, semanticsEnabled: false);
}
