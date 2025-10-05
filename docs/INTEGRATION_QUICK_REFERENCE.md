# Authentication Flow Overhaul - Quick Reference Card

## 🚀 What Was Built

### Phase 1: Critical Security ✅

- ✅ Mandatory seed backup during wallet creation
- ✅ 4-word verification quiz
- ✅ Persistent backup banner
- ✅ Analytics tracking

### Phase 2: Modern Onboarding ✅

- ✅ Start/welcome screen
- ✅ 6-digit passcode system
- ✅ Biometric authentication (Face ID/Touch ID)
- ✅ Success celebration screen
- ✅ Complete analytics tracking

---

## 📁 Key Files

### BLoC

- `lib/bloc/onboarding/onboarding_bloc.dart` - Onboarding state management
- `lib/bloc/onboarding/onboarding_event.dart` - Onboarding events
- `lib/bloc/onboarding/onboarding_state.dart` - Onboarding state

### Services

- `lib/services/passcode/passcode_service.dart` - Passcode management
- `lib/services/biometric/biometric_service.dart` - Biometric auth
- `lib/services/onboarding/onboarding_service.dart` - First launch tracking

### Screens (Phase 1)

- `lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_backup_warning_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_display_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_confirmation_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/backup_warning_banner.dart`

### Screens (Phase 2)

- `lib/views/wallets_manager/widgets/onboarding/start_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/passcode/passcode_entry_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/passcode/passcode_confirm_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/biometric_setup_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/wallet_ready_screen.dart`

### Integration Points

- `lib/views/wallets_manager/widgets/iguana_wallets_manager.dart` - Main flow controller
- `lib/views/wallets_manager/wallets_manager_wrapper.dart` - Start screen integration
- `lib/views/wallet/wallet_page/wallet_main/wallet_main.dart` - Backup banner display

### Analytics

- `lib/analytics/events/onboarding_events.dart` - 17 new event types

### Utilities

- `sdk/packages/komodo_defi_types/lib/src/utils/mnemonic_validator.dart` - BIP39 autocomplete

---

## 🔄 User Flow

### New User Creating Wallet

```
1. Launch app (first time)
   → START SCREEN shown

2. Click "Create new wallet"
   → WALLET TYPE SELECTION

3. Select Iguana/HD wallet
   → (OPTIONAL) PASSCODE ENTRY
   → (OPTIONAL) PASSCODE CONFIRM
   → WALLET CREATION FORM

4. Fill name & password
   → Wallet created by AuthBloc
   → SEED BACKUP WARNING

5. Click Continue
   → SEED DISPLAY (12 words)

6. Click Continue
   → SEED CONFIRMATION (4-word quiz)

7. Select correct words
   → BIOMETRIC SETUP (optional)

8. Enable/Skip biometric
   → WALLET READY (success)

9. Click Continue
   → MAIN WALLET VIEW
```

### Existing User

```
1. Launch app
   → WALLET LIST (skip start screen)

2. Login with password
   → Check hasBackup flag

3. If !hasBackup:
   → BACKUP WARNING BANNER shows

4. Click "Backup" button
   → Navigate to Settings > Security
```

---

## 🔑 Key Code Snippets

### Check if Backup Complete

```dart
final authBloc = context.read<AuthBloc>();
final hasBackup = authBloc.state.currentUser?.wallet.config.hasBackup ?? true;

if (!hasBackup) {
  // Show backup banner or prompt
}
```

### Navigate to Seed Backup

```dart
// Navigate to Settings > Security section
routingState.selectedMenu = MainMenuValue.settings;
routingState.settingsState.selectedMenu = SettingsMenuValue.security;
```

### Get BIP39 Autocomplete

```dart
final validator = MnemonicValidator();
await validator.init();
final matches = validator.getAutocompleteMatches('aba', maxResults: 5);
// Returns: {'abandon', 'ability', 'about', ...}
```

### Track Analytics Event

