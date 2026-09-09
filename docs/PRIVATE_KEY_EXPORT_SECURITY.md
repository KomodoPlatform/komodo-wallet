# Diagnostic privacy and private-key export

This change fixes the diagnostic disclosure and private-key export findings
reported against the 0.9.7 release candidate. The app and SDK use the matching
`fix/release-diagnostics-and-key-export` branches. The app branch starts at
`dev` (`eae57cd734f89270a36bcdf7c604b8cbe49869de`). The SDK branch starts at
`origin/dev` (`c696117ade94511c1a6a2c17e47583a57f645f53`) and first preserves the
app's existing descendant security fixes through
`4d386b0a710fd78aa4e5e0d782eb6d9e49d3e828`.

The verified wallet Delete fix is preserved. KDF remains
`3.1.0-beta_f3efd2c`, source `f3efd2ca10420f2982fa127dde84dcc17891f577`.

## SDK boundary

RPC diagnostics contain only recognized method names, outcomes, durations,
safe counts and fixed error categories. Requests, startup configuration,
responses, process output and exception bodies are excluded from diagnostics
regardless of verbosity. Unknown method names become `unknown`. Recursive
censorship recognizes private-key naming variants, including `priv_key`, as
secondary protection. Operational RPC values and deliberate export JSON retain
their original values. Secret-bearing models have redacted diagnostic strings,
including when Equatable stringification is enabled.

`SecurityManager.exportPrivateKeys` owns protocol selection. It returns a result
per requested asset, including its signing asset (the actual TRON platform for
online token exports), keys, actual coverage and a typed failure when unavailable.
Offline assets run independently with at most
two requests in flight, so one unsupported asset cannot erase successful keys.
Default asset selection remains the SDK session's activated, pending and failed
assets, with existing app presentation exclusions preserved.

TRON and TRC20 share one `show_priv_key` call per actual signing platform. Both
the requested asset and its platform must already be activated; pending and
inactive states are reported without activation. The returned scalar is checked
against secp256k1 bounds, and its public key and TRON owner address are derived
with the existing PointyCastle dependency and address codec. Fresh KDF metadata
must match the owner address and the actual HD address record/path. Public
metadata searches are bounded (32 account hints, 64 address pages); insufficient
evidence returns `metadataUnverified` rather than inferred coverage.

TRON coverage is always **currently activated address**. It does not represent
every address in an HD wallet. Offline HD assets retain their actual account,
chain and inclusive address range. ZHTLC retains its account-level coverage and
optional viewing-key fields. The existing `getPrivateKeys` API remains strict:
an explicit account/range request never silently falls back to one TRON key.

Export capabilities belong to one SecurityManager, verified wallet identity and
source-owned authentication generation. Public authentication transitions revoke
the generation synchronously before asynchronous work starts, including logout
followed by login to the same wallet. Capture is unavailable while a transition
is pending. Generation and identity are rechecked around asynchronous operations;
any transition invalidates the entire export.

## App lifecycle and delivery

The screen-scoped `PrivateKeyExportBloc` depends on injected export and delivery
services. Widgets render results and dispatch actions. Passwords are never state
fields. Cancellation, navigation away, disposal, wallet replacement and logout
clear the result and invalidate pending operations. A synchronous authentication
generation signal also clears displayed keys as soon as logout is requested.

Clipboard, file and share delivery revalidate identity asynchronously and then
check generation synchronously immediately before releasing the data. Desktop
and Android destination pickers receive no key bytes. Validation is repeated
after the destination is selected. iOS sharing stages a temporary file and removes
it on completion, cancellation or error. Browser downloads report an unconfirmed
outcome because a browser cannot report whether the user saved or cancelled.
Viewing keys is not recorded as a successful export.
Private-key delivery does not mark the entire wallet as backed up; the seed
backup flow remains separate.

