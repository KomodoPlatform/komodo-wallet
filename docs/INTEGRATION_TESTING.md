# Integration Testing

## 1. General info

- Integration testing implemented using Flutter built-in [integration_test](https://github.com/flutter/flutter/tree/main/packages/integration_test) package.
- New tests should be added, if possible, for every new issue as a part of corresponding PR, to provide coverage for specific bug/feature. This way we'll, hopefully, expand test coverage in a natural manner.
- Coverage (and structure, if needed) should be updated in table below.

## 2. How to run tests

### 2.1. Download Driver for Web/Chrome/Safari/Firefox

[https://github.com/flutter/flutter/wiki/Running-Flutter-Driver-tests-with-Web](https://github.com/flutter/flutter/wiki/Running-Flutter-Driver-tests-with-Web)

#### 2.1.1. Download and unpack web drivers

##### Chrome

  <https://chromedriver.chromium.org/downloads>

##### Safari

  Configure Safari to Enable WebDriver Support.

  Safari’s WebDriver support for developers is turned off by default.
  
  Run once:

  ```bash
  safaridriver --enable
  ```

  Note:  If you’re upgrading from a previous macOS release, you may need to use sudo.

##### Firefox

- Install and check the version of Firefox.

- Download the Gecko driver for that version from the releases <https://github.com/mozilla/geckodriver/releases>

  Note that this section is experimental, at this point we don't have automated tests running on Firefox.

#### 2.1.2. Launch the WebDriver

NOTE: `chromedriver` is now launched automatically by `run_integration_tests.dart` script, so
this step is optional if you plan to use Chrome.

- for Google Chrome

  ```bash
  chromedriver --port=4444 --silent  --enable-chrome-logs --log-path=console.log
  ```

- or Firefox

  ```bash
  geckodriver  --port=4444
  ```

- or Safari

  ```bash
  /usr/bin/safaridriver  --port=4444 --diagnose
  ```

#### 2.1.3. Run test. From the root of the project, run the following command

  ```bash
  dart run_integration_tests.dart
  ```

To see tests run scripts help message:

  ```bash
  dart run_integration_tests.dart -h
  ```

Tests script runs tests in profile mode, accepts browser dimension adjustment argument and -d (display) arg to set headless mode.  (see below for details)
Or, to run single test:

Change `<path>/testname_test.dart` to actual test file, located in ./test_integration directory.
Currently available test groups:

- `dex_tests/dex_tests.dart`
- `wallets_manager_tests/wallets_manager_tests.dart`
- `wallets_tests/wallets_tests.dart`
- `misc_tests/misc_tests.dart`
- `no_login_tests/no_login_tests.dart`

  and run

  ```bash
  dart run_integration_tests.dart -b '1600,1040' -d 'no-headless' -t 'wallets_tests/wallets_tests.dart'
  ```

  Each test in test groups can be run separately in exact same fashion.

#### 2.1.4. To simulate different screen dimensions, you can use the --browserDimension or -b argument, -d or --display argument to configure headless run

  ```bash
  dart run_integration_tests.dart -b '360,640'
  ```

  ```bash
  dart run_integration_tests.dart --browserDimension='1100,1600'
  ```

  ```bash
  dart run_integration_tests.dart -b '1600,1040' -d 'headless'
  ```
  
#### 2.1.5. To run tests in different browsers, you can specify the --browser-name or -n argument

 ```bash
  dart run_integration_tests.dart -n 'safari'
  ```

  ```bash
  dart run_integration_tests.dart --browser-name=firefox
  ```

 By default, the Chrome browser is used to run tests
