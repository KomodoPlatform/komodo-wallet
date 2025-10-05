# Komodo Wallet - New Login Flow Summary

## Quick Reference

**Full Plan**: See `NEW_LOGIN_FLOW_IMPLEMENTATION_PLAN.md`

**Figma Design**: https://www.figma.com/design/yiMzhZa6fXrtUeYsoxXkDP/Work-in-progress?node-id=8831-39188

---

## Critical Issues Identified

### 🚨 MUST FIX IMMEDIATELY

1. **No Seed Backup During Wallet Creation**

   - Users can create wallet and access funds WITHOUT backing up seed phrase
   - **Risk**: Catastrophic fund loss if device is lost
   - **Priority**: CRITICAL - Fix in Phase 1 (Week 1-2)

2. **No Seed Verification**
   - Users might write seed incorrectly
   - No way to verify backup is correct until they need to recover
   - **Priority**: CRITICAL - Fix in Phase 1 (Week 1-2)

### ⚠️ SHOULD FIX SOON

3. **No Passcode/Biometric Auth**

   - Only password authentication
   - Poor UX for daily usage
   - **Priority**: HIGH - Implement in Phase 2 (Week 2-3)

4. **Poor Onboarding Experience**

   - No welcome screen
   - Confusing wallet type selection
   - **Priority**: HIGH - Implement in Phase 2 (Week 2-3)

5. **Suboptimal Import UX**
   - Single text field for seed phrase
   - No autocomplete
   - Error-prone
   - **Priority**: MEDIUM - Improve in Phase 3 (Week 3-4)

---

## Proposed Solution Overview

### New User Journey (Create Wallet)

```
1. Start Screen
   ↓
2. Create 6-digit Passcode
   ↓
3. Confirm Passcode
   ↓
4. Seed Backup Warning (Educational)
   ↓
5. Display Seed Phrase (Write down)
   ↓
6. Confirm Seed (Quiz - verify 3-4 words)
   ↓
7. Setup Biometric (Optional - Face ID/Touch ID)
   ↓
8. Wallet Ready (Success screen)
   ↓
9. Main Wallet View
```

**Steps**: 1 → 8 steps (vs current 1 step)  
**Time**: ~3-5 minutes  
**Security**: ✅ Seed backed up ✅ Verified ✅ Secure auth

### Import Wallet Journey

```
1. Import Method Selection (Secret Phrase / File)
   ↓
2a. Enter Wallet Name
   ↓
2b. Enter Seed Words (1-6 words with autocomplete)
    OR
    Paste Full Seed
   ↓
2c. Select Word Count (12/18/24)
   ↓
3. Create Password
   ↓
4. [Same as create flow from step 7]
```

**Improvements**:

- Word-by-word entry with BIP39 autocomplete
- Visual feedback
- Better error handling
- Separate password step

---

## Implementation Phases (6 Weeks)

### 🔴 Phase 1: Critical Security (Week 1-2)

**Must Have Before Release**

- [ ] Mandatory seed backup flow in wallet creation
- [ ] Seed phrase confirmation screen (quiz)
- [ ] Backup warning banner on wallet view
- [ ] Prevent wallet access without backup

**Impact**: Prevents fund loss  
**Effort**: 5 days development + 3 days testing

---

### 🟡 Phase 2: Passcode & Onboarding (Week 2-3)

**High Priority, Can Release Incrementally**

- [ ] Start/welcome screen
- [ ] 6-digit passcode creation
- [ ] Passcode confirmation
- [ ] Passcode authentication on app launch
- [ ] Biometric (Face ID/Touch ID) integration

**Impact**: Better UX and security  
**Effort**: 7 days development + 3 days testing

---

### 🟢 Phase 3: Import UX (Week 3-4)

**Medium Priority, UX Enhancement**

- [ ] Word-by-word seed entry
- [ ] BIP39 autocomplete
- [ ] Word count selector
- [ ] Improved file import UI
- [ ] Multi-step form with progress

**Impact**: Reduced import errors  
**Effort**: 5 days development + 2 days testing

---

### 🔵 Phase 4: Polish (Week 4-6)

**Low Priority, Nice to Have**

- [ ] Animations and transitions
- [ ] Desktop welcome screen
- [ ] Illustrations and visual polish
- [ ] Performance optimizations
- [ ] Accessibility improvements

**Impact**: Professional feel  
**Effort**: 5 days development + 2 days testing

---

## Key Technical Changes

### New Services

- `PasscodeService` - Manage passcode creation, verification, storage
- `BiometricService` - Handle Face ID/Touch ID authentication
- `OnboardingService` - Track onboarding state and first launch

### New Widgets (23 new + 5 refactored)

- Start screen
- Passcode entry/confirm screens
- Seed backup warning/display/confirmation screens
- Biometric setup screen
- Word input fields with autocomplete
- File drop zone
- Backup warning banner
- Desktop welcome screen

### State Management

- New `OnboardingBloc` for managing flow
- Extended `AuthBloc` with seed backup state
- Passcode verification state