The `gleec-private-key-export` version 1 document preserves per-key fields and
adds coverage, signing-platform associations and unavailable outcomes. Its
filtered assets and coverage match the screen. Bulk actions refer to **Displayed
keys**. TRON labels never imply full HD-wallet coverage.

## Diagnostic storage and feedback

Logger initialization has one awaited, retryable readiness boundary. The fixed
namespace is `gleec_diagnostics_v1`. Before enabling it, migration removes old
diagnostic storage, cached diagnostic exports and precisely named app-owned iOS
diagnostic archives. It preserves wallet files, unrelated files, nested folders
and symlink targets. Failure leaves diagnostic export unavailable while wallet
use and feedback remain available.

Queue flushing, migration, retention, snapshots and disposal share a serialized
storage lifecycle. Browser clients use Web Locks and fail closed without them.
Snapshots copy bounded chunks under the lock before consumption, so later
writes cannot invalidate the export. Updated clients never read an old namespace
recreated by an older tab.

`SafeLogExporter` is the only app diagnostic attachment/export path. It accepts
complete versioned records, reapplies the diagnostic policy, drops malformed or
unclassifiable payload records and applies byte limits after filtering. Both
feedback providers receive prepared immutable attachments and have no logger
storage dependency. Automatic feedback metadata uses an explicit allowlist;
intentional user feedback remains usable without a diagnostic attachment.

Feedback latches screenshot sensitivity for the capture session. A sensitive
screen appearing at any time during that session suppresses app preview painting
and replaces the outgoing screenshot, even if logout or navigation subsequently
clears the screen. Missing or replaced sensitivity controllers fail closed.

## Validation and security review

Validation uses Flutter **3.41.4**. New app regressions are registered in
`test_units/main.dart`; its four required GasFree defines are documented in
[TESTING.md](TESTING.md). Native filesystem and browser OPFS tests cover legacy
cleanup, retry, queued writes, immediate snapshots, concurrent lock users,
namespace recreation, disposal and preservation of wallet files.

SDK tests use synthetic seed, password and private-key sentinels across logging
flags, errors and fallback paths, and assert that successful operational RPCs
and intentional exports retain their values. Export tests cover partial failure,
two-request concurrency, explicit range semantics, invalid scalars, metadata
mismatch, platform association, activation state and authentication transitions.

The retained bundled-KDF regression is:

```sh
cd sdk/packages/komodo_defi_sdk
KDF_EXPORT_TEST_BINARY="$(pwd)/../komodo_defi_framework/macos/bin/kdf" \
  flutter test --no-pub test/security/tron_export_kdf_contract_test.dart
```

It starts the pinned binary against a local mock TRON node with synthetic wallet
data, verifies indices 0 and 7, checks TRC20 signing-platform association and
confirms that offline TRON export is unsupported. It does not broadcast a
transaction or use a funded wallet.

An independent read-only security reviewer examined the SDK sources and app
boundaries. Review identified and drove regressions for actual WASM fallback
logging, logout invalidation timing, mutable request selection, cross-manager
capabilities, parent activation states, final delivery checks, browser delivery
reporting, asset exclusions, stale QR requests and feedback screenshot capture
timing. Final validation results and reviewed commit identifiers are recorded in
the [validation record](PRIVATE_KEY_EXPORT_VALIDATION.md).

### Limits

These fixes cannot revoke diagnostic files already downloaded or sent to another
party. Older open tabs can still run old code; updated clients exclude their
legacy storage. Desktop tests, Android channel tests/Java compilation and iOS
staging tests do not replace device testing of operating-system share sheets,
provider crashes or app termination. Browser tests exercise actual Web Locks,
OPFS and worker concurrency, not every browser/version or several complete app
tabs. Windows filesystem behavior was not exercised on this macOS host.

Private-key export deliberately releases secret material to the destination the
user chooses. Clearing references in Dart is not a promise of memory zeroization
or clipboard revocation after successful delivery.
