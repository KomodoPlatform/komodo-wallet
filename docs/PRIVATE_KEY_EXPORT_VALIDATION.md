# Validation and independent review record

Date: 2026-09-09. Toolchain: Flutter 3.41.4 on macOS. All added test credentials,
mnemonics and keys are synthetic. No feedback was submitted to a live provider,
and no blockchain transaction was broadcast.

## Implementation commits

Both repositories use `fix/release-diagnostics-and-key-export`.

| Repository | Reviewed implementation commit | Review base |
| --- | --- | --- |
| SDK | `00821337492faf939e2fe88f7c1119849aa9dcdd` | `4d386b0a710fd78aa4e5e0d782eb6d9e49d3e828` |
| App | `aa343d20f011506af63e0a7dbb37fffa3bd684f0` | `eae57cd734f89270a36bcdf7c604b8cbe49869de` |

The SDK branch includes `origin/dev`
`c696117ade94511c1a6a2c17e47583a57f645f53` and preserves the app's existing
descendant security fixes before adding the remediation. The app pins the exact
reviewed SDK commit. KDF remains `3.1.0-beta_f3efd2c`, source
`f3efd2ca10420f2982fa127dde84dcc17891f577`. The existing Delete fix is retained.
Test-generated build configuration changes were restored; dependency lockfiles
and KDF pins are unchanged.

See [the implementation notes](PRIVATE_KEY_EXPORT_SECURITY.md) for boundaries,
coverage semantics, migration behavior and limitations.

## Results

Counts below identify separate suites; focused tests can also be included in a
package or app aggregate, so the rows must not be added together.

| Check | Result |
| --- | --- |
| Full app `test_units/main.dart`, all four required GasFree defines | 908 passed, 3 pre-existing skips |
| Full `komodo_defi_sdk` suite, with the bundled-KDF export regression enabled | 907 passed, 1 pre-existing skip |
| Auth/Trezor regressions, including Delete, transition timing and wrong-password classification | 59 passed |
| SDK structured export regressions | 32 passed, also included in the SDK aggregate |
| Typed legacy `show_priv_key` RPC tests | 4 passed |
| Framework/RPC/sanitizer/streaming logging regressions, including actual WASM transport | Passed; synthetic secret sentinels and operational-value preservation checked |
| Seed-node startup fallback tests | 15 passed, including 8 new diagnostic regressions |
| DragonLogs native storage tests | 15 passed |
| DragonLogs Chrome OPFS/Web Locks tests | 9 passed, including worker concurrency and stable snapshots during writes |
| App export BLoC, delivery, real adapter, password and lifecycle regressions | 38 passed, included in the app aggregate |
| App logger, safe exporter, feedback and screenshot regressions | 34 passed, included in the app aggregate |
| App diagnostic artifact cleanup and guarded file delivery | 10 passed, included in the app aggregate |
| KDF replay, default/HD mode | 30 passed, 4 skips |
| KDF replay, legacy/iguana mode | 28 passed, 3 skips |
| Android bridge and MainActivity compilation against Flutter embedding and Android API 35 | Passed; javac reported missing Kotlin annotation metadata in the minimal validation classpath |
| Analysis of changed app files | No errors or warnings; 12 existing informational findings |
| Analysis of changed SDK files | No errors or warnings; 238 informational findings |
| Required repository-wide `flutter analyze --no-pub` | No errors; nonzero exit from 55 existing warnings and 2,088 informational findings |
| Changed-file formatting, generated localization keys and whitespace checks | Completed |

The three app skips are the existing `Get formatted USD balance using SDK
balance`, `getTotal24Change calculates total change`, and `Total fee positive
test` fixtures. The SDK skip is the existing balance-cache test whose empty-cache
expectation contradicts automatic reattachment after a wallet change. No new test
was skipped to make these changes pass. The retained real KDF regression ran
successfully; it was not skipped in the final SDK aggregate.

### Reproduction commands

Use the pinned toolchain, rather than a different globally selected Flutter:

```sh
export PATH="/Users/charl/fvm/versions/3.41.4/bin:$PATH"
flutter pub get --enforce-lockfile --offline
flutter test --no-pub test_units/main.dart \
  --dart-define=TRON_GASLESS_ENABLED=true \
  --dart-define=TRON_GASLESS_RECEIVE_ENABLED=true \
  --dart-define=TRON_GASLESS_BASE_URL=https://quicknode.gleec.com/gasfree/tron \
  --dart-define=TRON_GASLESS_SERVICE_PROVIDER=TLntW9Z59LYY5KEi9cmwk3PKjQga828ird

cd sdk/packages/komodo_defi_sdk
KDF_HARNESS='' \
KDF_EXPORT_TEST_BINARY="$(pwd)/../komodo_defi_framework/macos/bin/kdf" \
  flutter test --no-pub

cd ../dragon_logs
flutter test --no-pub test/dragon_logs_test.dart test/log_storage_privacy_test.dart
flutter test --no-pub --platform chrome test/web_log_storage_privacy_test.dart

cd ../komodo_defi_framework
flutter test --no-pub --platform chrome \
  test/operations/kdf_operations_wasm_diagnostics_test.dart

cd ../komodo_defi_harness
KDF_HARNESS_WALLET_TYPE=hd flutter test --no-pub --exclude-tags bench
KDF_HARNESS_WALLET_TYPE=iguana flutter test --no-pub --exclude-tags bench
```

The KDF export wrapper runs against a loopback mock node and temporary wallet
data. It verifies the activated owner key at HD indices 0 and 7, TRC20/platform
association, the direct account-balance metadata shape, and the unsupported
offline TRON contract. Public-vector and mocked SDK tests additionally cover
invalid scalars, mismatched addresses/paths, inactive and pending platforms,
mixed failures, concurrency and strict explicit-range behavior.

## Independent security review

A separate read-only `gleec_reviewer` agent examined the implementation and test
sources. It did not implement the fixes. Test-execution evidence came from the
implementation agents and the final aggregate runs above.

Review covered the committed SDK logging, storage, authentication and export
boundaries and the committed app BLoC, service adapters, delivery, migration,
feedback and screenshot boundaries. Findings were resolved and re-reviewed:

- Actual WASM fallback logging could still expose untrusted method/response
  values; the real JS transport now has captured-output regressions.
- Public authentication transitions initially revoked exports too late; the
  source now revokes synchronously before awaits and rejects pending transitions.
- Mutable selections and cross-manager capabilities could weaken session
  binding; selections are copied before awaiting and tokens are owner-bound.
- Parent activation state and HD metadata/path mismatches needed explicit
  rejection; the SDK now returns unavailable outcomes without guessing coverage.
- Async delivery checks left a final scheduling gap; each irreversible handoff
  has a synchronous generation check, including after destination selection.
- Browser downloads cannot report confirmed completion; they now remain
  unconfirmed and never mark the export as completed.
- Permanent asset exclusions and pending QR intent needed preservation; the UI
  now uses consistent selection and revision checks.
- Feedback sensitivity checked after screenshot capture could become false on
  logout; capture-lifetime sensitivity and preview painting now fail closed.
- Tests found an invalid transparent PNG and an already-disposed controller
  subscription; both were corrected and covered by pixel/decoder regressions.

The reviewer attested that the exact SDK and app implementation commits listed
above match the reviewed changes, with **no unresolved blocking findings**.

## Remaining verification limits

This is a code and automated-test review, not a guarantee that no vulnerability
exists. Full live-network GUI integration and benchmark tiers were not run for
this remediation. Real Android/iOS share-sheet lifecycle and provider failures,
process termination while staging a share, Windows filesystem behavior, and
multiple complete app tabs remain outside the exercised tests. Browser storage
tests did run real OPFS, Web Locks and a concurrent worker.

Already downloaded/shared diagnostics cannot be revoked. Old open app tabs can
still execute old code; updated clients never import their legacy namespace.
These limits and the intentional, current-address-only TRON coverage must remain
visible when evaluating release readiness.
