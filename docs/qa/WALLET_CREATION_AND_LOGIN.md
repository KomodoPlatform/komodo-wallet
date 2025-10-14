## QA Checklist: Wallet Creation and Login

This checklist covers positive, negative, and edge-case scenarios for onboarding flows: create/import wallet and login/unlock. Checkboxes have been added to help track execution. Use one sheet per OS, and share results with QA team to track coverage.

---
### Test Report ID
- **Pull request**: 
- **Commit hash**: 
- **Username**: 
- **Date**: 
- **Operating system**: 

---

### Preconditions
- [ ] Test device connected to stable network (Wi‑Fi and cellular where applicable)
- [ ] App fresh install (unless stated otherwise)
- [ ] Known test mnemonic(s), strong password policy, and test accounts prepared
- [ ] Analytics/test logging enabled per `docs/ANALYTICS.md` (if applicable)

---

### 1. First Launch & Onboarding
- [ ] App opens without crash; version/build visible in settings/about
- [ ] Legal screens (ToS/Privacy) appear where required; acceptance persists after relaunch
- [ ] “Create new wallet” and “Import existing wallet” options visible and enabled
- [ ] Localization displays correct strings for default locale

#### Negative
- [ ] Declining ToS/Privacy returns user to a safe state or exits gracefully
- [ ] Airplane mode: onboarding screens load without remote dependencies blocking

---

### 2. Create New Wallet (Positive)
- [ ] Tapping “Create wallet” navigates to password setup
- [ ] Password policy validation updates in real time (length, complexity)
- [ ] Confirm password mismatch shows inline error and disables continue
- [ ] Successfully set password continues to seed generation screen
- [ ] Seed phrase displayed with correct word count (typically 12/24)
- [ ] Ability to reveal/hide seed words works; copy action prompts security warning
- [ ] “I wrote it down” confirmation gated by user action (checkbox/button)
- [ ] Seed confirmation quiz enforces correct order/selection
- [ ] Wallet created; user lands in dashboard/home with empty balances
- [ ] App relaunch requires password/PIN/biometric per settings

#### Negative
- [ ] Weak password rejected with clear error
- [ ] Empty password fields blocked with validation
- [ ] Interrupt during creation (background app, incoming call) resumes safely without data loss
- [ ] Force close during seed display doesn’t store partial state that bypasses backup step
- [ ] Denying clipboard permission prevents copy, shows informative message (if applicable)

#### Edge Cases
- [ ] Extremely long valid password accepted and can unlock
- [ ] Password with unicode/special chars accepted and can unlock
- [ ] Device low storage shows graceful error if secure storage fails
- [ ] Time change/timezone change mid-flow doesn’t corrupt state

---

### 3. Import Existing Wallet (Mnemonic)
- [ ] Import option accepts valid 12/24-word mnemonic
- [ ] Supports uppercase/lowercase, extra spaces trimmed
- [ ] Optional passphrase (BIP39) can be entered and is validated
- [ ] Setting new local password after import works
- [ ] Post-import, expected addresses/accounts appear (if discovery implemented)

#### Negative
- [ ] Invalid word rejected with inline error
- [ ] Incorrect checksum/order rejected
- [ ] Wrong passphrase does not import expected account (warn clearly)
- [ ] Empty field(s) blocked
- [ ] Pasting with leading/trailing whitespace handled gracefully

#### Edge Cases
- [ ] Duplicate words allowed where valid; validation only fails when checksum/order invalid
- [ ] Non-English wordlist rejected or explicitly supported per product scope
- [ ] Large account gap (if discovery) doesn’t freeze UI; shows progress indicator

---

### 4. Import Existing Wallet (file)
- [ ] Valid seed file imports successfully
- [ ] File prompts for password; errors on wrong password
- [ ] Address derived matches expected

#### Negative
- [ ] Malformed file rejected
- [ ] Incorrect password fails with clear error

---

### 5. Password/PIN/Biometrics Setup
- [ ] Enable PIN from settings; set and confirm PIN
- [ ] Enable biometrics when available; system prompt displayed
- [ ] On relaunch, can unlock via biometric; fallback to password works

#### Negative
- [ ] Cancel biometric prompt falls back without lockout
- [ ] Multiple failed biometrics require password
- [ ] Changing device biometrics invalidates old template until re-enrollment

#### Edge Cases
- [ ] Device without biometrics hides option
- [ ] System policy “biometric off” handled gracefully

