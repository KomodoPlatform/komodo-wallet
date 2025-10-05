# Komodo Wallet - New Login Flow Implementation Plan

## Executive Summary

This document provides a comprehensive plan for implementing the revamped login/onboarding flow based on the Figma designs. The new flow addresses multiple UX and security issues in the current implementation and provides a more modern, intuitive user experience.

**Figma Design Reference**: https://www.figma.com/design/yiMzhZa6fXrtUeYsoxXkDP/Work-in-progress?node-id=8831-39188

---

## Table of Contents

1. [Current Flow Analysis](#current-flow-analysis)
2. [Figma Design Overview](#figma-design-overview)
3. [Key Issues in Current Implementation](#key-issues-in-current-implementation)
4. [New Flow Architecture](#new-flow-architecture)
5. [Implementation Roadmap](#implementation-roadmap)
6. [Technical Specifications](#technical-specifications)
7. [Migration Strategy](#migration-strategy)
8. [Testing Strategy](#testing-strategy)

---

## Current Flow Analysis

### Current User Journey

#### For New Users (Create Wallet):

1. **Wallet Type Selection** → Shows wallet type list (Iguana, Trezor, etc.)
2. **Wallet Creation Form** → Single screen with:
   - Wallet name field
   - Password field
   - Password confirmation field
   - HD/Iguana mode toggle
   - Quick login checkbox
   - EULA/ToS checkboxes
3. **Immediate Login** → User is logged in immediately after creation
4. **No Seed Backup** → Seed backup is deferred to Settings (critical flaw!)

#### For Existing Users (Import Wallet):

1. **Wallet Type Selection**
2. **Import Method Selection** → Simple import or file import
3. **Import Form** → Multi-step:
   - Step 1: Wallet name + seed phrase (single text field)
   - Step 2: Password creation
4. **Immediate Login**

#### For Returning Users:

1. **Wallet List** → Shows existing wallets
2. **Login Form** → Password entry for selected wallet

### Current File Structure

```
lib/views/wallets_manager/
├── wallets_manager_wrapper.dart         # Entry point, shows wallet type list
├── widgets/
│   ├── wallets_manager.dart             # Routes to Iguana or Hardware manager
│   ├── iguana_wallets_manager.dart      # Main state machine for Iguana wallets
│   ├── wallet_creation.dart             # Create new wallet form
│   ├── wallet_login.dart                # Login to existing wallet
│   ├── wallet_import_wrapper.dart       # Import method selector
│   ├── wallet_simple_import.dart        # Import by seed phrase
│   ├── wallet_import_by_file.dart       # Import by encrypted file
│   ├── wallets_list.dart                # List of existing wallets
│   ├── wallets_manager_controls.dart    # Create/Import buttons
│   └── wallets_type_list.dart           # Wallet type selection
```

---

## Figma Design Overview

### New User Journey (Mobile)

The Figma design shows a complete redesign with the following flow:

#### 1. **Start Screen** (NEW)

- **Purpose**: Welcome/onboarding screen for first-time users
- **UI Elements**:
  - Hero visual (blockchain graphic/illustration)
  - Tagline: "Own, control, and leverage the power of your digital assets"
  - Primary CTA: "Create new wallet"
  - Secondary CTA: "I already have a wallet"
  - Legal disclaimer (ToS/Privacy Policy)
- **Node IDs**: `9405:37677`, `9586:584`, `9602:6318`

#### 2. **Create New Wallet Flow**

**2a. Passcode Creation** (NEW)

- **Purpose**: Set up PIN/passcode for quick access
- **UI Elements**:
  - Title: "Create passcode"
  - Description: "Enter your passcode. Be sure to remember it so you can unlock your wallet."
  - 6-digit PIN entry visualization (dots)
  - Numeric keypad
  - Back button
- **Node IDs**: `8969:727`, `8986:852`

**2b. Passcode Confirmation** (NEW)

- **Purpose**: Verify passcode entry
- **UI Elements**:
  - Title: "Confirm passcode"
  - Description: "Re-enter your passcode..."
  - Same PIN entry UI
- **Node IDs**: `8969:29722`, `8986:895`, `9079:26316`

**2c. Seed Phrase Backup Warning** (NEW)

- **Purpose**: Educate user about seed phrase importance BEFORE showing it
- **UI Elements**:
  - Illustration/icon
  - Title: "This secret phrase unlocks your wallet"
  - Warning: "For your eyes only!"
  - Three key points with icons:
    - "Komodo wallet does not have access to this key."
    - "Don't save this in any digital format, write it on paper and store securely."
    - "If you lose your recovery phrase and device, your coins will be permanently lost..."
  - Primary CTA: "Continue"
- **Node IDs**: `8994:12153`, `9207:1546`

**2d. Manual Seed Phrase Display** (NEW)

- **Purpose**: Show 12/24 word seed phrase in a grid layout
- **UI Elements**:
  - Title: "Manual backup"
  - 12 words displayed in 2-column grid with numbers
  - Close button (X)
  - Warning banner at bottom: "Never share your secret phrase..."
  - Primary CTA: "Continue"
- **Node IDs**: `8994:12253`, `9079:25669`

**2e. Seed Phrase Confirmation** (NEW - CRITICAL)

- **Purpose**: Verify user has written down seed phrase correctly
- **UI Elements**:
  - Title: "Confirm secret phrase"
  - Description: "Please tap on the correct answer of the below seed phrases."
  - Interactive word selection for random words (e.g., Word #1, #7, #9, #12)
  - Multiple choice buttons for each word
  - Checkmark indication on correct selection
  - Primary CTA: "Continue"
- **Node IDs**: `8994:12339`, `9079:25713`

**2f. Biometric Setup** (NEW - Optional)

- **Purpose**: Enable Face ID/Touch ID
- **UI Elements**:
  - Icon/illustration for Face ID
  - Title: "Secure your wallet"
  - Description: "Turn on Face ID to secure your wallet."
  - Primary CTA: "Enable Face ID"
  - Secondary CTA: "Skip for now"
- **Node IDs**: `8969:29795`, `9071:15464`

**2g. Completion/Welcome** (NEW)

- **Purpose**: Congratulate user and prompt next actions
- **UI Elements**:
  - Illustration
  - Title: "Brilliant, your wallet is ready!"
  - Description: "Buy or deposit to get started."
  - Primary CTA: "Buy Crypto"
  - Secondary CTA: "I'll do this later"
- **Node IDs**: `8971:30112`

#### 3. **Import Existing Wallet Flow**

**3a. Import Method Selection** (UPDATED)

- **Purpose**: Choose how to import wallet
- **UI Elements**:
  - Title: "Add existing wallet"
  - Section: "Most popular"
    - Option: "Secret phrase" (with expand icon)
    - Option: "Import seed file" (with expand icon)
- **Node IDs**: `8986:999`, `9067:15391`

**3b. Import by Secret Phrase** (UPDATED)

- **Multi-step improved UX**:
  - Step 1: Wallet name input field
  - Step 2: Secret phrase input with:
    - Dropdown selector for word count (12/18/24 word phrase)
    - Individual numbered input fields (1-6, 7-12, etc.) OR full paste area
    - Autocomplete suggestions from BIP39 wordlist
  - Step 3: Password creation (separate screen)
  - Primary CTA: "Continue" / "Import"
  - Legal disclaimer checkbox
- **Node IDs**: `9079:26393`, `9398:37490`, `9085:48171`, `9079:26478`, `9398:37401`

**3c. Import by Seed File** (UPDATED)

- **UI Elements**:
  - Title: "Import Seed file"
  - Description: "Import file by clicking Browse or by dragging and dropping it below."
  - Wallet name input field
  - File upload drop zone with "Choose File" button
  - Password field for encrypted file
  - Confirm password field
  - Checkbox: "Legacy Komodo Wallet Seed" (with info popup)
  - Primary CTA: "Import"
- **Node IDs**: `9085:48669`, `9398:37596`

**3d. Legacy Seed Info Modal** (NEW)

- **Purpose**: Explain legacy seed format
- **UI Elements**:
  - Title: "Legacy Komodo Wallet Seed"
  - Description: "Seed phrase generated by komodo wallet before may 2025 release"
  - Primary CTA: "Got it"
- **Node IDs**: `9398:37543`, `9398:37643`

#### 4. **Desktop Welcome Screen** (NEW)

**4a. Desktop Connect Wallet** (NEW)

- **Purpose**: Unified entry point for desktop users
- **UI Elements**:
  - Komodo logo/branding
  - Title: "Welcome to Komodo Wallet"
  - Close button (X)
  - Primary CTA: "Create new wallet"
  - Secondary CTA: "I already have a wallet"
  - Section: "or connect with"
    - "WalletConnect" button
    - "Hardware Wallet" button
    - "Connect Keplr" button (disabled/coming soon)
- **Node IDs**: `9030:25797`, `9095:6441`

**4b. Desktop Password Creation** (NEW)

- **Purpose**: Create password for wallet encryption
- **UI Elements**:
  - Title: "Create a new password"
  - Description: "Enter a strong password to encrypt your wallet. This is how you will access it."
  - Info note: "Note: If you forgot your password, Komodo can't help you recover it."
  - Wallet name field
  - Password field
  - Confirm password field
  - EULA/ToS checkbox
  - Primary CTA: "Continue"
- **Node IDs**: `9030:26394`, `9030:26613`

**4c. Desktop Seed Input** (NEW)

- **Purpose**: Import wallet via seed phrase on desktop
- **UI Elements**:
  - Title: "Add Existing Wallet"
  - Description: "You can paste your entire secret recovery phrase into any field"
  - Grid of word input fields (12 words in 3 columns, with autocomplete)
  - Dropdown: Word phrase selector (12/18/24)
  - Checkbox: "Legacy Komodo Wallet Seed"
  - Password fields
  - Primary CTA: "Continue"
- **Node IDs**: `9030:26613`, `9054:14028`, `9398:37401`

**4d. Desktop Seed Safety Check** (NEW)

- **Purpose**: Warning screen before showing seed
- **UI Elements**:
  - Illustration
  - Title: "Check your secret phrase is safe"
  - Three checkpoints:
    - "Only you know this secret phrase."
    - "This secret phrase was NOT given to you by anyone, e.g. a company representative." (x2)
  - Primary CTA: "Continue"
- **Node IDs**: `9030:26613`, `8987:11183`

**4e. Desktop Main Wallet View** (NEW)

- **Purpose**: Post-login wallet dashboard
- **UI Elements**:
  - Header with settings
  - Sidebar navigation
  - Total Investment card
  - All time profit card
  - Asset list with search/filters
  - Revenue graph
  - Tab bar (Wallet, Portfolio, NFTs, Settings)
  - **Important**: Shows backup warning banner if seed not backed up
    - "Komodo wallet requires you to backup your seed phrase!"
    - CTA: "Backup"
- **Node IDs**: `9079:25140`, `9044:35903`, `9398:37389`

---

## Key Issues in Current Implementation

### Critical Issues

1. **No Seed Backup During Onboarding** 🚨

   - **Current**: Users are logged in immediately after wallet creation without backing up seed
   - **Risk**: Users may lose access to funds if they lose device before backing up
   - **Impact**: HIGH - This is a critical security/UX flaw

2. **No Seed Confirmation** 🚨

   - **Current**: No verification that user has correctly written down seed phrase
   - **Risk**: Users may write seed incorrectly and discover this only when trying to recover
   - **Impact**: HIGH

3. **Password-Only Security**

   - **Current**: Only password authentication, no biometric option
   - **Impact**: MEDIUM - Reduces convenience and may encourage weak passwords

4. **No Onboarding Experience**

   - **Current**: Directly shows wallet type selection dialog
   - **Impact**: MEDIUM - Confusing for new users, no value proposition

5. **Poor Import UX**
   - **Current**: Single text field for entire seed phrase
   - **Issue**: No word-by-word entry, no autocomplete, error-prone
   - **Impact**: MEDIUM

### UX Issues

6. **Cluttered Form Design**

   - **Current**: All fields (name, password, confirmation, toggles, checkboxes) on one screen
   - **Impact**: LOW-MEDIUM - Overwhelming for users

7. **No Visual Hierarchy**

   - **Current**: Plain form with no illustrations or visual guidance
   - **Impact**: LOW - Less engaging, harder to understand importance

8. **Limited Desktop Experience**

   - **Current**: Same flow for mobile and desktop
   - **Impact**: LOW - Missed opportunity for better desktop UX

9. **No Wallet Type Education**

   - **Current**: Shows "Wallet Type List" with no explanation
   - **Impact**: LOW-MEDIUM - Confusing for average users

10. **No Connection Options**
    - **Current**: No integration for WalletConnect, external wallets
    - **Impact**: MEDIUM - Limited connectivity with DeFi ecosystem

---

## New Flow Architecture

### State Machine Design

```dart
enum OnboardingStep {
  // New user flow
  splash,                    // NEW: Start screen
  createPasscode,            // NEW: PIN entry
  confirmPasscode,           // NEW: PIN confirmation
  seedBackupWarning,         // NEW: Warning before showing seed
  seedDisplay,               // NEW: Show seed phrase
  seedConfirmation,          // NEW: Verify seed backup
  biometricSetup,            // NEW: Optional Face ID/Touch ID
  walletReady,               // NEW: Success screen

  // Import flow
  importMethodSelection,     // UPDATED: Secret phrase vs file
  importSecretPhrase,        // UPDATED: Improved word-by-word entry
  importFile,                // UPDATED: Better file import UX
  createPassword,            // UPDATED: Separate password step

  // Existing wallet flow
  walletList,                // EXISTING: List of wallets
  walletLogin,               // EXISTING: Password entry
}
```

### Navigation Flow Diagram

```
┌─────────────────┐
│  Start Screen   │ (First launch only)
│  (9405:37677)   │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    v         v
[Create]  [Import]
    │         │
    │         └──────────────────────┐
    │                                │
    v                                v
┌─────────────────┐          ┌──────────────────┐
│ Create Passcode │          │ Import Method    │
│  (8969:727)     │          │  (8986:999)      │
└────────┬────────┘          └────────┬─────────┘
         │                            │
         v                       ┌────┴────┐
┌─────────────────┐              │         │
│Confirm Passcode │              v         v
│  (8969:29722)   │         [Phrase]   [File]
└────────┬────────┘              │         │
         │                       v         v
         v                   ┌─────────────────┐
┌─────────────────┐          │ Enter Name +    │
│ Backup Warning  │          │ Seed (Words)    │
│  (8994:12153)   │          │  (9079:26393)   │
└────────┬────────┘          └────────┬─────────┘
         │                            │
         v                            v
┌─────────────────┐          ┌──────────────────┐
│  Show Seed      │          │ Create Password  │
│  (8994:12253)   │          │  (9030:26394)    │
└────────┬────────┘          └────────┬─────────┘
         │                            │
         v                            │
┌─────────────────┐                  │
│ Confirm Seed    │                  │
│  (8994:12339)   │                  │
└────────┬────────┘                  │
         │                            │
         v                            │
┌─────────────────┐                  │
│Biometric Setup  │                  │
│  (Optional)     │                  │
│  (8969:29795)   │                  │
└────────┬────────┘                  │
         │                            │
         └────────────┬───────────────┘
                      │
                      v
              ┌──────────────────┐
              │  Wallet Ready    │
              │  (8971:30112)    │
              └──────────────────┘
                      │
                      v
              ┌──────────────────┐
              │  Main Wallet     │
              │  (9079:25140)    │
              └──────────────────┘
```

### Desktop-Specific Flow

```
┌─────────────────────┐
│  Welcome Screen     │
│  (9030:25797)       │
│                     │
│  - Create wallet    │
│  - Import wallet    │
│  - WalletConnect    │
│  - Hardware Wallet  │
│  - Keplr (soon)     │
└─────────┬───────────┘
          │
          └──> [Routes to respective flows]
```

---

## Implementation Roadmap

### Phase 1: Foundation & Critical Fixes (Week 1-2)

#### Priority: CRITICAL

**Goal**: Fix the seed backup security flaw

**Tasks**:

1. ✅ **Implement Mandatory Seed Backup Flow**

   - Create `SeedBackupWarningScreen` widget
   - Create `SeedDisplayScreen` widget
   - Create `SeedConfirmationScreen` widget
   - Integrate into wallet creation flow
   - Prevent wallet access until seed is confirmed
   - Update `AuthBloc` to track backup completion state

2. ✅ **Add Backup Warning Banner**
   - Create persistent banner component
   - Show on main wallet view if `!hasBackup`
   - Track dismissal state
   - Deep link to backup flow

**Files to Create**:

- `lib/views/wallets_manager/widgets/onboarding/seed_backup_warning_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/seed_display_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/seed_confirmation_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/backup_warning_banner.dart`

**Files to Modify**:

- `lib/views/wallets_manager/widgets/iguana_wallets_manager.dart` - Add backup flow to state machine
- `lib/bloc/auth_bloc/auth_bloc.dart` - Track backup completion
- `lib/views/wallet/wallet_page/wallet_main/wallet_main.dart` - Add banner

**Acceptance Criteria**:

- [ ] Users CANNOT access wallet without completing seed backup
- [ ] Seed confirmation requires 3-4 random words to be selected correctly
- [ ] Banner shows until seed is backed up
- [ ] Existing users are not affected (hasBackup flag is preserved)

---

### Phase 2: Start Screen & Passcode (Week 2-3)

#### Priority: HIGH

**Goal**: Implement new onboarding entry point and passcode authentication

**Tasks**:

1. ✅ **Create Start/Splash Screen**

   - Build animated start screen widget
   - Add illustrations/graphics from assets
   - Implement first-launch detection
   - Route to appropriate flow (start screen vs wallet list)

2. ✅ **Implement Passcode System**

   - Create passcode entry widget with numeric keypad
   - Create passcode confirmation screen
   - Implement local passcode storage (encrypted)
   - Add biometric authentication integration
   - Create passcode verification on app launch
   - Add "Forgot passcode?" recovery flow

3. ✅ **Biometric Integration**
   - Add `local_auth` package dependency
   - Create biometric setup screen
   - Implement Face ID/Touch ID authentication
   - Add fallback to passcode
   - Store biometric preference

**Files to Create**:

- `lib/views/wallets_manager/widgets/onboarding/start_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/passcode_entry_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/passcode_confirm_screen.dart`
- `lib/views/wallets_manager/widgets/onboarding/biometric_setup_screen.dart`
- `lib/services/passcode/passcode_service.dart`
- `lib/services/passcode/passcode_storage.dart`
- `lib/services/biometric/biometric_service.dart`

**Files to Modify**:

- `lib/main.dart` - Add first-launch detection
- `lib/views/main_layout/main_layout.dart` - Check passcode on resume
- `pubspec.yaml` - Add `local_auth` dependency

**Acceptance Criteria**:

- [ ] Start screen shows on first launch only
- [ ] 6-digit passcode can be created and confirmed
- [ ] Passcode is required on app launch/resume
- [ ] Biometric authentication works when enabled
- [ ] Users can disable passcode/biometric in Settings
- [ ] Passcode can be reset if forgotten (via password re-entry)

---

### Phase 3: Improved Import UX (Week 3-4)

#### Priority: MEDIUM

**Goal**: Modernize import experience with better UX

**Tasks**:

1. ✅ **Word-by-Word Seed Entry**

   - Create numbered input field component
   - Implement BIP39 word autocomplete
   - Add word count selector (12/18/24)
   - Support both word-by-word AND full paste
   - Real-time validation per word

2. ✅ **Enhanced File Import**

   - Improve file drop zone UI
   - Add drag-and-drop support
   - Better error messaging
   - Legacy seed detection and handling

3. ✅ **Multi-Step Form Flow**
   - Split import into logical steps
   - Add progress indicators
   - Implement smooth transitions
   - Enable back navigation

**Files to Create**:

- `lib/views/wallets_manager/widgets/import/word_input_field.dart`
- `lib/views/wallets_manager/widgets/import/word_autocomplete_overlay.dart`
- `lib/views/wallets_manager/widgets/import/seed_word_count_selector.dart`
- `lib/views/wallets_manager/widgets/import/file_drop_zone.dart`
- `lib/views/wallets_manager/widgets/import/legacy_seed_info_dialog.dart`

**Files to Modify**:

- `lib/views/wallets_manager/widgets/wallet_simple_import.dart` - Refactor to multi-step
- `lib/views/wallets_manager/widgets/wallet_import_by_file.dart` - Improve UI

**Acceptance Criteria**:

- [ ] Word-by-word entry with autocomplete works smoothly
- [ ] Full paste into any field is supported
- [ ] Word count selector changes number of visible fields
- [ ] File drag-and-drop works on web and desktop
- [ ] Legacy seed checkbox shows info modal
- [ ] Back navigation works through all steps

---

### Phase 4: UI/UX Polish (Week 4-5)

#### Priority: MEDIUM

**Goal**: Match Figma designs with animations and polish

**Tasks**:

1. ✅ **Design System Updates**

   - Update color palette to match designs
   - Create new component variants
   - Add illustrations/icons from Figma
   - Implement consistent spacing/padding

2. ✅ **Animations & Transitions**

   - Add screen transition animations
   - Implement PIN dot fill animation
   - Add success checkmarks
   - Create loading states

3. ✅ **Desktop-Specific Layouts**

   - Create desktop welcome screen
   - Optimize form layouts for desktop
   - Add sidebar navigation for wallet manager
   - Implement modal vs full-screen patterns

4. ✅ **Responsive Design**
   - Ensure all new screens work on mobile
   - Optimize layouts for tablets
   - Test on various screen sizes

**Files to Create**:

- `lib/views/wallets_manager/widgets/desktop/desktop_welcome_screen.dart`
- `lib/shared/widgets/animations/pin_dot_animation.dart`
- `lib/shared/widgets/onboarding/onboarding_illustration.dart`

**Files to Modify**:

- `app_theme/lib/src/*` - Update theme colors
- Multiple widget files - Add animations

**Acceptance Criteria**:

- [ ] All screens match Figma pixel-perfect (within reason)
- [ ] Smooth animations between screens
- [ ] Desktop and mobile layouts are optimized
- [ ] Illustrations render correctly

---

### Phase 5: Testing & Migration (Week 5-6)

#### Priority: HIGH

**Goal**: Ensure stability and smooth migration

**Tasks**:

1. ✅ **Unit Tests**

   - Test passcode service
   - Test seed confirmation logic
   - Test word autocomplete
   - Test form validation

2. ✅ **Integration Tests**

   - Test complete create wallet flow
   - Test complete import flows
   - Test passcode lock/unlock
   - Test biometric flow

3. ✅ **Migration Logic**

   - Detect existing users
   - Skip start screen for existing users
   - Optional passcode setup for existing users
   - Migrate hasBackup flag

4. ✅ **Documentation**
   - Update user documentation
   - Create developer documentation
   - Document new flows

**Files to Create**:

- `test_units/services/passcode_service_test.dart`
- `test_units/views/seed_confirmation_test.dart`
- `test_integration/tests/new_onboarding_flow_test.dart`
- `docs/NEW_LOGIN_FLOW.md`

**Acceptance Criteria**:

- [ ] All unit tests pass
- [ ] Integration tests cover happy paths
- [ ] Existing users can still log in
- [ ] No data loss during migration

---

## Technical Specifications

### New Data Models

#### 1. Passcode Configuration

```dart
class PasscodeConfig {
  final String hashedPasscode;  // Hashed passcode for verification
  final bool isEnabled;
  final bool biometricEnabled;
  final DateTime lastUpdated;

  // Storage key
  static const String storageKey = 'app_passcode_config';
}
```

#### 2. Onboarding State

```dart
class OnboardingState {
  final bool hasSeenStartScreen;
  final bool hasCompletedOnboarding;
  final DateTime? firstLaunchDate;

  static const String storageKey = 'onboarding_state';
}
```

#### 3. Seed Backup Verification

```dart
class SeedBackupVerification {
  final List<int> wordIndices;        // Random word indices to verify (e.g., [0, 6, 8, 11])
  final Map<int, String> correctWords; // Map of index to correct word
  final int attemptsRemaining;

  // Generate random word selection for verification
  static SeedBackupVerification generate(String seedPhrase) { ... }
}
```

### New Services

#### 1. PasscodeService

```dart
class PasscodeService {
  // Create and store a new passcode
  Future<void> setPasscode(String passcode);

  // Verify a passcode attempt
  Future<bool> verifyPasscode(String passcode);

  // Check if passcode is enabled
  Future<bool> isPasscodeEnabled();

  // Enable/disable passcode
  Future<void> setPasscodeEnabled(bool enabled);

  // Reset passcode (requires password)
  Future<void> resetPasscode(String walletPassword);

  // Hash passcode securely
  String _hashPasscode(String passcode);
}
```

#### 2. BiometricService

```dart
class BiometricService {
  // Check if biometrics are available
  Future<bool> isAvailable();

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics();

  // Authenticate with biometrics
  Future<bool> authenticate({required String reason});

  // Check if biometric is enabled for app
  Future<bool> isEnabled();

  // Enable/disable biometric auth
  Future<void> setEnabled(bool enabled);
}
```

#### 3. OnboardingService

```dart
class OnboardingService {
  // Check if user has seen start screen
  Future<bool> hasSeenStartScreen();

  // Mark start screen as seen
  Future<void> markStartScreenSeen();

  // Check if this is first launch
  Future<bool> isFirstLaunch();

  // Get onboarding state
  Future<OnboardingState> getState();
}
```

### New Widgets (Complete List)

#### Onboarding Screens

1. `StartScreen` - Initial welcome screen
2. `PasscodeEntryScreen` - Create passcode with keypad
3. `PasscodeConfirmScreen` - Confirm passcode
4. `SeedBackupWarningScreen` - Warning before showing seed
5. `SeedDisplayScreen` - Display seed phrase in grid
6. `SeedConfirmationScreen` - Verify seed backup with quiz
7. `BiometricSetupScreen` - Optional biometric setup
8. `WalletReadyScreen` - Success/completion screen

#### Import Screens

9. `ImportMethodSelectionScreen` - Choose import method (updated)
10. `ImportByPhraseScreen` - Word-by-word seed entry (updated)
11. `ImportByFileScreen` - File upload with improved UX (updated)
12. `PasswordCreationScreen` - Separate password step
13. `LegacySeedInfoDialog` - Info modal for legacy seeds

#### Desktop-Specific

14. `DesktopWelcomeScreen` - Desktop entry point
15. `DesktopSeedSafetyCheckScreen` - Desktop-specific warning

#### Shared Components

16. `PinDotIndicator` - Visual PIN entry dots
17. `NumericKeypad` - Custom numeric keypad widget
18. `WordInputField` - Individual word input with autocomplete
19. `WordAutocompleteOverlay` - BIP39 word suggestions
20. `SeedWordCountSelector` - Dropdown for 12/18/24 words
21. `FileDropZone` - Drag-and-drop file upload
22. `BackupWarningBanner` - Persistent backup reminder
23. `OnboardingIllustration` - Reusable illustration component

### State Management Changes

#### AuthBloc Extensions

```dart
// New Events
class AuthPasscodeVerifyRequested extends AuthEvent {
  final String passcode;
}

class AuthBiometricVerifyRequested extends AuthEvent {}

class AuthSeedBackupStarted extends AuthEvent {}

class AuthSeedBackupDisplayed extends AuthEvent {
  final String seedPhrase;
}

class AuthSeedBackupConfirmed extends AuthEvent {
  final bool isCorrect;
}

// New State Properties
class AuthBlocState {
  // ... existing properties

  final bool isSeedBackupRequired;
  final bool isSeedBackupInProgress;
  final SeedBackupVerification? currentVerification;
  final bool isPasscodeLocked;
}
```

#### New Bloc: OnboardingBloc

```dart
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  // Manages onboarding flow state
  // Tracks current step
  // Handles navigation between steps
  // Stores temporary data (passcode, name, etc.)
}
```

### Routing Updates

#### New Routes

```dart
// Add to routing configuration
class OnboardingRoutes {
  static const String start = '/onboarding/start';
  static const String createPasscode = '/onboarding/create-passcode';
  static const String confirmPasscode = '/onboarding/confirm-passcode';
  static const String seedWarning = '/onboarding/seed-warning';
  static const String seedDisplay = '/onboarding/seed-display';
  static const String seedConfirm = '/onboarding/seed-confirm';
  static const String biometricSetup = '/onboarding/biometric-setup';
  static const String walletReady = '/onboarding/ready';
}
```

### Dependencies to Add

```yaml
# pubspec.yaml additions
dependencies:
  local_auth: ^2.1.0 # Biometric authentication
  local_auth_android: ^1.0.0 # Android implementation
  local_auth_ios: ^1.1.0 # iOS implementation
  crypto: ^3.0.3 # For passcode hashing (may already exist)

  # Optional enhancements
  flutter_animate: ^4.5.0 # Smooth animations
  drop_zone: ^0.0.2 # Drag-and-drop file upload (web)
```

---

## Migration Strategy

### Detecting Existing vs New Users

```dart
class UserMigrationService {
  Future<bool> isExistingUser() async {
    final walletsRepo = getIt<WalletsRepository>();
    final wallets = await walletsRepo.getWallets();
    return wallets.isNotEmpty;
  }

  Future<bool> needsPasscodeSetup() async {
    if (!await isExistingUser()) return false;
    final passcodeService = getIt<PasscodeService>();
    return !await passcodeService.isPasscodeEnabled();
  }

  Future<bool> needsSeedBackup(Wallet wallet) async {
    return !wallet.config.hasBackup;
  }
}
```

### Migration Flow for Existing Users

1. **On App Launch**:

   - Check if user has existing wallets
   - If yes → Skip start screen, show wallet list
   - If no → Show start screen

2. **Optional Passcode Setup**:

   - After successful login, prompt: "Secure your wallet with a passcode?"
   - Allow "Later" option
   - Don't force existing users

3. **Seed Backup Prompt**:
   - If `!hasBackup` → Show backup warning banner
   - Make backup accessible from Settings
   - Track backup completion

### Data Migration

```dart
// No breaking changes to existing data structures
// New fields are optional:
class Wallet {
  // ... existing fields

  // Already exists, just ensure it's used correctly
  final bool hasBackup;  // Default: false for old wallets
}

// New storage keys (won't affect existing data)
- 'app_passcode_config'
- 'onboarding_state'
- 'biometric_preference'
```

---

## Testing Strategy

### Unit Tests

```dart
// test_units/services/passcode_service_test.dart
testWidgets('PasscodeService - Create and verify passcode', (tester) async {
  final service = PasscodeService();
  await service.setPasscode('123456');
  expect(await service.verifyPasscode('123456'), true);
  expect(await service.verifyPasscode('654321'), false);
});

// test_units/views/seed_confirmation_test.dart
testWidgets('SeedConfirmation - Correct selection succeeds', (tester) async {
  // Test seed confirmation logic
});
```

### Integration Tests

```dart
// test_integration/tests/new_onboarding_flow_test.dart
testWidgets('Complete new wallet creation flow', (tester) async {
  // 1. Launch app (first time)
  await tester.pumpWidget(app);

  // 2. Verify start screen shown
  expect(find.text('Create new wallet'), findsOneWidget);

  // 3. Tap create wallet
  await tester.tap(find.text('Create new wallet'));
  await tester.pumpAndSettle();

  // 4. Create passcode
  // ... enter 6 digits

  // 5. Confirm passcode
  // ... re-enter 6 digits

  // 6. See seed backup warning
  expect(find.text('For your eyes only!'), findsOneWidget);

  // 7. View seed phrase
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // 8. Confirm seed phrase
  // ... select correct words

  // 9. Skip biometric (or setup)

  // 10. See success screen
  expect(find.text('your wallet is ready!'), findsOneWidget);
});
```

### Manual Test Cases

1. **First Launch**:

   - [ ] Start screen appears
   - [ ] Can create new wallet
   - [ ] Can import existing wallet
   - [ ] Legal disclaimers are visible

2. **Create Wallet**:

   - [ ] Passcode entry works (6 digits)
   - [ ] Passcode confirmation validates correctly
   - [ ] Wrong confirmation shows error
   - [ ] Seed backup warning is clear
   - [ ] Seed phrase displays correctly
   - [ ] Seed confirmation requires correct words
   - [ ] Wrong word selection shows error
   - [ ] Cannot proceed without correct verification
   - [ ] Biometric setup is optional
   - [ ] Success screen appears

3. **Import Wallet**:

   - [ ] Method selection shows both options
   - [ ] Word-by-word entry works
   - [ ] Autocomplete suggests valid BIP39 words
   - [ ] Can paste full seed
   - [ ] Word count selector works
   - [ ] File upload works (browse & drag-drop)
   - [ ] Legacy seed checkbox works
   - [ ] Password creation step is separate
   - [ ] Import completes successfully

4. **Passcode Auth**:

   - [ ] App locks on background
   - [ ] Passcode required on return
   - [ ] Biometric works when enabled
   - [ ] Wrong passcode shows error
   - [ ] Can reset passcode via password

5. **Backup Warning**:
   - [ ] Banner shows on main wallet if not backed up
   - [ ] Banner dismisses after backup
   - [ ] Tapping banner starts backup flow

---

## Detailed Component Specifications

### 1. StartScreen

**Layout**:

- Full-screen background with gradient
- Hero illustration (blockchain/crypto visual)
- Centered content area
- Tagline text
- Two action buttons (Create / Import)
- Footer with legal disclaimer

**Behavior**:

- Shows only on first app launch
- Stores flag in local storage after display
- Animate entrance on first show
- Buttons navigate to respective flows

**Design Tokens**:

- Background: `#0C1020`
- Primary button: `#3D77E9`
- Secondary button: `#202337`
- Text: `#EAEBEF` / `#E9EAEE`
- Heading: Manrope Bold 28px / line-height 36px

---

### 2. PasscodeEntryScreen

**Layout**:

- Header with back button and title
- Centered content:
  - Title: "Create passcode"
  - Instruction text
  - 6 PIN dot indicators
  - Custom numeric keypad (1-9, 0, delete)

**Behavior**:

- Auto-advance when 6 digits entered
- Visual feedback on each digit
- Delete button removes last digit
- Vibration feedback on input (mobile)
- Validate minimum length

**Design Tokens**:

- Dot container: `#2B2D40` (empty), `#3D77E9` (filled)
- Dot: `#ADAFC4` (obscured)
- Keypad background: `#222229` (with blur)
- Text: `#ADAFC4`

**Security**:

- Store hashed passcode only
- Use bcrypt or Argon2 for hashing
- Rate limit failed attempts
- Auto-lock after 5 failed attempts

---

### 3. SeedBackupWarningScreen

**Layout**:

- Modal overlay OR full screen
- Top section: Illustration + decorative elements
- Middle: Title + warning icon
- Bottom: Three warning boxes with icons
- Primary action button

**Behavior**:

- Cannot be skipped
- Must tap Continue to proceed
- Can go back to cancel wallet creation

**Design Tokens**:

- Background: `#060B1C` / `#0C1020`
- Warning boxes: `#171926`
- Icon: Warning icon (eye, paper, lock)
- Text: `#ADAFC4`

---

### 4. SeedDisplayScreen

**Layout**:

- Header with close button
- Title: "Manual backup"
- 12 words in 2-column grid (6x2)
- Each word: numbered pill button
- Bottom: Warning text with icon
- Primary action button

**Behavior**:

- Words are selectable for copy (optional, debatable for security)
- Close button confirms user wants to exit
- Screenshot protection on mobile
- Warning remains visible

**Design Tokens**:

- Word pill: `#2B2D40`
- Word text: `#ADAFC4`
- Number: Prefixed to word
- Warning: Icon + text

---

### 5. SeedConfirmationScreen

**Layout**:

- Header with close button
- Title: "Confirm secret phrase"
- Instruction text
- 3-4 verification questions:
  - "Word #X" label
  - 3 multiple choice buttons
- Primary action button

**Behavior**:

- Randomly select 3-4 words from seed
- Generate 2 random incorrect options per word
- Highlight correct selection (checkmark icon)
- All words must be correct to continue
- Show error if incorrect
- Limit to 3 attempts

**Design Tokens**:

- Word button: `#2B2D40` (unselected), `#3D77E9` (selected)
- Checkmark: Green icon on selection
- Text: `#ADAFC4`

---

### 6. WordInputField Component

**Layout**:

- Individual input field for one word
- Label: "Word #X"
- Autocomplete dropdown
- Number prefix (1., 2., etc.)

**Behavior**:

- Autocomplete from BIP39 wordlist
- Filter suggestions as user types
- Accept only valid BIP39 words (unless custom seed allowed)
- Support paste of full seed into any field (smart detection)
- Auto-focus next field on valid entry

**Implementation**:

```dart
class WordInputField extends StatefulWidget {
  final int wordNumber;
  final TextEditingController controller;
  final bool allowCustomSeed;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final void Function(String word)? onWordEntered;

  @override
  State<WordInputField> createState() => _WordInputFieldState();
}

class _WordInputFieldState extends State<WordInputField> {
  List<String> _suggestions = [];

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    // Filter BIP39 wordlist
    final matches = bip39Wordlist
        .where((word) => word.startsWith(text.toLowerCase()))
        .take(5)
        .toList();

    setState(() => _suggestions = matches);

    // If exact match, auto-fill and move to next
    if (matches.length == 1 && matches[0] == text.toLowerCase()) {
      widget.onWordEntered?.call(matches[0]);
      widget.nextFocusNode?.requestFocus();
    }
  }

  // ... build autocomplete overlay
}
```

---

### 7. BackupWarningBanner Component

**Layout**:

- Prominent banner at top of wallet view
- Warning icon
- Text: "Komodo wallet requires you to backup your seed phrase!"
- Action button: "Backup"
- Dismiss button (X)

**Behavior**:

- Shows if `!wallet.config.hasBackup`
- Persists across sessions until backup completed
- Tapping "Backup" navigates to seed backup flow
- Can be temporarily dismissed but reappears on next launch

**Implementation**:

```dart
class BackupWarningBanner extends StatelessWidget {
  final VoidCallback onBackupTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text('Komodo wallet requires you to backup your seed phrase!'),
          ),
          TextButton(
            onPressed: onBackupTap,
            child: Text('Backup'),
          ),
        ],
      ),
    );
  }
}
```

---

## Security Considerations

### 1. Passcode Security

- **Hashing**: Use bcrypt or Argon2 for passcode hashing
- **Storage**: Store only hashed passcode in secure storage
- **Rate Limiting**: Limit failed attempts (5 max before lock)
- **Timeout**: Auto-lock after background duration

### 2. Biometric Security

- **Fallback**: Always provide passcode fallback
- **Enrollment**: Check biometric enrollment before enabling
- **Re-authentication**: Require biometric on sensitive operations
- **Disable Option**: Allow users to disable in Settings

### 3. Seed Phrase Protection

- **Screenshot Protection**: Enable on all seed-related screens
- **Clipboard**: Clear clipboard after copy (if allowed)
- **Memory**: Clear seed from memory after display
- **Verification**: Mandatory confirmation before allowing wallet access

### 4. Password Requirements

- **Strength**: Enforce minimum length (current: defined in constants)
- **Validation**: Real-time strength indicator
- **Recovery**: No password recovery without seed phrase

---

## Accessibility Considerations

1. **Screen Readers**:

   - Add semantic labels to all interactive elements
   - Announce passcode entry
   - Describe seed word positions

2. **Font Scaling**:

   - Support system font size settings
   - Test with large text enabled
   - Ensure keypad remains usable

3. **Color Contrast**:

   - Verify WCAG AA compliance
   - Provide high-contrast mode option
   - Don't rely solely on color for state

4. **Keyboard Navigation**:
   - Support tab navigation on desktop
   - Allow keyboard entry for passcode
   - Enable keyboard shortcuts

---

## Analytics Events

### New Events to Track

```dart
// Onboarding
- onboarding_started(method: 'create' | 'import')
- onboarding_step_completed(step: string)
- onboarding_abandoned(step: string)
- onboarding_completed(method: 'create' | 'import', duration: int)

// Passcode
- passcode_created()
- passcode_enabled()
- passcode_auth_failed(attempts: int)
- passcode_reset()

// Biometric
- biometric_setup_shown()
- biometric_enabled(type: 'faceId' | 'touchId' | 'fingerprint')
- biometric_auth_success()
- biometric_auth_failed()

// Seed Backup
- seed_backup_warning_shown()
- seed_displayed()
- seed_confirmation_started()
- seed_confirmation_failed(attempts: int)
- seed_confirmation_success()
- backup_banner_shown()
- backup_banner_dismissed()
- backup_banner_action_clicked()

// Import
- import_method_selected(method: 'phrase' | 'file' | 'hardware')
- import_word_count_selected(count: 12 | 18 | 24)
- import_autocomplete_used(word_number: int)
- legacy_seed_info_shown()
```

---

## Internationalization

### New Translation Keys Required

```json
{
  "onboarding": {
    "startScreenTagline": "Own, control, and leverage the power of your digital assets",
    "startScreenLegal": "By tapping any button you agree and consent to our Terms of Service and Privacy Policy.",
    "createNewWallet": "Create new wallet",
    "alreadyHaveWallet": "I already have a wallet",

    "passcode": {
      "title": "Passcode",
      "createTitle": "Create passcode",
      "confirmTitle": "Confirm passcode",
      "createHint": "Enter your passcode. Be sure to remember it so you can unlock your wallet.",
      "confirmHint": "Re-enter your passcode. Be sure to remember it so you can unlock your wallet.",
      "mismatch": "Passcodes do not match",
      "tooShort": "Passcode must be 6 digits"
    },

    "seedBackup": {
      "warningTitle": "This secret phrase unlocks your wallet",
      "forYourEyesOnly": "For your eyes only!",
      "warning1": "Komodo wallet does not have access to this key.",
      "warning2": "Don't save this in any digital format, write it on paper and store securely.",
      "warning3": "If you lose your recovery phrase and device, your coins will be permanently lost and cannot be recovered.",
      "manualBackupTitle": "Manual backup",
      "neverShare": "Never share your secret phrase with anyone, and store it securely!",
      "confirmTitle": "Confirm secret phrase",
      "confirmHint": "Please tap on the correct answer of the below seed phrases.",
      "wordNumber": "Word #{number}",
      "incorrectSelection": "Incorrect word selection. Please try again.",
      "tooManyAttempts": "Too many incorrect attempts. Please review your seed phrase again."
    },

    "biometric": {
      "title": "Secure your wallet",
      "description": "Turn on {type} to secure your wallet.",
      "enable": "Enable {type}",
      "skipForNow": "Skip for now",
      "faceId": "Face ID",
      "touchId": "Touch ID",
      "fingerprint": "Fingerprint"
    },

    "success": {
      "title": "Brilliant, your wallet is ready!",
      "description": "Buy or deposit to get started.",
      "buyCrypto": "Buy Crypto",
      "later": "I'll do this later"
    }
  },

  "import": {
    "methodSelection": "Add existing wallet",
    "mostPopular": "Most popular",
    "secretPhrase": "Secret phrase",
    "importSeedFile": "Import seed file",
    "uploadSeedFile": "Upload seed file",

    "phrase": {
      "walletName": "Wallet name",
      "walletNameHint": "Enter your wallet name",
      "secretPhraseLabel": "Secret Phrase",
      "enterWordsHint": "Enter 1-{count} word of your seed",
      "wordCountSelector": "{count} Word phrase",
      "whatIsSecretPhrase": "What is a secret phrase?"
    },

    "file": {
      "title": "Import Seed file",
      "description": "Import file by clicking Browse or by dragging and dropping it below.",
      "chooseFile": "Choose File",
      "dragDrop": "Drag & Drop or Choose File",
      "passwordLabel": "Password",
      "passwordHint": "Enter password",
      "confirmPasswordLabel": "Confirm password",
      "confirmPasswordHint": "Enter Confirm password",
      "legacySeedCheckbox": "Legacy Komodo Wallet Seed",
      "legacySeedInfo": "Seed phrase generated by komodo wallet before may 2025 release",
      "legacySeedGotIt": "Got it"
    }
  },

  "desktop": {
    "welcomeTitle": "Welcome to Komodo Wallet",
    "orConnectWith": "or connect with",
    "walletConnect": "WalletConnect",
    "hardwareWallet": "Hardware Wallet",
    "connectKeplr": "Connect Keplr",
    "comingSoon": "coming soon",

    "password": {
      "title": "Create a new password",
      "description": "Enter a strong password to encrypt your wallet. This is how you will access it.",
      "note": "Note: If you forgot your password, Komodo can't help you recover it.",
      "walletNameLabel": "Wallet name"
    }
  },

  "backupBanner": {
    "title": "Komodo wallet requires you to backup your seed phrase!",
    "action": "Backup"
  }
}
```

---

## File Structure Changes

### New Directory Structure

```
lib/views/wallets_manager/
├── wallets_manager_wrapper.dart
├── wallets_manager_events_factory.dart
├── widgets/
│   ├── onboarding/                           # NEW DIRECTORY
│   │   ├── start_screen.dart                 # NEW
│   │   ├── passcode/
│   │   │   ├── passcode_entry_screen.dart    # NEW
│   │   │   ├── passcode_confirm_screen.dart  # NEW
│   │   │   ├── passcode_keypad.dart          # NEW
│   │   │   └── passcode_dot_indicator.dart   # NEW
│   │   ├── seed_backup/
│   │   │   ├── seed_backup_warning_screen.dart    # NEW
│   │   │   ├── seed_display_screen.dart           # NEW
│   │   │   ├── seed_confirmation_screen.dart      # NEW
│   │   │   └── seed_word_quiz_widget.dart         # NEW
│   │   ├── biometric_setup_screen.dart        # NEW
│   │   ├── wallet_ready_screen.dart           # NEW
│   │   └── backup_warning_banner.dart         # NEW
│   ├── import/                               # NEW DIRECTORY
│   │   ├── import_method_selection.dart       # REFACTORED from wallet_import_wrapper
│   │   ├── import_by_phrase/
│   │   │   ├── import_phrase_screen.dart      # REFACTORED from wallet_simple_import
│   │   │   ├── word_input_field.dart          # NEW
│   │   │   ├── word_autocomplete_overlay.dart # NEW
│   │   │   └── word_count_selector.dart       # NEW
│   │   ├── import_by_file/
│   │   │   ├── import_file_screen.dart        # REFACTORED from wallet_import_by_file
│   │   │   ├── file_drop_zone.dart            # NEW
│   │   │   └── legacy_seed_info_dialog.dart   # NEW
│   │   └── password_creation_screen.dart      # NEW - Shared by both import methods
│   ├── desktop/                              # NEW DIRECTORY
│   │   ├── desktop_welcome_screen.dart        # NEW
│   │   ├── desktop_connect_options.dart       # NEW
│   │   └── desktop_seed_safety_check.dart     # NEW
│   ├── wallets_manager.dart                  # MODIFIED
│   ├── iguana_wallets_manager.dart           # MODIFIED - Add new states
│   ├── wallet_creation.dart                  # MODIFIED - Integrate with new flow
│   ├── wallet_login.dart                     # MODIFIED - Add passcode support
│   ├── wallets_list.dart                     # EXISTING
│   ├── wallets_manager_controls.dart         # EXISTING
│   └── wallets_type_list.dart                # EXISTING (might be deprecated)

lib/services/
├── passcode/                                 # NEW DIRECTORY
│   ├── passcode_service.dart
│   └── passcode_storage.dart
├── biometric/                                # NEW DIRECTORY
│   ├── biometric_service.dart
│   └── biometric_auth_provider.dart
└── onboarding/                               # NEW DIRECTORY
    ├── onboarding_service.dart
    └── user_migration_service.dart

lib/bloc/
└── onboarding/                               # NEW DIRECTORY
    ├── onboarding_bloc.dart
    ├── onboarding_event.dart
    └── onboarding_state.dart
```

---

## Implementation Priority Matrix

| Component             | Priority | Complexity | Impact | Effort (days) |
| --------------------- | -------- | ---------- | ------ | ------------- |
| Seed Backup Flow      | CRITICAL | Medium     | HIGH   | 5             |
| Seed Confirmation     | CRITICAL | Medium     | HIGH   | 3             |
| Backup Warning Banner | CRITICAL | Low        | HIGH   | 1             |
| Start Screen          | HIGH     | Low        | MEDIUM | 2             |
| Passcode System       | HIGH     | Medium     | MEDIUM | 4             |
| Biometric Auth        | MEDIUM   | Medium     | MEDIUM | 3             |
| Word-by-Word Import   | MEDIUM   | Medium     | MEDIUM | 3             |
| Desktop Welcome       | MEDIUM   | Low        | LOW    | 2             |
| File Import UX        | LOW      | Low        | LOW    | 2             |
| Animations/Polish     | LOW      | Low        | LOW    | 3             |

**Total Estimated Effort**: 28 days (~6 weeks with testing)

---

## Phased Rollout Strategy

### Phase 1: Security Critical (Release 1.1)

- Mandatory seed backup flow
- Seed confirmation
- Backup warning banner
- **Release**: After 2 weeks of testing

### Phase 2: Passcode & Onboarding (Release 1.2)

- Start screen
- Passcode system
- Biometric authentication
- **Release**: 2 weeks after Phase 1

### Phase 3: Import UX (Release 1.3)

- Word-by-word seed entry
- Improved file import
- Desktop welcome screen
- **Release**: 2 weeks after Phase 2

### Phase 4: Polish (Release 1.4)

- Animations
- UI refinements
- Performance optimizations
- **Release**: 2 weeks after Phase 3

---

## Breaking Changes & Backward Compatibility

### NO Breaking Changes

- All existing wallet data remains compatible
- Existing wallets can still log in with password
- New features are additive

### Optional Migrations

- Existing users can opt-in to passcode
- Existing users are prompted to backup seed (if not backed up)
- No forced upgrades to authentication method

### New User Experience Only

- New wallet creation follows new flow
- Import follows enhanced flow
- Existing wallets continue working as-is

---

## Success Metrics

### User Experience Metrics

- [ ] 100% of new users complete seed backup
- [ ] <5% seed confirmation failure rate
- [ ] > 80% biometric adoption rate (where available)
- [ ] <10% onboarding abandonment rate
- [ ] Average onboarding time: <3 minutes

### Technical Metrics

- [ ] 0 critical bugs in seed backup flow
- [ ] <100ms passcode verification time
- [ ] <500ms biometric authentication time
- [ ] > 95% test coverage for security components
- [ ] 0 seed phrase leaks in logs/crash reports

### Business Metrics

- [ ] Reduced support requests about seed backup
- [ ] Increased user confidence scores
- [ ] Improved app store ratings
- [ ] Lower account recovery support volume

---

## Risk Assessment & Mitigation

### Risk 1: User Confusion

**Risk**: New multi-step flow might confuse existing users
**Mitigation**:

- Clear skip options for existing wallets
- In-app guidance/tooltips
- User education content

### Risk 2: Development Complexity

**Risk**: Large refactor might introduce bugs
**Mitigation**:

- Phased rollout
- Feature flags for gradual enable
- Comprehensive testing
- Beta testing program

### Risk 3: Passcode Lock-Out

**Risk**: Users forget passcode and can't access wallet
**Mitigation**:

- Password-based passcode reset
- Clear instructions during setup
- Recovery documentation

### Risk 4: Biometric Failures

**Risk**: Biometric auth may fail on some devices
**Mitigation**:

- Always provide passcode fallback
- Graceful degradation
- Clear error messages

### Risk 5: Migration Issues

**Risk**: Existing users may face login issues
**Mitigation**:

- Extensive testing with existing wallets
- No forced migrations
- Rollback plan
- Support documentation

---

## Performance Considerations

### 1. Passcode Hashing

- **Issue**: Hashing may be slow on low-end devices
- **Solution**: Use web workers / isolates for hashing
- **Target**: <100ms verification time

### 2. Autocomplete Performance

- **Issue**: Filtering 2048 BIP39 words on each keystroke
- **Solution**: Implement trie data structure for O(1) lookup
- **Target**: <16ms per keystroke

### 3. Screen Transitions

- **Issue**: Heavy screens may cause jank
- **Solution**:
  - Lazy load illustrations
  - Preload next screen during current step
  - Use cached widgets
- **Target**: 60fps transitions

### 4. Memory Management

- **Issue**: Seed phrase in memory
- **Solution**:
  - Clear immediately after display
  - Don't store in state longer than necessary
  - Use secure memory allocation where possible

---

## Future Enhancements (Post-MVP)

1. **Social Recovery**

   - Split seed into shares
   - Distribute to trusted contacts
   - Recover with threshold signature

2. **Hardware Wallet Integration**

   - Better Trezor UX
   - Ledger support
   - Visual device connection status

3. **WalletConnect Integration**

   - Connect to external wallets
   - DApp browser integration
   - QR code scanning

4. **Seed Backup Alternatives**

   - iCloud/Google Drive encrypted backup
   - Metal plate ordering service
   - Shamir's Secret Sharing

5. **Advanced Security**

   - Multisig wallets
   - Time-locked transactions
   - Spending limits

6. **Gamification**
   - Onboarding achievements
   - Backup streak tracking
   - Referral program

---

## Conclusion

This implementation plan provides a comprehensive roadmap for upgrading Komodo Wallet's login and onboarding experience to match modern security and UX standards. The phased approach ensures critical security fixes are deployed first, while allowing for iterative improvements over time.

**Key Priorities**:

1. ✅ Fix seed backup security flaw immediately
2. ✅ Implement seed confirmation to prevent user error
3. ✅ Add passcode for better day-to-day UX
4. ✅ Improve import experience to reduce errors
5. ✅ Create welcoming onboarding for new users

**Timeline**: 6 weeks for full implementation, 2 weeks for critical fixes

**Resources Required**:

- 1 Senior Flutter Developer (full-time)
- 1 UI/UX Designer (part-time, for asset preparation)
- 1 QA Engineer (full-time during testing phases)

---

## Appendix

### A. Figma Node ID Reference

| Screen Name               | Node ID    | Type    | Priority |
| ------------------------- | ---------- | ------- | -------- |
| Start Screen              | 9405:37677 | Mobile  | HIGH     |
| Create Passcode           | 8969:727   | Mobile  | HIGH     |
| Confirm Passcode          | 8969:29722 | Mobile  | HIGH     |
| Seed Backup Warning       | 8994:12153 | Mobile  | CRITICAL |
| Seed Display              | 8994:12253 | Mobile  | CRITICAL |
| Seed Confirmation         | 8994:12339 | Mobile  | CRITICAL |
| Biometric Setup           | 8969:29795 | Mobile  | MEDIUM   |
| Wallet Ready              | 8971:30112 | Mobile  | MEDIUM   |
| Import Method Selection   | 8986:999   | Mobile  | MEDIUM   |
| Import by Phrase          | 9079:26393 | Mobile  | MEDIUM   |
| Import by File            | 9085:48669 | Mobile  | LOW      |
| Desktop Welcome           | 9030:25797 | Desktop | MEDIUM   |
| Desktop Password Creation | 9030:26394 | Desktop | MEDIUM   |
| Desktop Seed Input        | 9030:26613 | Desktop | MEDIUM   |
| Desktop Wallet View       | 9079:25140 | Desktop | LOW      |

### B. Current vs New Flow Comparison

| Aspect            | Current Flow      | New Flow                        | Improvement               |
| ----------------- | ----------------- | ------------------------------- | ------------------------- |
| Onboarding        | None              | Start screen                    | Better first impression   |
| Seed Backup       | Deferred          | Mandatory during creation       | Critical security fix     |
| Seed Verification | None              | Quiz confirmation               | Prevents user error       |
| Auth Method       | Password only     | Password + Passcode + Biometric | Better UX & security      |
| Import UX         | Single text field | Word-by-word with autocomplete  | Fewer errors              |
| Steps (Create)    | 1 screen          | 7 steps                         | More guidance             |
| Steps (Import)    | 2 screens         | 4 steps                         | Clearer flow              |
| Desktop UX        | Same as mobile    | Optimized layouts               | Better desktop experience |
| Education         | Minimal           | Comprehensive warnings          | Better user understanding |

### C. Dependencies

```yaml
# Required new dependencies
dependencies:
  local_auth: ^2.1.0              # Biometric authentication
  local_auth_android: ^1.0.0      # Android biometric
  local_auth_ios: ^1.1.0          # iOS biometric

# Optional but recommended
dependencies:
  flutter_animate: ^4.5.0         # Smooth animations
  drop_zone: ^0.0.2               # Drag-and-drop (web)
  lottie: ^3.0.0                  # Animated illustrations

# Already in project (verify versions)
dependencies:
  crypto: ^3.0.3                  # Hashing
  flutter_secure_storage: ^9.0.0  # Secure storage
```

### D. Asset Requirements

**Illustrations Needed** (from Figma or similar):

- Start screen hero illustration (blockchain/crypto theme)
- Seed backup warning illustration
- Wallet ready success illustration
- Biometric setup icon/illustration
- File upload icon
- Warning/info icons

**Export from Figma**:

- All icons as SVG
- Illustrations as SVG or PNG @2x, @3x
- Color palette as JSON for theme

---

## Questions for Product/Design Team

1. **Passcode vs Password**:

   - Should passcode completely replace password for daily use?
   - Or should both coexist (passcode for app unlock, password for sensitive ops)?

2. **Seed Backup Alternatives**:

   - Allow file export as alternative to manual backup?
   - Allow screenshot (security risk) or completely disable?

3. **Biometric Fallback**:

   - If user enables biometric but device doesn't support it anymore, fallback to passcode or password?

4. **Import Flow**:

   - Should word-by-word be default, or single text field with option to switch?

5. **Desktop vs Mobile**:

   - Should desktop have different passcode requirement (maybe optional)?
   - Should hardware wallet be pushed more on desktop?

6. **Legacy Users**:
   - Force seed backup for existing users, or keep as optional?
   - Deadline for passcode setup, or always optional?

---

## Sign-Off

**Prepared by**: AI Assistant  
**Date**: October 1, 2025  
**Review Status**: Pending  
**Approved by**: [Product Lead] [Tech Lead]

---

**Next Steps**:

1. Review this plan with team
2. Prioritize phases based on team capacity
3. Set sprint goals
4. Begin Phase 1 implementation

