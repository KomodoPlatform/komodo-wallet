## QA Checklist: Settings Page and Children

Covers Settings landing, General, Security, and Support. Includes mobile/desktop layouts, navigation menu, and sensitive-data flows.

---
### Test Report ID
- **Pull request**: 
- **Commit hash**: 
- **Username**: 
- **Date**: 
- **Operating system**: 
- **Issues opened**: 

---

### Preconditions
- [ ] Signed in (for wallet-dependent items); also test logged-out
- [ ] Trading enabled/disabled states available (for conditional items)
- [ ] Hardware wallet mode (if applicable) to verify hidden items

---

### 1. Navigation and Layout
- [ ] Settings page opens without crash
- [ ] Desktop: left menu + scrollable content; Mobile: menu list and content views
- [ ] Selecting a menu item updates content and highlights selection
- [ ] Back navigation on mobile returns to menu where applicable

---

### 2. General Settings
- [ ] Theme switcher toggles themes and persists after relaunch
- [ ] Manage Analytics: enable/disable analytics providers; state persists
- [ ] Manage Test Coins: toggles test coin visibility and persists
- [ ] Manage Weak Passwords: exposes controls only when wallet available (non-HW)
- [ ] Manage Trading Bot: visible only when trading enabled; opens bot settings
- [ ] Download Logs: generates and downloads logs without PII leakage
- [ ] Reset Activated Coins: clears and refreshes wallet coin list
- [ ] Show Swap Data / Import Swaps: accessible when wallet present; actions complete

#### Negative
- [ ] Disabled trading hides trading bot control
- [ ] Logged out or HW wallet hides restricted controls

---

### 3. Security Settings
- [ ] Security main page loads with options: View Seed, View Private Keys, Change Password
- [ ] View Seed: password prompt required; seed shown; back flows work
- [ ] Seed Confirmation: user can confirm seed; success page shown; data cleared after
- [ ] View Private Keys: password prompt with loading; keys shown only after fetch
- [ ] Private keys never persisted in logs/state; cleared when leaving view
- [ ] Change Password: requires current password; updates and persists

#### Negative
- [ ] Wrong password shows error and blocks access
- [ ] Attempt to navigate away during sensitive view clears sensitive data
- [ ] Trading-disabled assets listed as blocked in private key view

#### Edge Cases
- [ ] Long seed/large number of keys render without UI freezes
- [ ] Copy actions work and show confirmation; clipboard contains correct text

---

### 4. Support
- [ ] Support page loads content and external links
- [ ] Links open externally and do not block navigation

---

### 5. Accessibility and Localization
- [ ] All labels localized; errors actionable
- [ ] Screen readers announce menu selection and section headers
- [ ] Keyboard navigation across menu and content works (Tab/Enter)

---

### 6. Performance and Stability
- [ ] Switching sections is responsive (< 200ms) on mid-tier devices
- [ ] Large logs export completes without UI freeze

---

### 7. Device/Environment Matrix (see `docs/OS_SUPPORT.md`)
- [ ] Android min + latest; iOS min + latest
- [ ] macOS Intel + Apple Silicon; Windows min + latest; Linux min
- [ ] Offline, captive portal, VPN; flaky network

---

### 8. Post-Execution
- [ ] Document failures with steps and redacted logs
- [ ] Report [issues](https://github.com/KomodoPlatform/komodo-wallet/issues) for failing tests and/or UX enhancements
- [ ] Report [issues](https://github.com/KomodoPlatform/komodo-wallet/issues) for missing or obsolete tests within the QA checklists (if flows changed)
- [ ] Update manual test cases in `docs/qa/MANUAL_TESTING_NOTES.md` 
