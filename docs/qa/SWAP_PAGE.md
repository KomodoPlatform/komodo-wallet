## QA Checklist: Swap Page (DEX)

Covers coin selection, orderbook, maker/taker order forms, confirmations, and lists: Orders, In Progress, and History. Includes filters and detail pages/modals.

---
### Test Report ID
- **Pull request**: 
- **Commit hash**: 
- **Username**: 
- **Date**: 
- **Operating system**: 

---

### Preconditions
- [ ] User is signed in with activated coins for trading
- [ ] Network reachable; test offline/flaky states
- [ ] At least 1 supported trading pair available (balance on sell side)
- [ ] Market data and orderbook endpoints reachable
- [ ] Time synchronization acceptable (swaps can be time-sensitive)

---

### 1. Navigation and Layout
- [ ] Swap page opens without crash; default tab visible (e.g., Orders)
- [ ] Maker/Taker mode switch available and clearly highlighted
- [ ] Coin pair selectors present; balances visible next to coins
- [ ] Section header/tabs for Orders, In Progress, History render correctly

#### Negative
- [ ] With zero balance on sell side, form disables submit and explains why

---

### 2. Coin Selection
- [ ] Sell and Buy coin pickers open searchable lists; funded at top of list.
- [ ] Switching coins updates balances, available volume, and price quote
- [ ] Flip button swaps Buy/Sell correctly and updates all fields

#### Negative
- [ ] Impossible to select the same coin for both sides (includes segwit; show err message if needed)

#### Edge Cases
- [ ] Very long coin lists scroll smoothly; keyboard navigation works (desktop)
- [ ] Coin variant groupings displayed correctly when expanded

---

### 3. Orderbook
- [ ] Orderbook loads bids/asks; columns align and sort correctly
- [ ] Clicking an orderbook row pre-fills Taker form (price/amount)
- [ ] Spread and mid price shown where applicable

#### Negative
- [ ] Network/orderbook error shows non-blocking banner and retry
- [ ] Empty orderbook shows placeholder with explanation and suggestion to use maker form

#### Edge Cases
- [ ] Rapid updates don’t cause flicker; best price highlights update smoothly
- [ ] Large/small numbers formatted with appropriate precision

---

### 4. Taker Order Form
- [ ] Address/balance widgets show available balance and fee impact
- [ ] Enter buy/sell amount updates the other side via price quote
- [ ] Max button sets spendable amount (reserving fees)
- [ ] Fees/total calculation visible and updates dynamically
- [ ] Slippage or min volume (if available) displayed and editable where applicable
- [ ] Preimage/quote fetch succeeds and updates limits (min/max)
- [ ] Submit shows confirmation with summary (rates, fees, amounts, timings)

#### Negative
- [ ] Amount > balance blocked; zero/empty amount blocked
- [ ] Invalid pair or price quote error shows actionable message; form preserved
- [ ] Network/preimage errors show retry; throttling debounces repeat clicks

#### Edge Cases
- [ ] High-precision amounts accepted per coin rules; rounding handled
- [ ] Fee market change during edit results in recalculation without crash

---

### 5. Maker Order Form
- [ ] Set price and amount; total and fees update correctly
- [ ] Orderbook integration: choose price level via helper (if available)
- [ ] Compare-to-CEX (if shown) displays reference pricing and updates
- [ ] Submit creates maker order and adds to Orders tab

#### Negative
- [ ] Price = 0 or invalid precision blocked with message
- [ ] Not enough balance prevents submission

#### Edge Cases
- [ ] Very small tick sizes/step increments handled; inputs snap correctly
- [ ] Editing price while orderbook updates doesn’t reset user input

---

### 6. Confirmations
- [ ] Maker confirmation modal shows all parameters; confirm/cancel works
- [ ] Taker confirmation modal shows rate, amounts, estimated fees, timeouts
- [ ] Hardware wallet prompts (if any) handled; user cancellation clean

#### Negative
- [ ] Reject/Cancel returns to form with state intact
- [ ] Invalid quote at confirm time shows refresh option

---

