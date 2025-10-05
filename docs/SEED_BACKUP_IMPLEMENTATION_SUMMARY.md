# Seed Backup Flow - Implementation Summary

## ✅ Completed Components

### 1. Core Widgets Created

All seed backup widgets have been implemented in `lib/views/wallets_manager/widgets/onboarding/seed_backup/`:

- **SeedBackupWarningScreen** (`seed_backup_warning_screen.dart`)

  - Educational screen showing 3 warning boxes
  - Figma design: node 8994:12153
  - Features: Gradient background, warning icons, cancellation confirmation dialog

- **SeedDisplayScreen** (`seed_display_screen.dart`)

  - Displays seed phrase in 2-column grid
  - Figma design: node 8994:12253
  - Features: Screenshot protection, numbered word pills, warning banner

- **SeedConfirmationScreen** (`seed_confirmation_screen.dart`)

  - Quiz-based verification with 4 random words
  - Figma design: node 8994:12339
  - Features: Multiple choice, 3-attempt limit, screenshot protection

- **BackupWarningBanner** (`backup_warning_banner.dart`)
  - Persistent reminder on main wallet view
  - Figma design: node 9398:37389
  - Features: Dismissible, action button, gradient styling

### 2. Translation Keys Added

All necessary translation keys have been added to `assets/translations/en.json`:

```json
{
  "onboardingSeedBackupWarningTitle": "This secret phrase unlocks your wallet",
  "onboardingSeedBackupForYourEyesOnly": "For your eyes only!",
  "onboardingSeedBackupWarning1": "Komodo wallet does not have access to this key.",
  "onboardingSeedBackupWarning2": "Don't save this in any digital format, write it on paper and store securely.",
  "onboardingSeedBackupWarning3": "If you lose your recovery phrase and device, your coins will be permanently lost and cannot be recovered.",
  "onboardingSeedBackupManualBackupTitle": "Manual backup",
  "onboardingSeedBackupNeverShare": "Never share your secret phrase with anyone, and store it securely!",
  "onboardingSeedBackupConfirmTitle": "Confirm secret phrase",
  "onboardingSeedBackupConfirmHint": "Please tap on the correct answer of the below seed phrases.",
  "onboardingSeedBackupWordNumber": "Word #{0}",
  "onboardingSeedBackupIncorrectSelection": "Incorrect word selection. Please try again.",
  "onboardingSeedBackupTooManyAttempts": "Too many incorrect attempts. Please review your seed phrase again.",
  "onboardingSeedBackupAttemptsRemaining": "Attempts remaining: {0}",
  "backupBannerTitle": "Komodo wallet requires you to backup your seed phrase!",
  "backupBannerAction": "Backup",
  "cancelWalletCreationTitle": "Cancel wallet creation?",
  "cancelWalletCreationMessage": "Your wallet will be deleted if you cancel now. Are you sure?"
}
```

## 🔄 Next Steps: Integration

### Step 1: Generate Translation Code

Run the code generation command to update `codegen_loader.g.dart`:

```bash
flutter pub run easy_localization:generate -S assets/translations -f keys -o codegen_loader.g.dart
```

### Step 2: Integrate into Wallet Manager

The `iguana_wallets_manager.dart` needs to be modified to include the seed backup flow. Here's the integration plan:

#### A. Add State Variables

```dart
class _IguanaWalletsManagerState extends State<IguanaWalletsManager> {
  // ... existing variables

  // NEW: Seed backup flow state
  WalletCreationStep _creationStep = WalletCreationStep.initial;
  String? _pendingSeedPhrase;
  String? _pendingWalletPassword;
}

enum WalletCreationStep {
  initial,
  seedBackupWarning,
  seedDisplay,
  seedConfirmation,
  complete,
}
```

#### B. Modify BlocListener

Intercept the wallet creation flow to show seed backup before login:

```dart
BlocListener<AuthBloc, AuthBlocState>(
  listener: (context, state) {
    // NEW: Intercept wallet creation to show seed backup
    if (state.mode == AuthorizeMode.logIn &&
        _action == WalletsManagerAction.create &&
        _creationStep == WalletCreationStep.initial) {
      _startSeedBackupFlow(state);
      return; // Don't call _onLogIn yet
    }

    if (state.mode == AuthorizeMode.logIn) {
      _onLogIn();
    }
    // ... rest of listener
  },
)
```

#### C. Add Seed Backup Flow Methods

```dart
Future<void> _startSeedBackupFlow(AuthBlocState state) async {
  try {
    final kdfSdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final mnemonic = await kdfSdk.auth.getMnemonic(
      encrypted: false,
      walletPassword: _pendingWalletPassword,
    );

    if (mounted) {
      setState(() {
        _pendingSeedPhrase = mnemonic.plaintextMnemonic;
        _creationStep = WalletCreationStep.seedBackupWarning;
        _isLoading = false;
      });
    }
  } catch (e) {
    // Handle error
    setState(() => _isLoading = false);
  }
}

void _onSeedBackupConfirmed() async {
  // Mark seed as backed up
  final kdfSdk = RepositoryProvider.of<KomodoDefiSdk>(context);
  await kdfSdk.confirmSeedBackup(hasBackup: true);

  // Clear seed from memory
  setState(() {
    _pendingSeedPhrase = null;
    _pendingWalletPassword = null;
    _creationStep = WalletCreationStep.complete;
  });

  // Emit event to update AuthBloc
  context.read<AuthBloc>().add(const AuthSeedBackupConfirmed());

  // NOW complete the login
  _onLogIn();
}
```

#### D. Update \_buildContent Method

Add routing to seed backup screens:

```dart
Widget _buildContent() {
  // NEW: Show seed backup flow if in progress
  if (_creationStep != WalletCreationStep.initial) {
    return _buildSeedBackupFlow();
  }

  // ... existing content routing
}

Widget _buildSeedBackupFlow() {
  switch (_creationStep) {
    case WalletCreationStep.seedBackupWarning:
      return SeedBackupWarningScreen(
        onContinue: () => setState(() {
          _creationStep = WalletCreationStep.seedDisplay;
        }),
        onCancel: _cancelWalletCreation,
      );

    case WalletCreationStep.seedDisplay:
      return SeedDisplayScreen(
        seedPhrase: _pendingSeedPhrase!,
        onContinue: () => setState(() {
          _creationStep = WalletCreationStep.seedConfirmation;
        }),
        onCancel: _cancelWalletCreation,
      );

    case WalletCreationStep.seedConfirmation:
      return SeedConfirmationScreen(
        seedPhrase: _pendingSeedPhrase!,
        onConfirmed: _onSeedBackupConfirmed,
        onCancel: () => setState(() {
          _creationStep = WalletCreationStep.seedDisplay;
        }),
      );

    default:
      return const SizedBox();
  }
}

void _cancelWalletCreation() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(LocaleKeys.cancelWalletCreationTitle.tr()),
      content: Text(LocaleKeys.cancelWalletCreationMessage.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.no.tr()),
        ),
        UiPrimaryButton(
          onPressed: () async {
            Navigator.of(context).pop();

            // Sign out to delete the created wallet
            context.read<AuthBloc>().add(const AuthSignOutRequested());

            // Reset state
            setState(() {
              _creationStep = WalletCreationStep.initial;
              _pendingSeedPhrase = null;
              _pendingWalletPassword = null;
              _action = WalletsManagerAction.none;
            });
          },
          text: LocaleKeys.yes.tr(),
        ),
      ],
    ),
  );
}
```

#### E. Store Password Temporarily

Modify `_createWallet` to store the password:

```dart
void _createWallet({
  required String name,
  required String password,
  WalletType? walletType,
  required bool rememberMe,
}) async {
  // NEW: Store password for later use in seed backup flow
  _pendingWalletPassword = password;

  setState(() {
    _isLoading = true;
    _rememberMe = rememberMe;
  });

  // ... rest of existing code
}
```

