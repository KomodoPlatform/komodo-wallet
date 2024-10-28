// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

// omit './test_integration/tests/' part of path to testfile
final List<String> testsList = [
  'suspended_assets_test/suspended_assets_test.dart',
  'wallets_tests/wallets_tests.dart',
  'wallets_manager_tests/wallets_manager_tests.dart',
  'dex_tests/dex_tests.dart',
  'misc_tests/misc_tests.dart',
  'fiat_onramp_tests/fiat_onramp_tests.dart',
];

//app data path for mac and linux
const String macAppData = '/Library/Containers/com.komodo.komodowallet';
const String linuxAppData = '/.local/share/com.komodo.KomodoWallet';
const String windowsAppData = r'\AppData\Roaming\com.komodo';

// TODO: convert to class & include args as class members
const String suspendedCoin = 'KMD';
File? _configFile;
bool verbose = false;

Future<void> main(List<String> args) async {
  final ArgParser parser = _configureArgParser();
  final ArgResults runArguments = parser.parse(args);

  final bool runHelp = runArguments['help'] as bool;
  verbose = runArguments['verbose'] as bool;
  final String testToRunArg = runArguments['testToRun'] as String;
  final String browserDimensionArg = runArguments['browserDimension'] as String;
  final String displayArg = runArguments['displayMode'] as String;
  final String deviceArg = runArguments['device'] as String;
  final String runModeArg = runArguments['runMode'] as String;
  final String browserNameArg = runArguments['browser-name'] as String;

  // Show help message and exit
  if (runHelp) {
    print(parser.usage);
    exit(0);
  }

  // Coins config setup for suspended_assets_test
  final Map<String, dynamic> originalConfig;
  _configFile = await _findCoinsConfigFile();
  originalConfig = _readConfig();

  // Run tests
  if (testToRunArg.isNotEmpty) {
    await _runTest(
      testToRunArg,
      browserDimensionArg,
      displayArg,
      deviceArg,
      runModeArg,
      browserNameArg,
      originalConfig,
    );
  } else {
    for (final String test in testsList) {
      try {
        await _runTest(
          test,
          browserDimensionArg,
          displayArg,
          deviceArg,
          runModeArg,
          browserNameArg,
          originalConfig,
        );
      } catch (e, s) {
        print(s);
        throw Exception('Caught error executing _runTest: ' + e.toString());
      }
    }
  }
}

ArgParser _configureArgParser() {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show help message and exit',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Print verbose output',
    )
    ..addOption(
      'testToRun',
      abbr: 't',
      defaultsTo: '',
      help: 'Specify a single testfile to run, if option is not used, '
          'all available tests will be run instead; option usage '
          'example: -t "design_tests/theme_test.dart"',
    )
    ..addOption(
      'browserDimension',
      abbr: 'b',
      defaultsTo: '1024,1400',
      help: 'Set device window(screen) dimensions: height, width',
    )
    ..addOption(
      'displayMode',
      abbr: 'd',
      defaultsTo: 'no-headless',
      help:
          'Set to "headless" for headless mode usage, defaults to no-headless',
      allowed: ['headless', 'no-headless'],
    )
    ..addOption(
      'device',
      abbr: 'D',
      defaultsTo: 'web-server',
      help: 'Set device to run tests on',
      allowedHelp: {
        'web-server': 'Web server (default)',
        'chrome': 'Test Chrome',
        'linux': 'Test native Linux application',
        'macos': 'Test native macOS application',
        'windows': 'Test native Windows application',
        'ios': 'iOS',
        'android': 'Android',
      },
    )
    ..addOption(
      'runMode',
      abbr: 'm',
      defaultsTo: 'profile',
      help: 'App build mode selectrion',
      allowed: ['release', 'debug', 'profile'],
    )
    ..addOption(
      'browser-name',
      abbr: 'n',
      defaultsTo: 'chrome',
      help: 'Set browser to run tests on',
      allowed: ['chrome', 'safari', 'firefox', 'edge'],
    );
  return parser;
}