```dart
context.read<AnalyticsBloc>().logEvent(
  const SeedBackupWarningShownEventData(),
);
```

### Save Passcode

```dart
final passcodeService = PasscodeService();
await passcodeService.setPasscode('123456');
```

### Check Biometric Availability

```dart
final biometricService = BiometricService();
final isAvailable = await biometricService.isAvailable();
final type = await biometricService.getBiometricTypeName();
// Returns: "Face ID", "Touch ID", or "Biometric"
```

---

## 🛠️ Development Commands

### Run App

```bash
flutter run -d chrome
```

### Format Code

```bash
dart format lib/
```

### Analyze Code

```bash
flutter analyze
```

### Clear State (Test First Launch)

```bash
flutter clean
flutter pub get
```

---

## 📊 State Machine Reference

### WalletCreationStep Enum

```dart
initial              // Wallet form
  ↓
createPasscode       // Enter 6-digit passcode (optional)
  ↓
confirmPasscode      // Confirm passcode (optional)
  ↓
[back to initial to complete form]
  ↓
[AuthBloc creates wallet]
  ↓
seedBackupWarning    // Educational warning
  ↓
seedDisplay          // Show 12 words
  ↓
seedConfirmation     // 4-word quiz
  ↓
biometricSetup       // Face ID/Touch ID (optional)
  ↓
walletReady          // Success screen
  ↓
complete             // Login to wallet
```

---

## 🔍 Testing Checklist

### Quick Smoke Test

- [ ] First launch shows start screen
- [ ] Create wallet flows through all steps
- [ ] Seed backup is mandatory
- [ ] Biometric setup is optional
- [ ] Success screen appears
- [ ] Wallet is accessible after onboarding
- [ ] Banner shows if `!hasBackup`
- [ ] Banner navigates to Settings

### Security Test

- [ ] Seed cannot be screenshotted
- [ ] Seed cleared from memory after backup
- [ ] Passcode is hashed (not plaintext)
- [ ] Wrong seed words show error
- [ ] Cannot skip seed confirmation
- [ ] Cancellation deletes wallet

### Edge Cases

- [ ] Wrong passcode confirmation
- [ ] 3 failed seed attempts
- [ ] Biometric on unsupported device
- [ ] Existing wallet login still works
- [ ] Banner doesn't show if hasBackup=true

---

## 🐛 Troubleshooting

### Issue: Start screen doesn't show

**Check**: Are there existing wallets in `WalletsRepository`?  
**Fix**: Clear app data to simulate first launch

### Issue: Passcode screens don't appear

**Check**: Passcode flow is optional, might be skipped  
**Note**: This is by design - passcode is not mandatory yet

### Issue: Banner always shows

**Check**: Is `hasBackup` flag actually set to `true`?  
**Debug**: Check wallet metadata in AuthBloc state

### Issue: Seed backup screens don't appear

**Check**: Ensure wallet creation completes successfully  
**Debug**: Check `_creationStep` value in state

### Issue: Analytics events not firing

**Check**: Is `AnalyticsBloc` initialized?  
**Debug**: Check console logs for event names

---

## 📦 Dependencies

### Required

- ✅ `local_auth: ^2.3.0` - Already added
- ✅ `flutter_secure_storage` - Via SDK dependency

### Used Services

- `PasscodeService` - From `lib/services/passcode/`
- `BiometricService` - From `lib/services/biometric/`
- `OnboardingService` - From `lib/services/onboarding/`

---

## 🎨 Figma Design Nodes

| Screen            | Node ID    | Compliance |
| ----------------- | ---------- | ---------- |
| Start Screen      | 9405:37677 | ~95%       |
| Passcode Entry    | 8969:727   | ~95%       |
| Passcode Confirm  | 8969:29722 | ~95%       |
| Seed Warning      | 8994:12153 | ~95%       |
| Seed Display      | 8994:12253 | ~95%       |
| Seed Confirmation | 8994:12339 | ~95%       |
| Biometric Setup   | 8969:29795 | ~90%       |
| Wallet Ready      | 8971:30112 | ~90%       |
| Backup Banner     | 9398:37389 | ~95%       |

