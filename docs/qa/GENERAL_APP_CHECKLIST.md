## QA Checklist: General App (Cross-Cutting)

App-wide checks not covered by feature-specific lists. Use alongside page-specific checklists.

---
### Test Report ID
- **Pull request**: 
- **Commit hash**: 
- **Username**: 
- **Date**: 
- **Operating system**: 

---

### 1. Startup, Install, and Upgrade
- [ ] Fresh install launches without crash; first-run flows appear
- [ ] Upgrade from previous version preserves data and settings
- [ ] App version/build visible in About/Settings

---

### 2. Navigation and Routing
- [ ] Bottom/top nav items route correctly; back stack behaves as expected
- [ ] Deep links open the correct page and handle locked-state auth
- [ ] External intents (share, explorer links) handled by system/embedded webview

---

### 3. Theming and UI Consistency
- [ ] Light/Dark themes apply across all screens; iconography and text remain legible
- [ ] Typography/fonts load; fallbacks used when fonts missing
- [ ] Layout scales for phone/tablet/desktop; no clipped or overlapping widgets

---

### 4. Localization and i18n
- [ ] Language switching updates all visible strings without restart (if supported)
- [ ] Date/number/currency formats follow locale
- [ ] Fallback language provided for missing keys

---

### 5. Permissions and Privacy
- [ ] Clipboard, camera (QR), storage prompts shown with rationale
- [ ] Denying permissions results in graceful fallback
- [ ] No secrets written to logs or crash reports

---

### 6. Offline and Network Resilience
- [ ] Offline states show banners/placeholders without blocking navigation
- [ ] Flaky network recovers without app restart; retries/backoff present
- [ ] Captive portal doesn’t crash; errors are user-friendly

---

### 7. Error Handling and Toasts/Banners
- [ ] Errors use consistent UI (snackbar/banner/dialog) and never expose stack traces
- [ ] Retry actions are present where meaningful and preserve form state

---

### 8. Analytics and Telemetry
- [ ] Consent gating follows policy; opt-in/out persists
- [ ] No PII or secrets sent in events; event names/params documented
- [ ] Events fire on key flows (onboarding, send, swap, bridge) once per action

---

### 9. Security and Privacy
- [ ] App respects system screenshots/app switcher masking when enabled
- [ ] Sensitive views require re-auth when returning from background after timeout
- [ ] Local storage encrypted; logs redacted; seed/keys never persisted

---

### 10. Performance and Stability
- [ ] Cold start < 2.5s on mid-tier devices; warm start < 1s
- [ ] Smooth scrolling in long lists; no jank around image-heavy screens
- [ ] Memory footprint stable during repeated navigation; no leaks/crashes

---

### 11. Notifications (if applicable)
- [ ] Notification permissions prompt and settings work
- [ ] Tapping notifications navigates to relevant screen

---

### 12. Platform-Specifics
- [ ] Android back handling consistent; no accidental exits or auth bypass
- [ ] iOS safe areas respected; swipe-back works where expected
- [ ] Desktop window sizing, close/minimize behavior correct; Linux GTK deps satisfied

---

### 13. Compliance and Store Readiness
- [ ] App icons/splash correct; adaptive icons configured
- [ ] Privacy policy and licenses accessible from settings/about
- [ ] No debug-only text/assets in release builds

---

### 14. Post-Execution
- [ ] Document failures with steps and redacted logs
- [ ] File issues following `docs/ISSUE.md`
- [ ] Update manual test cases in `docs/MANUAL_TESTING_DEBUGGING.md` if flows changed


