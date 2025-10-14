## QA Checklist: Coin Activation and Basic Wallet Operations

This checklist covers coin activation/deactivation and non-DEX wallet operations: receive, send, transaction history, charts/graphs, faucets, and wallet page UI/UX. Use one sheet per OS, and record outcomes for traceability.

---
### Test Report ID
- **Pull request**: 
- **Commit hash**: 
- **Username**: 
- **Date**: 
- **Operating system**: 

---

### Preconditions
- [ ] Signed in to a test wallet (with/without backup as needed)
- [ ] Network reachable; also plan offline/flaky runs
- [ ] Test coins defined: at least 1 UTXO coin, 1 account-based coin
- [ ] Known faucet-supported asset(s) available (see faucet feature visibility)
- [ ] Test counterpart wallet/address for send/receive
- [ ] Prices/market data available (or note unavailability) for graphs

---

### 1. Wallet Page: Load and Layout
- [ ] Wallet page loads without crash; no blocking spinners > 5s
- [ ] Active coins list shows at least one coin or empty state guidance
- [ ] Total portfolio value visible; updates when coins activated
- [ ] Pull-to-refresh or refresh control refreshes balances/fiat
- [ ] Scroll behavior smooth; lazy-loading lists don’t jump
- [ ] Expand/collapse for coin list items works; state persists on navigate back

#### Negative
- [ ] With no activated coins, empty state CTA(s) shown (activate/import)
- [ ] API errors show non-blocking toasts/banners without leaking internals
- [ ] Offline shows cached balances (if available) and an informative banner

---

### 2. Activate Coin(s)
- [ ] Open coin activation/selection UI; search/filter works
- [ ] Select single coin → activate; coin appears in active list with balance
- [ ] Select multiple coins → bulk activation runs without UI freeze
- [ ] Activation progress/status visible for coins with setup flows (e.g., ZHTLC/ARRR)
- [ ] Autoscroll/status bar shows per-coin progress and completion

#### Negative
- [ ] Activation failure (network) shows retry; partial success handled safely
- [ ] Duplicate activation request is deduplicated or ignored without error
- [ ] Cancelling or leaving page mid-activation preserves safe state (no soft-lock)

#### Edge Cases
- [ ] First activation after fresh login works and updates portfolio totals
- [ ] Activating coin with zero balance still shows 0 with correct formatting
- [ ] Very large list of selected coins doesn’t freeze UI; progress feedback provided

---

### 3. Deactivate/Disable Coin(s)
- [ ] Deactivate a single coin; it disappears from active list
- [ ] Reactivate the same coin in-session without errors
- [ ] Bulk deactivate multiple coins; portfolio totals update

#### Negative
- [ ] Deactivate parent coin also hides dependent/child coins (if applicable)
- [ ] Rapid activate→deactivate toggling does not crash or corrupt state

#### Edge Cases
- [ ] Deactivation while background balance polling occurs does not throw visible errors
- [ ] After relaunch, previously deactivated coins remain deactivated

---

### 4. Receive Funds
- [ ] Open Receive for a coin: shows address/QR; copy/share available
- [ ] New address button (if implemented) derives a new address and updates QR
- [ ] Trezor/hardware prompts appear when required (if applicable)
- [ ] Copy address shows confirmation; clipboard contains correct address

#### Negative
- [ ] Attempt to generate address when offline shows graceful error or cached address
- [ ] Invalid clipboard paste warning handled (if input address verification exists)

#### Edge Cases
- [ ] Mixed-case and Bech32 addresses rendered correctly in QR and text
- [ ] Very long addresses fit and are selectable; overflow handled

---

### 5. Faucet (If visible for coin)
- [ ] Faucet button visible for supported coins/addresses only
- [ ] Request faucet → shows in-progress state; success shows link to transaction
- [ ] Faucet response message localized and non-PII

