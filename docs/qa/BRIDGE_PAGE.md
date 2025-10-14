## QA Checklist: Bridge Page (Cross-Chain)

Basic cross-chain exchange UI that reuses DEX functionality under the hood. Covers form, confirmation, and lists (In Progress, History) with bridge-specific filters.

---
### Test Report ID
- **Pull request**: 
- **Commit hash**: 
- **Username**: 
- **Date**: 
- **Operating system**: 

---

### Preconditions
- [ ] Signed in; required coins activated (auto-activation allowed)
- [ ] Network reachable; test offline/flaky states
- [ ] Sell asset has sufficient balance for min volume and fees
- [ ] Best orders endpoint reachable and returns candidates

---

### 1. Navigation and Layout
- [ ] Bridge page opens without crash; default tab is Form
- [ ] Tabs present: Form, In Progress, History
- [ ] Clock/time warning banner visible
- [ ] Switching to Trading Details view works when a swap is selected

---

### 2. Ticker and Protocol Selection
- [ ] Ticker dropdown opens; selecting ticker filters source/target protocols
- [ ] Source protocols table lists coins; selecting sets Sell coin
- [ ] Target protocols table lists best orders; selecting sets Buy coin and price
- [ ] Auto-activation runs when needed; status banners/errors shown if activation fails

#### Negative
- [ ] Selecting suspended/unsupported coins prevented with clear message
- [ ] Selecting own address as counterparty prevented (trade with self check)

#### Edge Cases
- [ ] Long lists scroll smoothly; search/filter interactions remain responsive

---

### 3. Amount and Limits
- [ ] Max button uses available balance (periodically refreshed)
- [ ] Min trading volume enforced (from DEX); error provides Set Min action
- [ ] Max taker volume enforced; error provides Set Max action
- [ ] Buy amount updates from price and sell amount

#### Negative
- [ ] Zero/empty amount blocked with error
- [ ] Amount > available balance shows actionable error

---

### 4. Fees and Preimage
- [ ] Fee/total section updates periodically (~20s) while valid
- [ ] Preimage retrieval succeeds and shows rates/fees
- [ ] Network/preimage errors surface, do not clear user input

---

### 5. Submit and Confirmation
- [ ] Submit validates and shows confirmation with send/receive, fiat deltas, fees
- [ ] Confirm initiates swap; navigates to Trading Details by UUID
- [ ] Cancel returns to form with state intact

#### Negative
- [ ] Submit while trading disabled shows disabled button/text
- [ ] Start swap failure logs error and displays non-blocking message

---

### 6. In Progress List (Bridge-only filter)
- [ ] In Progress shows only swaps where sell ticker == buy ticker
- [ ] Clicking item opens Trading Details with step breakdown
- [ ] Live status updates; retry/recover buttons (if present) work

#### Negative
- [ ] Network hiccups show non-blocking status with auto-retry

#### Edge Cases
- [ ] App background/foreground preserves progress
- [ ] Logout resets form state and tabs to defaults

---

### 7. History List (Bridge-only filter)
- [ ] Completed swaps listed with timestamps and explorer links
- [ ] Failed/canceled swaps show reasons
- [ ] Sorting/filtering behaves consistently

---

### 8. DEX Parity (Reuse Behavior)
- [ ] Enforces same min/max volume, dust, fee policy as Swap page
- [ ] Resumes swaps after restart/offline
- [ ] Refund/recover flows behave identically to Swap page

---

### 9. Accessibility and Localization
- [ ] All labels localized; errors actionable and translated
- [ ] Keyboard navigation and focus order correct

---

### 10. Performance and Stability
- [ ] Lists render smoothly with 100+ items (when applicable)
- [ ] Form interactions (dropdowns, amounts) are responsive (< 200ms)

---

### 11. Device/Environment Matrix (see `docs/OS_SUPPORT.md`)
- [ ] Android min + latest; iOS min + latest
- [ ] macOS Intel + Apple Silicon; Windows min + latest; Linux min
- [ ] Offline, captive portal, VPN; flaky network

---

### 12. Post-Execution
- [ ] Document failures with steps and redacted logs
- [ ] File issues following `docs/ISSUE.md`
- [ ] Update manual test cases in `docs/MANUAL_TESTING_DEBUGGING.md` if flows changed


