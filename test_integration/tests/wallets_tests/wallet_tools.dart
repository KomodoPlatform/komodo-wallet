// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../common/goto.dart' as goto;
import '../../common/pause.dart';
import '../../common/widget_tester_action_extensions.dart';
import '../../common/widget_tester_pump_extension.dart';

Future<void> removeAsset(
  WidgetTester tester, {
  required Finder asset,
  required String search,
}) async {
  print('🔍 REMOVE ASSET: Starting remove asset flow');

  final Finder removeAssetsButton = find.byKey(
    const Key('remove-assets-button'),
  );
  final Finder list = find.byKey(const Key('coins-manager-list'));
  final Finder switchButton = find.byKey(const Key('back-button'));
  final Finder searchCoinsField = find.byKey(
    const Key('coins-manager-search-field'),
  );

  await goto.walletPage(tester);
  print('🔍 REMOVE ASSET: Navigated to wallet page');

  await tester.tapAndPump(removeAssetsButton);
  print('🔍 REMOVE ASSET: Tapped remove assets button');
  expect(list, findsOneWidget);

  try {
    expect(searchCoinsField, findsOneWidget);
  } on TestFailure {
    print('**Error** addAsset() no searchCoinsField');
  }

  await enterText(tester, finder: searchCoinsField, text: search);
  print('🔍 REMOVE ASSET: Entered search text: $search');

  try {
    expect(asset, findsOneWidget);
  } on TestFailure {
    print('🔍 REMOVE ASSET: Asset not found initially, attempting to scroll');
    print('**Error** removeAsset([$asset])');
    await tester.dragUntilVisible(asset, list, const Offset(0, -5));
    await tester.pumpAndSettle();
  }

  await tester.tapAndPump(asset);
  print('🔍 REMOVE ASSET: Tapped on asset');

  try {
    expect(switchButton, findsOneWidget);
  } on TestFailure {
    print('🔍 REMOVE ASSET: Switch button not found');
    print('**Error** removeAsset(): switchButton: $switchButton');
  }
  await tester.tapAndPump(switchButton);
  print('🔍 REMOVE ASSET: Tapped switch button');
  await pause(sec: 5);
}

Future<void> addAsset(
  WidgetTester tester, {
  required Finder asset,
  required String search,
}) async {
  print('🔍 ADD ASSET: Starting add asset flow');

  final Finder list = find.byKey(const Key('coins-manager-list'));
  final Finder addAssetsButton = find.byKey(const Key('add-assets-button'));
  final Finder searchCoinsField = find.byKey(
    const Key('coins-manager-search-field'),
  );
  final Finder switchButton = find.byKey(const Key('back-button'));

  await goto.walletPage(tester);
  print('🔍 ADD ASSET: Navigated to wallet page');

  try {
    expect(asset, findsNothing);
  } on TestFailure {
    print('🔍 ADD ASSET: Asset already exists, skipping add');
    // asset already created
    return;
  }

  await tester.tap(addAssetsButton);
  await tester.pumpAndSettle(); // wait for page switch and list loading
  print('🔍 ADD ASSET: Tapped add assets button');

  try {
    expect(searchCoinsField, findsOneWidget);
  } on TestFailure {
    print('**Error** addAsset() no searchCoinsField');
  }

  await enterText(tester, finder: searchCoinsField, text: search);
  print('🔍 ADD ASSET: Entered search text: $search');

  await tester.dragUntilVisible(asset, list, const Offset(-250, 0));
  print('🔍 ADD ASSET: Scrolled to make asset visible');
  await tester.tapAndPump(asset);
  print('🔍 ADD ASSET: Tapped on asset');

  try {
    expect(switchButton, findsOneWidget);
  } on TestFailure {
    print('🔍 ADD ASSET: Switch button not found');
    print('**Error** addAsset(): switchButton: $switchButton');
  }

  await tester.tapAndPump(switchButton);
  print('🔍 ADD ASSET: Tapped switch button');
}

Future<bool> filterAsset(
  WidgetTester tester, {
  required Finder asset,
  required Finder assetScrollView,
  required String text,
  required Finder searchField,
}) async {
  print('🔍 FILTER ASSET: Starting filter with text: $text');

  await enterText(tester, finder: searchField, text: text);
  print('🔍 FILTER ASSET: Entered filter text');
  await tester.pumpAndSettle();

  try {
    await tester.dragUntilVisible(asset, assetScrollView, const Offset(0, -50));
    expect(asset, findsOneWidget);
  } on TestFailure {
    print('🔍 FILTER ASSET: Asset not found after filtering');
    await pause(msg: '**Error** filterAsset([$asset, $text])');
    return false;
  }
  print('🔍 FILTER ASSET: Successfully filtered asset');
  return true;
}

Future<void> enterText(
  WidgetTester tester, {
  required Finder finder,
  required String text,
  int frames = 60,
}) async {
  await tester.enterText(finder, text);
  await tester.pumpNFrames(frames);
  await pause();
}