---

### 6. Login/Unlock Flow
- [ ] From cold start, login screen requires password/PIN/biometric
- [ ] Correct password unlocks; lands on last-known route or dashboard
- [ ] Lock after inactivity triggers; user is returned to auth screen
- [ ] Deep link when locked prompts unlock then routes to destination

#### Negative
- [ ] Wrong password shows non-revealing error; rate limiting/backoff applied
- [ ] Multiple failed attempts trigger exponential delay or temporary lockout
- [ ] PIN brute force protection active per policy; eventual fallback to password

#### Edge Cases
- [ ] App update across versions preserves ability to unlock
- [ ] Device locale change doesn’t break unlock
- [ ] After OS reboot, keystore-backed keys still accessible post-auth

---

### 7. Session, State, and Security
- [ ] Sensitive data never visible in app switcher/screenshots when masked setting enabled
- [ ] Clipboard clears seed after configurable timeout (if copied)
- [ ] Seed never shown after creation unless explicit re-auth + reveal flow
- [ ] Logging excludes secrets; errors are redacted per `docs/BUILD_SECURITY_ADVISORY.md`
- [ ] Analytics events fire per `docs/ANALYTICS_EVENT_IMPLEMENTATION_PLAN.md` without PII

#### Negative
- [ ] Attempt to access protected routes while locked redirects to auth
- [ ] Backgrounding app locks per policy (mobile)

---

### 8. Usability and Accessibility
- [ ] Input focus order logical; keyboard Next/Done advances correctly
- [ ] Large fonts and screen readers announce labels and errors
- [ ] High-contrast/dark mode renders inputs and errors legibly
- [ ] Error messages are concise, actionable, localized

---

### 9. Persistence and Backup
- [ ] Password change flow requires current password; updates encryption key
- [ ] Export wallet requires re-auth; export masked until explicit reveal
- [ ] Disable biometrics requires password confirmation

#### Negative
- [ ] Wrong current password blocks password change
- [ ] Export attempt without re-auth blocked

---

### 10. Reliability & Recovery
- [ ] Kill app during unlock returns to auth screen without corruption
- [ ] Crash during seed confirmation restarts at safe step without bypass
- [ ] Device date/time skew < 1 min does not block local auth
- [ ] Device date/time skew > 1 min shows informative error for user to sync clock
- [ ] Child KDF instances die naturally on app crash/exit
- [ ] Attempted launch of second instance diverts to existing, or shows appropriate error message
- [ ] All KDF launch fail events return an actionable error message (port conflict, missing coins file, misconfigured MM2.json etc)

---

### 11. Platform-Specific Checks
- [ ] Android: Back button behavior consistent; doesn’t bypass auth or skip seed step
- [ ] iOS: Swipe-to-dismiss respects auth gating; Face ID/Touch ID prompts behave per HIG
- [ ] Desktop/Web: secure storage alternatives work; lock on blur supported

---

### 12. Localization and Error Handling
- [ ] All auth-related strings localized; placeholders interpolated
- [ ] Errors map to user-friendly messages (network, storage, validation)

---

### 13. Performance
- [ ] Unlock latency < 1s on modern devices; < 2s on low-end
- [ ] Import with discovery shows progress and remains responsive

---

### 14. Device/Environment Matrix (see `docs/OS_SUPPORT.md`)
- [ ] Android minimum supported device (low-end)
- [ ] Android latest release (high-end)
- [ ] iOS minimum supported
- [ ] iOS latest
- [ ] MacOS intel (pre-silicon)
- [ ] MacOS silicon
- [ ] Linux minimum supported (Ubuntu/Debian)
- [ ] Linux LTR (Ubuntu/Debian)
- [ ] Windows minimum supported
- [ ] Windows latest
- [ ] Different locales (EN + 2 others)
- [ ] Offline, flaky network, VPN
- [ ] Emulator/simulator (optional)

---

### 15. Security Regression Scenarios
- [ ] No cached seed/mnemonic in logs, preferences, or backups
- [ ] Unlock does not expose secrets to accessibility services beyond expected
- [ ] Rate limiting not reset by relaunching app

---

### 16. Post-Execution
- [ ] Document failures with steps to reproduce and logs
- [ ] File issues following `docs/ISSUE.md`
- [ ] Update manual test cases in `docs/MANUAL_TESTING_DEBUGGING.md` if flows changed