#### Negative
- [ ] Faucet rate-limit or insufficient funds returns actionable error
- [ ] Faucet unavailable/network error shows retry without blocking other actions

#### Edge Cases
- [ ] Multiple rapid taps are throttled/debounced (single request sent)
- [ ] Faucet transaction appears in history after network confirms

---

### 6. Send Funds (Basic)
- [ ] Open Send for a coin; form fields validate live (address, amount, fee, memo)
- [ ] Paste address trims spaces; checksum/address validity errors shown where supported
- [ ] Max button fills available spendable amount minus fee
- [ ] Optional custom fee selector present and functional
- [ ] Preview/confirmation screen shows accurate summary before broadcast
- [ ] Successful send returns txid and a link to explorer (where available)

#### Negative
- [ ] Invalid address blocked with clear message
- [ ] Amount > balance blocked; amount = 0 blocked
- [ ] Network/broadcast errors show retry; form state preserved (when available)
- [ ] Hardware wallet rejection cancels cleanly without stuck state

#### Edge Cases
- [ ] High-precision decimals for account-based coins accepted and rounded per rules
- [ ] Very low fee (if allowed) warns about slow confirmation
- [ ] Multi-output or memo fields (if available) validated and included in summary

---

### 7. Transaction History
- [ ] History list loads for selected coin; newest-first ordering
- [ ] Incoming tx shows pending/confirmed status transitions
- [ ] Outgoing tx shows fee, confirmations, and accurate amounts
- [ ] Tapping an item opens details with txid, timestamp, addresses
- [ ] Links to explorers open and resolve

#### Negative
- [ ] API error shows non-blocking banner; cached history still renders if available
- [ ] Empty history shows appropriate empty state

#### Edge Cases
- [ ] Large histories paginate/infinite-scroll smoothly
- [ ] Timezone/locale formatting correct; relative/absolute times consistent

---

### 8. Charts/Graphs
- [ ] Price chart renders with correct units and time ranges (24h/7d/30d)
- [ ] Changing range updates data and axis labels
- [ ] Data unavailable shows graceful placeholder and retry

#### Negative
- [ ] Network failure does not freeze wallet page; other sections usable

#### Edge Cases
- [ ] Very small or large values scale/read correctly; tooltips formatted

---

### 9. Protocol-Specific Coverage (Examples)
- [ ] ZHTLC/ARRR activation shows progress bar; statuses update until done
- [ ] Retry/backoff for activation errors does not spam the UI
- [ ] Post-activation, balances start polling without manual refresh

---

### 10. Buttons, Navigation, and Scroll
- [ ] All primary/secondary buttons enabled/disabled appropriately by form state
- [ ] Back navigation returns to prior scroll position and expanded sections
- [ ] External links open in system browser or in-app webview as designed
- [ ] Keyboard actions (Tab/Enter/Next) advance correctly in forms

---

### 11. Accessibility and Localization
- [ ] Labels, hints, and errors are localized for the current locale
- [ ] Screen readers read button roles and dynamic states (loading/disabled)
- [ ] High-contrast/dark modes keep charts and tx items legible

---

### 12. Performance and Stability
- [ ] Activating 25+ coins completes without UI stutter or memory issues
- [ ] Switching coins in details view is responsive (< 200ms nav)
- [ ] Send/receive screens open in < 500ms on mid-tier devices

---

### 13. Device/Environment Matrix (see `docs/OS_SUPPORT.md`)
- [ ] Android minimum supported device and latest
- [ ] iOS minimum supported device and latest
- [ ] macOS Intel and Apple Silicon
- [ ] Linux minimum supported (Ubuntu/Debian)
- [ ] Windows minimum supported and latest
- [ ] Offline, captive portal, VPN; flaky network

---

### 14. Post-Execution
- [ ] Document failures with steps and redacted logs
- [ ] File issues following `docs/ISSUE.md`
- [ ] Update manual test cases in `docs/MANUAL_TESTING_DEBUGGING.md` if flows changed