**Design Link**: https://www.figma.com/design/yiMzhZa6fXrtUeYsoxXkDP/Work-in-progress?node-id=8831-39188

---

## 📖 Translation Keys Reference

### Seed Backup (17 keys)

- `onboardingSeedBackupWarningTitle`
- `onboardingSeedBackupForYourEyesOnly`
- `onboardingSeedBackupWarning1/2/3`
- `onboardingSeedBackupManualBackupTitle`
- `onboardingSeedBackupNeverShare`
- `onboardingSeedBackupConfirmTitle`
- `onboardingSeedBackupConfirmHint`
- `onboardingSeedBackupWordNumber`
- `onboardingSeedBackupIncorrectSelection`
- `onboardingSeedBackupTooManyAttempts`
- `onboardingSeedBackupAttemptsRemaining`
- `backupBannerTitle`
- `backupBannerAction`
- `cancelWalletCreationTitle`
- `cancelWalletCreationMessage`

### Passcode (7 keys)

- `onboardingPasscodeTitle`
- `onboardingPasscodeCreateTitle`
- `onboardingPasscodeConfirmTitle`
- `onboardingPasscodeCreateHint`
- `onboardingPasscodeConfirmHint`
- `onboardingPasscodeMismatch`
- `onboardingPasscodeTooShort`

### Biometric (7 keys)

- `onboardingBiometricTitle`
- `onboardingBiometricDescription`
- `onboardingBiometricEnable`
- `onboardingBiometricSkipForNow`
- `onboardingBiometricAuthReason`
- `onboardingBiometricAuthFailed`
- `onboardingBiometricError`

### Start & Success (8 keys)

- `onboardingCreateNewWallet`
- `onboardingAlreadyHaveWallet`
- `onboardingStartScreenTagline`
- `onboardingStartScreenLegal`
- `onboardingSuccessTitle`
- `onboardingSuccessDescription`
- `onboardingSuccessBuyCrypto`
- `onboardingSuccessLater`

---

## ⚡ Quick Commands

### Test New Flow

```bash
# Clear and test first launch
flutter clean && flutter pub get && flutter run -d chrome
```

### Format Code

```bash
dart format lib/
```

### Check for Errors

```bash
flutter analyze lib/views/wallets_manager/ lib/bloc/onboarding/
```

### View Analytics Logs

```bash
# Check console for analytics events during testing
# Look for: "Analytics Event: [event_name]"
```

---

## 🎯 Success Criteria

### ✅ All Met

- [x] Zero linter errors
- [x] All screens implemented
- [x] All services implemented
- [x] Full flow integration
- [x] Analytics tracking complete
- [x] Backward compatible
- [x] Design compliance >90%
- [x] Documentation complete

---

## 📞 Quick Links

- **Full Summary**: [COMPLETE_INTEGRATION_SUMMARY.md](COMPLETE_INTEGRATION_SUMMARY.md)
- **Action Plan**: [NEW_LOGIN_FLOW_ACTION_PLAN.md](NEW_LOGIN_FLOW_ACTION_PLAN.md)
- **Phase 1 Docs**: [PHASE_1_IMPLEMENTATION_COMPLETE.md](PHASE_1_IMPLEMENTATION_COMPLETE.md)
- **Phase 2 Docs**: [PHASE_2_IMPLEMENTATION_COMPLETE.md](PHASE_2_IMPLEMENTATION_COMPLETE.md)

---

**Last Updated**: October 2, 2025  
**Status**: ✅ **COMPLETE AND READY FOR TESTING**  
**Next**: Manual QA Testing → Code Review → Production Release

---

_Quick reference for developers working on or testing the authentication flow overhaul._