### Dependencies

- `local_auth: ^2.1.0` - Biometric authentication
- Optional: `flutter_animate`, `drop_zone` for better UX

---

## Migration Strategy

### ✅ Backward Compatible

- Existing wallets work unchanged
- No data structure modifications
- Additive features only

### 🔄 Optional for Existing Users

- Passcode setup prompt (skippable)
- Seed backup prompt (banner, not blocking)
- Biometric setup (user preference)

### 🆕 Required for New Users

- Complete onboarding flow
- Mandatory seed backup
- Passcode creation (or skip to password-only)

---

## Success Criteria

| Metric                 | Target | Current | New Flow |
| ---------------------- | ------ | ------- | -------- |
| Seed backup completion | 100%   | ~20%?   | 100%     |
| Onboarding abandonment | <10%   | N/A     | <10%     |
| Import errors          | <5%    | ~15%?   | <5%      |
| Auth convenience       | 3/5    | 2/5     | 4.5/5    |
| Security score         | B      | C       | A        |

---

## Quick Start for Developers

### To Implement Phase 1 (Critical):

1. **Create new directory**: `lib/views/wallets_manager/widgets/onboarding/seed_backup/`

2. **Create 3 new screens**:

   - `seed_backup_warning_screen.dart` - Warning before showing seed
   - `seed_display_screen.dart` - Show seed in grid
   - `seed_confirmation_screen.dart` - Quiz to verify

3. **Modify `iguana_wallets_manager.dart`**:

   - Add new states to state machine
   - Insert seed backup flow after wallet creation
   - Block navigation until confirmed

4. **Create banner**:

   - `backup_warning_banner.dart`
   - Show if `!wallet.config.hasBackup`
   - Add to `wallet_main.dart`

5. **Update `AuthBloc`**:
   - Add `AuthSeedBackupConfirmed` event
   - Set `hasBackup = true` after confirmation

### To Test:

```bash
# Run unit tests
flutter test test_units/

# Run integration test for wallet creation
flutter test test_integration/tests/wallets_manager_tests/

# Manual test checklist
# 1. Create new wallet
# 2. Verify seed backup warning shows
# 3. View seed phrase
# 4. Attempt to skip (should fail)
# 5. Complete seed quiz correctly
# 6. Verify wallet is accessible
# 7. Verify hasBackup = true
```

---

## Communication Plan

### For Users

**Release Notes (Phase 1)**:

> **🔒 Security Improvement**: Seed Phrase Backup Now Required
>
> We've made backing up your wallet more secure! When creating a new wallet, you'll now:
>
> - See clear warnings about seed phrase importance
> - View and write down your 12-word recovery phrase
> - Verify you've written it correctly before accessing your wallet
>
> Existing users: We'll remind you to backup your seed if you haven't already.

**Release Notes (Phase 2)**:

> **✨ New Onboarding Experience**
>
> Welcome to the new Komodo Wallet!
>
> - Beautiful new start screen
> - Quick passcode for easy access (6-digit PIN)
> - Face ID / Touch ID support
> - Step-by-step guided setup

### For Support Team

**FAQs to Prepare**:

1. Why do I need to backup my seed phrase now?
2. I forgot my passcode, how do I access my wallet?
3. What's the difference between password and passcode?
4. Can I skip biometric authentication?
5. I already have a wallet, why am I seeing new screens?

---

## Timeline Visualization

```
Week 1-2: Phase 1 - Critical Security
[████████████████████] SEED BACKUP + CONFIRMATION

Week 2-3: Phase 2 - Passcode & Onboarding
         [████████████████] PASSCODE + BIOMETRIC + START SCREEN

Week 3-4: Phase 3 - Import UX
                  [████████████] WORD-BY-WORD + AUTOCOMPLETE

Week 4-6: Phase 4 - Polish
                            [████████████] ANIMATIONS + DESKTOP

Testing: [═══════════════════════════════════] (Continuous)
```

---

## Resources

- **Figma Design**: [View Designs](https://www.figma.com/design/yiMzhZa6fXrtUeYsoxXkDP/Work-in-progress?node-id=8831-39188)
- **Full Implementation Plan**: `NEW_LOGIN_FLOW_IMPLEMENTATION_PLAN.md`
- **BIP39 Wordlist**: https://github.com/bitcoin/bips/blob/master/bip-0039/english.txt
- **Local Auth Package**: https://pub.dev/packages/local_auth
- **Flutter Animate**: https://pub.dev/packages/flutter_animate

---

## Decision Log

| Date       | Decision                       | Rationale                                   |
| ---------- | ------------------------------ | ------------------------------------------- |
| 2025-10-01 | Make seed backup mandatory     | Critical security issue, prevents fund loss |
| 2025-10-01 | Implement passcode as optional | Better UX without forcing existing users    |
| 2025-10-01 | Phased rollout over 6 weeks    | Allows for testing and iteration            |
| 2025-10-01 | No breaking changes            | Ensures smooth migration                    |

---

**Last Updated**: October 1, 2025