### Step 3: Add Backup Banner to Wallet View

Integrate the banner into the main wallet view (e.g., `wallet_main.dart`):

```dart
import 'package:web_dex/views/wallets_manager/widgets/onboarding/backup_warning_banner.dart';

class WalletMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        final hasBackup = state.currentUser?.wallet.config.hasBackup ?? true;

        return Column(
          children: [
            // Show banner if seed not backed up
            if (!hasBackup)
              BackupWarningBanner(
                onBackupTap: () => _navigateToSeedBackup(context),
                onDismiss: () => _dismissBanner(context),
              ),

            // ... rest of wallet content
          ],
        );
      },
    );
  }

  void _navigateToSeedBackup(BuildContext context) {
    // Navigate to seed backup flow in Settings
    // (or show modal with seed backup screens)
  }

  void _dismissBanner(BuildContext context) {
    // Store dismissal in local storage with timestamp
    // Banner will reappear on next app launch if still not backed up
  }
}
```

### Step 4: Add Required Imports

Add these imports to `iguana_wallets_manager.dart`:

```dart
import 'package:web_dex/views/wallets_manager/widgets/onboarding/seed_backup/seed_backup_warning_screen.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/seed_backup/seed_display_screen.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/seed_backup/seed_confirmation_screen.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
```

## 🧪 Testing Checklist

### Manual Testing

- [ ] Create new wallet flows to seed backup
- [ ] All 3 seed backup screens appear in sequence
- [ ] Seed phrase is displayed correctly (12 words in 2 columns)
- [ ] Seed confirmation randomly selects 4 words
- [ ] Wrong word selection shows error
- [ ] 3 failed attempts returns to seed display
- [ ] Correct confirmation completes wallet creation
- [ ] Banner appears if seed not backed up
- [ ] Banner action navigates correctly
- [ ] Screenshot protection works (on mobile)

### Code Quality

- [ ] No linter errors
- [ ] Follows BLoC pattern conventions
- [ ] Proper error handling
- [ ] Secure memory management (seed cleared after use)
- [ ] Analytics events logged

## 🔒 Security Considerations

1. **Seed Never Logged**: No `print()` or logging of seed phrase
2. **Memory Cleared**: `_pendingSeedPhrase` set to null after confirmation
3. **Screenshot Protection**: `ScreenshotSensitive` widget used
4. **Secure Storage**: Password temporarily stored in state, cleared after use
5. **No Skip Option**: User cannot bypass seed confirmation

## 📊 Analytics Events

Consider adding these analytics events:

```dart
// When seed backup starts
analyticsBloc.logEvent(SeedBackupStartedEvent());

// When seed is displayed
analyticsBloc.logEvent(SeedDisplayedEvent());

// When confirmation is attempted
analyticsBloc.logEvent(SeedConfirmationAttemptedEvent(success: true/false));

// When backup is completed
analyticsBloc.logEvent(SeedBackupCompletedEvent());
```

## 🎨 Design Compliance

All screens match Figma designs:

- **Color Palette**: Using exact hex values from Figma
- **Typography**: Manrope font family, correct weights and sizes
- **Spacing**: 16px padding, consistent margins
- **Gradients**: Matching gradient backgrounds
- **Icons**: Using Material Icons as placeholders

## 📝 Documentation

- [x] Translation keys documented
- [x] Widget documentation (dartdoc comments)
- [x] Integration guide (this document)
- [ ] Update main README with new flow
- [ ] Add to CHANGELOG.md

## 🚀 Deployment

After testing:

1. Commit changes with conventional commit message
2. Create PR with thorough description
3. Request code review
4. Merge to dev branch
5. Test on staging environment
6. Release as part of next version

---

**Status**: ✅ Phase 1 Complete - Ready for Integration Testing

**Next Phase**: Implement passcode system (Phase 2)
