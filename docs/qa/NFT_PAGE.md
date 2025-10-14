## QA Checklist: NFT Page

Covers NFT list/grid, details, receive, withdraw, and NFT transactions (filters and details) across mobile/desktop layouts.

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
- [ ] Signed in; NFT-supported coins activated
- [ ] Network reachable; test offline/flaky
- [ ] Test wallet with a small set of NFTs (varied media)
- [ ] Explorer links available (if applicable)

---

### 1. NFT Main Page
- [ ] Page loads without crash; shows tabs/controls
- [ ] Refresh button updates list; spinner/banners visible during load
- [ ] Empty state shown when no NFTs; CTA guidance present
- [ ] Error state shows non-blocking banner with retry

#### Edge Cases
- [ ] Large collection renders smoothly; virtualization/pagination works
- [ ] Mixed media (image/video/unknown) thumbnails render or fallback

---

### 2. NFT List/Grid
- [ ] Items show thumbnail, name/id, and key metadata (chain/collection)
- [ ] Infinite scroll/pagination loads more items without duplication
- [ ] Search/filter (if available) narrows results appropriately
- [ ] Selection opens Details page

#### Negative
- [ ] Broken media shows placeholder but item remains selectable
- [ ] Network error shows banner; list remains interactable

---

### 3. NFT Details Page
- [ ] Header shows image/animation, title, token id, collection, chain
- [ ] Data rows show attributes/metadata; long text scrolls or wraps
- [ ] Explorer links open externally and resolve
- [ ] Receive/Withdraw actions visible where relevant

#### Edge Cases
- [ ] Very large metadata payload renders without UI freeze
- [ ] Unsupported media displays a neutral placeholder

---

### 4. Receive NFT
- [ ] Receive page shows correct address/QR for the NFT chain
- [ ] Copy/share address works; clipboard contains correct text
- [ ] New address (if supported) reflected in QR and text

#### Negative
- [ ] Offline shows cached address or error without crash
- [ ] Permissions (clipboard) denied → graceful fallback

---

### 5. Withdraw/Send NFT
- [ ] Withdraw form validates recipient, token id, and network fees
- [ ] Preview/confirmation shows summary and fees
- [ ] Successful send shows success view and explorer link

#### Negative
- [ ] Invalid recipient blocked with message
- [ ] Insufficient balance/fees blocked with actionable error
- [ ] Network/broadcast error shows retry; form preserved

#### Edge Cases
- [ ] Hardware wallet rejection cancels cleanly
- [ ] High-latency confirmation updates status without duplicate actions

---

### 6. NFT Transactions
- [ ] Transactions page shows NFT-specific history
- [ ] Mobile and desktop layouts render equivalent information
- [ ] Filters (status/date/type/collection where available) work and combine logically
- [ ] Clicking an item opens details: tx hash, status, timestamp, media preview
- [ ] Copy tx hash shows confirmation; hash copied to clipboard

#### Negative
- [ ] Loading/empty/failure pages render appropriately with retry
- [ ] Explorer link failures do not crash the app

---

### 7. Accessibility and Localization
- [ ] All labels/buttons are localized; long strings truncated with tooltips
- [ ] Screen readers announce media, buttons, and statuses
- [ ] Keyboard navigation through list/grid and actions works (Tab/Enter)

---

### 8. Performance and Stability
- [ ] List renders 100+ items smoothly with images
- [ ] Details open < 300ms; media loads asynchronously with placeholders
- [ ] Receive/Withdraw pages load < 500ms on mid-tier devices

---

### 9. Device/Environment Matrix (see `docs/OS_SUPPORT.md`)
- [ ] Android min + latest; iOS min + latest
- [ ] macOS Intel + Apple Silicon; Windows min + latest; Linux min
- [ ] Offline, captive portal, VPN; flaky network

---

### 10. Post-Execution
- [ ] Document failures with steps and redacted logs
- [ ] Report [issues](https://github.com/KomodoPlatform/komodo-wallet/issues) for failing tests and/or UX enhancements
- [ ] Report [issues](https://github.com/KomodoPlatform/komodo-wallet/issues) for missing or obsolete tests within the QA checklists (if flows changed)
- [ ] Update manual test cases in `docs/qa/MANUAL_TESTING_NOTES.md` 



