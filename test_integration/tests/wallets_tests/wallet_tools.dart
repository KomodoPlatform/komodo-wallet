// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../common/goto.dart' as goto;
import '../../common/pause.dart';
import '../../common/pump_and_settle.dart';
import '../../common/tester_utils.dart';

Future<void> removeAsset(
  WidgetTester tester, {
  required Finder asset,
  required String search,
}) async {
  final Finder removeAssetsButton = find.byKey(
    const Key('remove-assets-button'),
  );
  final Finder list = find.byKey(
    const Key('coins-manager-list'),
  );
  final Finder switchButton = find.byKey(
    const Key('back-button'),
  );
  final Finder searchCoinsField = find.byKey(
    const Key('coins-manager-search-field'),
  );

  await goto.walletPage(tester);

  await tester.tap(removeAssetsButton);
  await tester.pumpNFrames(10);
  expect(list, findsOneWidget);

  try {
    expect(searchCoinsField, findsOneWidget);
  } on TestFailure {
    print('**Error** addAsset() no searchCoinsField');
  }

  await enterText(tester, finder: searchCoinsField, text: search);

  try {
    expect(asset, findsOneWidget);
  } on TestFailure {
    print('**Error** removeAsset([$asset])');
    await tester.dragUntilVisible(asset, list, const Offset(0, -5));
    await tester.pumpAndSettle();
  }

  await testerTap(tester, asset);

  try {
    expect(switchButton, findsOneWidget);
  } on TestFailure {
    print('**Error** removeAsset(): switchButton: $switchButton');
  }
  await testerTap(tester, switchButton);
  await pause(sec: 5);
}

Future<void> addAsset(
  WidgetTester tester, {
  required Finder asset,
  required String search,
}) async {
  final Finder list = find.byKey(
    const Key('coins-manager-list'),
  );
  final Finder addAssetsButton = find.byKey(
    const Key('add-assets-button'),
  );
  final Finder searchCoinsField = find.byKey(
    const Key('coins-manager-search-field'),
  );
  final Finder switchButton = find.byKey(
    const Key('back-button'),
  );

  await goto.walletPage(tester);

  try {
    expect(asset, findsNothing);
  } on TestFailure {
    // asset already created
    return;
  }

  await testerTap(tester, addAssetsButton);
  try {
    expect(searchCoinsField, findsOneWidget);
  } on TestFailure {
    print('**Error** addAsset() no searchCoinsField');
  }

  await enterText(tester, finder: searchCoinsField, text: search);

  await tester.dragUntilVisible(
    asset,
    list,
    const Offset(-250, 0),
  );
  await tester.pumpAndSettle();
  await tester.tap(asset);

  try {
    expect(switchButton, findsOneWidget);
  } on TestFailure {
    print('**Error** addAsset(): switchButton: $switchButton');
  }

  await tester.tap(switchButton);
  await tester.pumpAndSettle();
}

Future<bool> filterAsset(
  WidgetTester tester, {
  required Finder asset,
  required String text,
  required Finder searchField,
}) async {
  await enterText(tester, finder: searchField, text: text);
  await tester.pumpAndSettle();

  try {
    expect(asset, findsOneWidget);
  } on TestFailure {
    await pause(msg: '**Error** filterAsset([$asset, $text])');
    return false;
  }
  return true;
}

Future<void> enterText(
  WidgetTester tester, {
  required Finder finder,
  required String text,
}) async {
  await tester.enterText(finder, text);
  await tester.pumpNFrames(10);
  await pause();
}