### 7. Orders Tab (Open Orders)
- [ ] Newly placed maker orders appear with correct status
- [ ] Cancel action available; confirmation and success feedback shown
- [ ] Columns sortable/filterable (pair, side, time)
- [ ] Clicking an item opens Maker Order Details with full params

#### Negative
- [ ] Cancel failure shows error and retains order
- [ ] Pagination/infinite scroll continues loading without duplication

---

### 8. In Progress Tab (Active Swaps)
- [ ] Starting a taker swap moves entry into In Progress with step/status
- [ ] Step list updates live (init, negotiation, payment, confirmation)
- [ ] Recover/Retry buttons (if present) operate correctly
- [ ] Clicking item opens Swap Details with step breakdown and logs

#### Negative
- [ ] Network hiccups show non-blocking status with auto-retry
- [ ] Failure states produce actionable messages and recovery options

#### Edge Cases
- [ ] App backgrounding/foregrounding preserves progress status
- [ ] System time skew warnings handled (time provider checks)

---

### 9. History Tab (Completed/Failed Swaps)
- [ ] Completed swaps show success state, timestamps, and tx links
- [ ] Failed/cancelled swaps show clear reasons
- [ ] Filters (date range, pair, side, status) work and combine logically
- [ ] Sorting persists across navigation
- [ ] Clicking an item opens details with full audit info

#### Negative
- [ ] Loading/empty states handled gracefully
- [ ] Explorer link errors don’t crash the app

---

### 10. Filters and Search
- [ ] Global/local filters for lists reflect in URL/router state (if applicable)
- [ ] Clearing filters resets lists; badge counts update
- [ ] Mobile filter panels open/close, apply, and persist on back

---

### 11. Protocol/Engine Specific
- [ ] Preimage/limits reflect protocol rules (min volume, dust, fee policy)
- [ ] Timeouts/locktimes surface in UI when relevant
- [ ] Partial fills (if supported) surfaced correctly in orders/history

---

### 12. DEX Swap Functionality
- [ ] Completed taker swap updates balances for both coins; success state shown
- [ ] Completed maker swap fills reflected (full/partial if supported); order removed or updated
- [ ] Swap details show both chain txids, fees, confirmations, and explorer links
- [ ] Refund flow executes when counterparty fails; refunded amount and txid visible
- [ ] Recover funds action (if available) works for stuck swaps; shows result and guidance
- [ ] Timeouts respected per protocol; UI warns before/after expiry with next steps
- [ ] Import swaps (if available) loads historical swaps and preserves status
- [ ] Protocol specifics (e.g. ZHTLC while activation in progress)
- [ ] System time source checks pass; time skew warnings guide user
- [ ] User warned if swap in progress when attempting logout/exit

#### Negative
- [ ] Counterparty cancel/fail surfaces clear reason; no funds lost
- [ ] Expired maker orders auto-cancel or show manual cancel with reason

#### Edge Cases
- [ ] App restart during swap resumes progress with consistent step index
- [ ] Offline mid-swap resumes safely and continues after timely reconnect
- [ ] Multiple concurrent swaps do not mix logs/details

---

### 13. Accessibility and Localization
- [ ] All labels/buttons localized; numeric formats follow locale
- [ ] Screen reader announces tab changes and loading states
- [ ] Keyboard navigation: Tab/Enter moves through forms and tables logically

---

### 14. Performance and Stability
- [ ] Orderbook updates at target frequency without jank
- [ ] Lists render 100+ items smoothly with virtualization/pagination
- [ ] Switching tabs (Orders/In Progress/History) is responsive (< 200ms)

---

### 15. Device/Environment Matrix (see `docs/OS_SUPPORT.md`)
- [ ] Android min + latest; iOS min + latest
- [ ] macOS Intel + Apple Silicon; Windows min + latest; Linux min
- [ ] Offline, captive portal, VPN; flaky network

---

### 16. Post-Execution
- [ ] Document failures with steps and redacted logs
- [ ] File issues following `docs/ISSUE.md`
- [ ] Update manual test cases in `docs/MANUAL_TESTING_DEBUGGING.md` if flows changed