Future<void> _runTest(
  String test,
  String browserDimentionFromArg,
  String displayStateFromArg,
  String deviceFromArg,
  String runModeFromArg,
  String browserNameArg,
  Map<String, dynamic> originalConfigPassed,
) async {
  print('Running test ' + test);

  if (test == 'suspended_assets_test/suspended_assets_test.dart') {
    _breakConfig(originalConfigPassed);
  }

  print('Starting process for test: ' + test);

  ProcessResult result;
  try {
    if (deviceFromArg == 'web-server') {
      if (verbose) {
        print(
          "RUNNING: 'flutter drive --dart-define=testing_mode=true "
          '--driver=test_driver/integration_test.dart '
          '--target=test_integration/tests/$test -d $deviceFromArg '
          '--browser-dimension $browserDimentionFromArg '
          '--$displayStateFromArg '
          '--$runModeFromArg '
          "--browser-name $browserNameArg'",
        );
      }
      result = await Process.run(
        'flutter',
        [
          'drive',
          '--dart-define=testing_mode=true',
          '--driver=test_driver/integration_test.dart',
          '--target=test_integration/tests/' + test,
          if (verbose) '-v',
          '-d',
          deviceFromArg,
          '--browser-dimension',
          browserDimentionFromArg,
          '--' + displayStateFromArg,
          '--' + runModeFromArg,
          '--browser-name',
          browserNameArg,
          '--web-renderer',
          'canvaskit',
        ],
        runInShell: true,
      );
    } else {
      //Clear app data before tests for Desktop native app
      await _clearNativeAppsData();

      // Run integration tests for native apps
      // E.g. Linux, MacOS, Windows, iOS, Android
      result = await Process.run(
        'flutter',
        [
          'drive',
          '--dart-define=testing_mode=true',
          '--driver=test_driver/integration_test.dart',
          '--target=test_integration/tests/' + test,
          if (verbose) '-v',
          '-d',
          deviceFromArg,
          '--' + runModeFromArg,
        ],
        runInShell: true,
      );
    }
  } catch (e, s) {
    if (test == 'suspended_assets_test/suspended_assets_test.dart') {
      _restoreConfig(originalConfigPassed);
      print('Restored original coins configuration file.');
    }
    print(s);
    throw Exception('Error running flutter drive Process: ' + e.toString());
  }

  stdout.write(result.stdout);
  if (test == 'suspended_assets_test/suspended_assets_test.dart') {
    _restoreConfig(originalConfigPassed);
    print('Restored original coins configuration file.');
  }
  // Flutter drive can return failed test results just as stdout message,
  // we need to parse this message and detect test failure manually
  if (_didAnyTestFail(result)) {
    throw ProcessException(
      'flutter',
      ['test ' + test],
      'Failure details are in $browserNameArg driver output.\n',
      -1,
    );
  }
  print('\n---\n');
}

bool _didAnyTestFail(ProcessResult result) {
  final caseInvariantConsoleOutput = result.stdout.toString().toLowerCase() +
      result.stderr.toString().toLowerCase();

  return caseInvariantConsoleOutput.contains('failure details') ||
      caseInvariantConsoleOutput.contains('test failed') ||
      !caseInvariantConsoleOutput.contains('all tests passed');
}

Map<String, dynamic> _readConfig() {
  Map<String, dynamic> json;

  try {
    final String jsonStr = _configFile!.readAsStringSync();
    json = jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (e) {
    print('Unable to load json from ${_configFile!.path}:\n$e');
    rethrow;
  }

  return json;
}

void _breakConfig(Map<String, dynamic> config) {
  if (_configFile == null) {
    throw Exception('Coins config file not found');
  } else {
    print('Temporarily breaking $suspendedCoin electrum config'
        " in '${_configFile!.path}' to test suspended state.");
  }

  final broken = Map<String, dynamic>.from(config);
  // ignore: avoid_dynamic_calls
  broken[suspendedCoin]['electrum'] = [
    {
      'url': 'broken.e1ectrum.net:10063',
      'ws_url': 'broken.e1ectrum.net:30063',
    }
  ];

  _writeConfig(broken);
}

void _restoreConfig(Map<String, dynamic> originalConfig) {
  _writeConfig(originalConfig);
}

void _writeConfig(Map<String, dynamic> config) {
  final String spaces = ' ' * 4;
  final JsonEncoder encoder = JsonEncoder.withIndent(spaces);

  _configFile!.writeAsStringSync(encoder.convert(config));
}

Future<File?> _findCoinsConfigFile() async {
  final config = File('assets/config/coins_config.json');

  if (!config.existsSync()) {
    throw Exception('Coins config file not found at ${config.path}');
  }

  return config;
}

Future<void> _clearNativeAppsData() async {
  ProcessResult deleteResult;
  if (Platform.isWindows) {
    final homeDir = Platform.environment['UserProfile'];
    if (Directory('$homeDir$windowsAppData').existsSync()) {
      deleteResult = await Process.run(
        'rmdir',
        ['/s', '/q', '$homeDir$windowsAppData'],
        runInShell: true,
      );
      if (deleteResult.exitCode == 0) {
        print('Windows App data removed successfully.');
      } else {
        print(
          'Failed to remove Windows app data. Error: ${deleteResult.stderr}',
        );
      }
    } else {
      print('No need clean windows app data');
    }
  } else if (Platform.isLinux) {
    final homeDir = Platform.environment['HOME'];
    deleteResult = await Process.run(
      'rm',
      ['-rf', '$homeDir$linuxAppData'],
      runInShell: true,
    );
    if (deleteResult.exitCode == 0) {
      print('Linux App data removed successfully.');
    } else {
      print('Failed to remove Linux app data. Error: ${deleteResult.stderr}');
    }
  } else if (Platform.isMacOS) {
    final homeDir = Platform.environment['HOME'];
    deleteResult = await Process.run(
      'rm',
      ['-rf', '$homeDir$macAppData'],
      runInShell: true,
    );
    if (deleteResult.exitCode == 0) {
      print('MacOS App data removed successfully.');
    } else {
      print('Failed to remove MacOS app data. Error: ${deleteResult.stderr}');
    }
  }
}
