# New Login Flow - Action Plan for Development

## 🎯 Immediate Action Items

This document provides a step-by-step action plan for implementing the new login flow. Start here!

**Related Documents**:

- Full Plan: `NEW_LOGIN_FLOW_IMPLEMENTATION_PLAN.md`
- Summary: `NEW_LOGIN_FLOW_SUMMARY.md`
- Comparison: `LOGIN_FLOW_COMPARISON.md`

---

## 🚨 Phase 1: Critical Security Fix (START HERE!)

**Goal**: Fix the seed backup security flaw  
**Timeline**: Week 1-2 (10 days)  
**Priority**: CRITICAL

### Day 1-2: Setup & Planning

#### Create Directory Structure

```bash
mkdir -p lib/views/wallets_manager/widgets/onboarding/seed_backup
mkdir -p test_units/views/wallets_manager/seed_backup
```

#### Create Base Files

```bash
# Create empty widget files
touch lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_backup_warning_screen.dart
touch lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_display_screen.dart
touch lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_confirmation_screen.dart
touch lib/views/wallets_manager/widgets/onboarding/backup_warning_banner.dart

# Create test files
touch test_units/views/wallets_manager/seed_backup/seed_confirmation_test.dart
```

#### Study Existing Code

Read these files to understand current flow:

- `lib/views/wallets_manager/widgets/iguana_wallets_manager.dart` (state machine)
- `lib/views/wallets_manager/widgets/wallet_creation.dart` (create form)
- `lib/bloc/auth_bloc/auth_bloc.dart` (authentication logic)
- `lib/views/settings/widgets/security_settings/seed_settings/seed_confirmation/seed_confirmation.dart` (existing seed confirmation in Settings)

---

### Day 3-4: Implement Seed Backup Warning Screen

**Reference**: Figma node `8994:12153` / `9207:1546`

#### Create `seed_backup_warning_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class SeedBackupWarningScreen extends StatelessWidget {
  const SeedBackupWarningScreen({
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF060B1C),
            Color(0xFF0C1020),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header with close button
          _buildHeader(context),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Illustration
                  _buildIllustration(),
                  SizedBox(height: 24),

                  // "For your eyes only!"
                  _buildEyesOnlyBadge(),
                  SizedBox(height: 12),

                  // Title
                  Text(
                    LocaleKeys.onboardingSeedBackupWarningTitle.tr(),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Warning boxes
                  _buildWarningBox(
                    icon: Icons.key,
                    text: LocaleKeys.onboardingSeedBackupWarning1.tr(),
                  ),
                  SizedBox(height: 16),
                  _buildWarningBox(
                    icon: Icons.edit_note,
                    text: LocaleKeys.onboardingSeedBackupWarning2.tr(),
                  ),
                  SizedBox(height: 16),
                  _buildWarningBox(
                    icon: Icons.warning_amber,
                    text: LocaleKeys.onboardingSeedBackupWarning3.tr(),
                    isWarning: true,
                  ),
                ],
              ),
            ),
          ),

          // Continue button
          Padding(
            padding: EdgeInsets.all(16),
            child: UiPrimaryButton(
              onPressed: onContinue,
              text: LocaleKeys.continueText.tr(),
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => _showCancelConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    // TODO: Add actual illustration from Figma
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Color(0xFF171926),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.security,
          size: 80,
          color: Color(0xFF3D77E9),
        ),
      ),
    );
  }

  Widget _buildEyesOnlyBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF171926),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility, size: 16, color: Color(0xFFADAFC4)),
          SizedBox(width: 8),
          Text(
            LocaleKeys.onboardingSeedBackupForYourEyesOnly.tr(),
            style: TextStyle(color: Color(0xFFADAFC4)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox({
    required IconData icon,
    required String text,
    bool isWarning = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF171926),
        borderRadius: BorderRadius.circular(13),
        border: isWarning ? Border.all(
          color: Color(0xFFFF6B00),
          width: 1,
        ) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isWarning ? Color(0xFFFF6B00) : Color(0xFF3D77E9),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFFADAFC4),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
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
            onPressed: () {
              Navigator.of(context).pop();
              onCancel();
            },
            text: LocaleKeys.yes.tr(),
          ),
        ],
      ),
    );
  }
}
```

**Checklist**:

- [ ] Widget created
- [ ] Matches Figma design
- [ ] Translations added
- [ ] Cancel confirmation works
- [ ] Continue callback works

---

### Day 5-6: Implement Seed Display Screen

**Reference**: Figma node `8994:12253`

#### Create `seed_display_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';

class SeedDisplayScreen extends StatelessWidget {
  const SeedDisplayScreen({
    required this.seedPhrase,
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  final String seedPhrase;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final words = seedPhrase.split(' ');

    return ScreenshotSensitive(
      child: Scaffold(
        backgroundColor: Color(0xFF0C1020),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: onCancel,
          ),
          title: Text(
            LocaleKeys.onboardingSeedBackupManualBackupTitle.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(height: 16),

                    // Seed word grid (2 columns)
                    _buildSeedGrid(words),

                    SizedBox(height: 32),

                    // Warning banner at bottom
                    _buildWarningBanner(),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: EdgeInsets.all(16),
              child: UiPrimaryButton(
                onPressed: onContinue,
                text: LocaleKeys.continueText.tr(),
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedGrid(List<String> words) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3.2,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        return _buildWordPill(index + 1, words[index]);
      },
    );
  }

  Widget _buildWordPill(int number, String word) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF2B2D40),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            '$number.',
            style: TextStyle(
              color: Color(0xFF797B89),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              word,
              style: TextStyle(
                color: Color(0xFFADAFC4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF171926),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6B00)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Color(0xFFFF6B00), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.onboardingSeedBackupNeverShare.tr(),
              style: TextStyle(
                color: Color(0xFFADAFC4),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Checklist**:

- [ ] Widget created
- [ ] Screenshot protection enabled
- [ ] Grid layout correct (2 columns)
- [ ] Words are numbered
- [ ] Warning banner prominent
- [ ] Close confirmation works

---

### Day 7-8: Implement Seed Confirmation Screen

**Reference**: Figma node `8994:12339`, `9079:25713`

#### Create `seed_confirmation_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'dart:math';

class SeedConfirmationScreen extends StatefulWidget {
  const SeedConfirmationScreen({
    required this.seedPhrase,
    required this.onConfirmed,
    required this.onCancel,
    super.key,
  });

  final String seedPhrase;
  final VoidCallback onConfirmed;
  final VoidCallback onCancel;

  @override
  State<SeedConfirmationScreen> createState() => _SeedConfirmationScreenState();
}

class _SeedConfirmationScreenState extends State<SeedConfirmationScreen> {
  late List<SeedWordVerification> _verifications;
  Map<int, String?> _selectedWords = {};
  String? _errorMessage;
  int _attemptsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _generateVerifications();
  }

  void _generateVerifications() {
    final words = widget.seedPhrase.split(' ');
    final random = Random();
    final allIndices = List.generate(words.length, (i) => i);
    allIndices.shuffle(random);

    // Select 4 random words to verify
    final indicesToVerify = allIndices.take(4).toList()..sort();

    _verifications = indicesToVerify.map((index) {
      final correctWord = words[index];

      // Generate 2 random wrong words
      final wrongWords = words
          .where((w) => w != correctWord)
          .toList()
        ..shuffle(random);

      final options = [correctWord, wrongWords[0], wrongWords[1]]
        ..shuffle(random);

      return SeedWordVerification(
        wordIndex: index,
        correctWord: correctWord,
        options: options,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0C1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        title: Text(
          LocaleKeys.onboardingSeedBackupConfirmTitle.tr(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instruction
                  Text(
                    LocaleKeys.onboardingSeedBackupConfirmHint.tr(),
                    style: TextStyle(
                      color: Color(0xFFADAFC4),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Verification questions
                  ..._verifications.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: _buildWordQuestion(entry.value, entry.key),
                    );
                  }).toList(),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFFF6B00)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Color(0xFFFF6B00), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Color(0xFFFF6B00)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Attempts remaining
                  if (_attemptsRemaining < 3)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Attempts remaining: $_attemptsRemaining',
                        style: TextStyle(
                          color: Color(0xFF797B89),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Continue button
          Padding(
            padding: EdgeInsets.all(16),
            child: UiPrimaryButton(
              onPressed: _isAllSelected ? _onVerify : null,
              text: LocaleKeys.continueText.tr(),
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordQuestion(SeedWordVerification verification, int questionIndex) {
    final isSelected = _selectedWords.containsKey(questionIndex);
    final selectedWord = _selectedWords[questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.onboardingSeedBackupWordNumber.tr(
            args: ['${verification.wordIndex + 1}'],
          ),
          style: TextStyle(
            color: Color(0xFFADAFC4),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),

        Row(
          children: verification.options.map((option) {
            final isThisSelected = selectedWord == option;
            final isCorrect = isThisSelected &&
                option == verification.correctWord;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: _buildOptionButton(
                  option,
                  isThisSelected,
                  isCorrect,
                  () => _onWordSelected(questionIndex, option),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionButton(
    String word,
    bool isSelected,
    bool isCorrect,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3D77E9) : Color(0xFF2B2D40),
          borderRadius: BorderRadius.circular(6),
          border: isSelected
            ? Border.all(color: Color(0xFF3D77E9), width: 2)
            : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected && isCorrect)
              Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check, size: 16, color: Colors.white),
              ),
            Text(
              word,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFFADAFC4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onWordSelected(int questionIndex, String word) {
    setState(() {
      _selectedWords[questionIndex] = word;
      _errorMessage = null;
    });
  }

  bool get _isAllSelected {
    return _selectedWords.length == _verifications.length;
  }

  void _onVerify() {
    // Check if all selections are correct
    bool allCorrect = true;
    for (var i = 0; i < _verifications.length; i++) {
      final verification = _verifications[i];
      final selected = _selectedWords[i];
      if (selected != verification.correctWord) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      widget.onConfirmed();
    } else {
      setState(() {
        _attemptsRemaining--;

        if (_attemptsRemaining == 0) {
          _errorMessage = LocaleKeys.onboardingSeedBackupTooManyAttempts.tr();
          // Navigate back to seed display after delay
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              // Reset and go back
              Navigator.of(context).pop();
            }
          });
        } else {
          _errorMessage = LocaleKeys.onboardingSeedBackupIncorrectSelection.tr();
          // Clear selections
          _selectedWords.clear();
        }
      });
    }
  }
}

class SeedWordVerification {
  final int wordIndex;
  final String correctWord;
  final List<String> options;

  SeedWordVerification({
    required this.wordIndex,
    required this.correctWord,
    required this.options,
  });
}
```

**Checklist**:

- [ ] Widget created
- [ ] Random word selection works
- [ ] Multiple choice generation correct
- [ ] Selection feedback (checkmark)
- [ ] Verification logic correct
- [ ] Attempts limiting works
- [ ] Error messaging clear
- [ ] Screenshot protection enabled

---

### Day 9: Implement Backup Warning Banner

**Reference**: Figma node `9398:37389`

#### Create `backup_warning_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class BackupWarningBanner extends StatelessWidget {
  const BackupWarningBanner({
    required this.onBackupTap,
    this.onDismiss,
    super.key,
  });

  final VoidCallback onBackupTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF6B00).withOpacity(0.1),
            Color(0xFFFF6B00).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFFF6B00),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF6B00),
            size: 32,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.backupBannerTitle.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          UiPrimaryButton(
            onPressed: onBackupTap,
            text: LocaleKeys.backupBannerAction.tr(),
            height: 38,
            textStyle: TextStyle(fontSize: 12),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: Color(0xFF797B89),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Checklist**:

- [ ] Widget created
- [ ] Visually prominent (warning colors)
- [ ] Backup button works
- [ ] Dismiss button works (if enabled)
- [ ] Responsive layout

---

### Day 10: Integration & Testing

#### Update `iguana_wallets_manager.dart`

```dart
// Add to _IguanaWalletsManagerState

enum WalletCreationState {
  initial,
  seedBackupWarning,
  seedDisplay,
  seedConfirmation,
  complete,
}

class _IguanaWalletsManagerState extends State<IguanaWalletsManager> {
  // ... existing code

  WalletCreationState _creationState = WalletCreationState.initial;
  String? _pendingSeedPhrase;
  String? _pendingWalletName;

  Widget _buildContent() {
    // ... existing code

    // Add new state handling
    if (_action == WalletsManagerAction.create &&
        _creationState != WalletCreationState.initial) {
      return _buildSeedBackupFlow();
    }

    // ... rest of existing code
  }

  Widget _buildSeedBackupFlow() {
    switch (_creationState) {
      case WalletCreationState.seedBackupWarning:
        return SeedBackupWarningScreen(
          onContinue: () => setState(() {
            _creationState = WalletCreationState.seedDisplay;
          }),
          onCancel: _cancelWalletCreation,
        );

      case WalletCreationState.seedDisplay:
        return SeedDisplayScreen(
          seedPhrase: _pendingSeedPhrase!,
          onContinue: () => setState(() {
            _creationState = WalletCreationState.seedConfirmation;
          }),
          onCancel: _cancelWalletCreation,
        );

      case WalletCreationState.seedConfirmation:
        return SeedConfirmationScreen(
          seedPhrase: _pendingSeedPhrase!,
          onConfirmed: _onSeedBackupConfirmed,
          onCancel: () => setState(() {
            _creationState = WalletCreationState.seedDisplay;
          }),
        );

      default:
        return SizedBox();
    }
  }

  void _createWallet({
    required String name,
    required String password,
    WalletType? walletType,
    required bool rememberMe,
  }) async {
    setState(() {
      _isLoading = true;
      _rememberMe = rememberMe;
      _pendingWalletName = name;
    });

    // Create wallet (existing code)
    final Wallet newWallet = Wallet.fromName(
      name: name,
      walletType: walletType ?? WalletType.iguana,
    );

    context.read<AuthBloc>().add(
      AuthRegisterRequested(wallet: newWallet, password: password),
    );

    // After wallet creation succeeds (listen to AuthBloc)
    // Get seed phrase and show backup flow
  }

  Future<void> _startSeedBackupFlow(String password) async {
    // Get seed phrase from KDF
    final kdfSdk = context.read<KomodoDefiSdk>();
    final seed = await kdfSdk.auth.getMnemonic(
      encrypted: false,
      walletPassword: password,
    );

    setState(() {
      _pendingSeedPhrase = seed.plaintextMnemonic;
      _creationState = WalletCreationState.seedBackupWarning;
      _isLoading = false;
    });
  }

  void _onSeedBackupConfirmed() async {
    // Mark seed as backed up
    await context.read<KomodoDefiSdk>().confirmSeedBackup(hasBackup: true);

    // Clear seed from memory
    setState(() {
      _pendingSeedPhrase = null;
      _creationState = WalletCreationState.complete;
    });

    // Emit auth event to update state
    context.read<AuthBloc>().add(AuthSeedBackupConfirmed());

    // Proceed to wallet (onLogin flow will handle this)
  }

  void _cancelWalletCreation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel wallet creation?'),
        content: Text('Your wallet will be deleted if you cancel now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No'),
          ),
          UiPrimaryButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Delete the created wallet
              // (implement wallet deletion logic)

              setState(() {
                _creationState = WalletCreationState.initial;
                _pendingSeedPhrase = null;
                _action = WalletsManagerAction.none;
              });
            },
            text: 'Yes',
          ),
        ],
      ),
    );
  }
}
```

#### Update `wallet_main.dart` to show banner

```dart
// In lib/views/wallet/wallet_page/wallet_main/wallet_main.dart

class WalletMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthBloc>().state.currentUser;
    final hasBackup = currentUser?.wallet.config.hasBackup ?? true;

    return Column(
      children: [
        // Show backup banner if seed not backed up
        if (!hasBackup)
          BackupWarningBanner(
            onBackupTap: () => _navigateToSeedBackup(context),
            onDismiss: () => _dismissBannerTemporarily(context),
          ),

        // ... existing wallet content
      ],
    );
  }

  void _navigateToSeedBackup(BuildContext context) {
    // Navigate to seed backup flow in Settings
    // (use existing flow or create new one)
  }

  void _dismissBannerTemporarily(BuildContext context) {
    // Store dismissal in local storage with timestamp
    // Reshow after 24 hours or next app launch
  }
}
```

#### Add Translation Keys

```dart
// Add to assets/translations/en.json

{
  "onboarding": {
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
    }
  },
  "backupBanner": {
    "title": "Komodo wallet requires you to backup your seed phrase!",
    "action": "Backup"
  },
  "cancelWalletCreationTitle": "Cancel wallet creation?",
  "cancelWalletCreationMessage": "Your wallet will be deleted if you cancel now. Are you sure?"
}
```

**Checklist**:

- [ ] State machine updated
- [ ] Seed backup flow integrated
- [ ] Wallet creation triggers backup flow
- [ ] Backup confirmation updates `hasBackup`
- [ ] Banner appears on wallet view
- [ ] Translations added
- [ ] Manual testing completed
- [ ] Integration tests pass

---

## Testing Phase 1

### Create Test File

```dart
// test_integration/tests/wallets_manager_tests/seed_backup_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Seed Backup Flow Tests', () {
    testWidgets('Complete seed backup flow during wallet creation', (tester) async {
      // 1. Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // 2. Navigate to create wallet
      await tester.tap(find.byKey(Key('create-wallet-button')));
      await tester.pumpAndSettle();

      // 3. Fill wallet creation form
      await tester.enterText(find.byKey(Key('name-wallet-field')), 'Test Wallet');
      await tester.enterText(find.byKey(Key('create-password-field')), 'TestPass123!');
      await tester.enterText(find.byKey(Key('confirm-password-field')), 'TestPass123!');

      // 4. Check EULA
      await tester.tap(find.byKey(Key('create-wallet-eula-checks')));
      await tester.pumpAndSettle();

      // 5. Create wallet
      await tester.tap(find.byKey(Key('confirm-password-button')));
      await tester.pumpAndSettle();

      // 6. Verify seed backup warning appears
      expect(find.text('For your eyes only!'), findsOneWidget);
      expect(find.text('This secret phrase unlocks your wallet'), findsOneWidget);

      // 7. Continue to seed display
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // 8. Verify seed phrase is shown
      expect(find.text('Manual backup'), findsOneWidget);
      // Should show 12 numbered words
      expect(find.textContaining('1.'), findsOneWidget);
      expect(find.textContaining('12.'), findsOneWidget);

      // 9. Continue to confirmation
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // 10. Verify confirmation screen
      expect(find.text('Confirm secret phrase'), findsOneWidget);

      // 11. Select correct words (this would need to parse the seed)
      // (Implementation would extract seed and select correct options)

      // 12. Verify wallet is accessible
      expect(find.byType(WalletMainView), findsOneWidget);

      // 13. Verify hasBackup flag is true
      final authBloc = BlocProvider.of<AuthBloc>(tester.element(find.byType(MyApp)));
      expect(authBloc.state.currentUser?.wallet.config.hasBackup, true);
    });

    testWidgets('Backup warning banner appears if not backed up', (tester) async {
      // Create wallet programmatically with hasBackup = false
      // ... setup code

      // Verify banner appears
      expect(find.byType(BackupWarningBanner), findsOneWidget);
      expect(find.text('Komodo wallet requires you to backup your seed phrase!'), findsOneWidget);

      // Tap backup button
      await tester.tap(find.text('Backup'));
      await tester.pumpAndSettle();

      // Should navigate to backup flow
      expect(find.text('Manual backup'), findsOneWidget);
    });

    testWidgets('Cannot skip seed confirmation', (tester) async {
      // Setup: navigate to seed confirmation
      // ... setup code

      // Try to go back
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Cancel wallet creation?'), findsOneWidget);

      // Verify cannot proceed without confirmation
      // (no direct skip button exists)
    });

    testWidgets('Wrong word selection shows error', (tester) async {
      // Setup: navigate to seed confirmation
      // ... setup code

      // Select wrong words
      await tester.tap(find.text('wrongword1'));
      await tester.tap(find.text('wrongword2'));
      await tester.tap(find.text('wrongword3'));
      await tester.tap(find.text('wrongword4'));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Incorrect word selection'), findsOneWidget);

      // Selections should be cleared
      // User can try again
    });
  });
}
```

---

## Definition of Done (Phase 1)

### Feature Complete

- [x] All 3 screens created (warning, display, confirmation)
- [x] Backup banner created
- [x] Integration into state machine
- [x] Navigation wired up
- [x] Translations added

### Quality Assurance

- [ ] Unit tests written and passing
- [ ] Integration tests written and passing
- [ ] Manual testing completed
- [ ] Code review approved
- [ ] No linter errors
- [ ] Performance is acceptable (<16ms frame time)

### Security Verification

- [ ] Screenshot protection on all seed screens
- [ ] No seed in logs (verified)
- [ ] No seed in error messages (verified)
- [ ] Seed cleared from memory after use
- [ ] hasBackup flag correctly set
- [ ] Cannot bypass confirmation

### UX Verification

- [ ] Matches Figma designs (90%+ accuracy)
- [ ] Animations smooth
- [ ] Text is clear
- [ ] Error messages helpful
- [ ] Can navigate back/cancel
- [ ] Loading states shown

### Documentation

- [ ] Code comments added
- [ ] README updated (if needed)
- [ ] API documentation generated
- [ ] User-facing docs updated

### Deployment Ready

- [ ] Merged to dev branch
- [ ] Tested on dev environment
- [ ] Beta tested with select users
- [ ] Release notes prepared
- [ ] Support team briefed

---

## Quick Commands

### Run Tests

```bash
# Unit tests
flutter test test_units/views/wallets_manager/seed_backup/

# Integration tests
flutter test test_integration/tests/wallets_manager_tests/seed_backup_flow_test.dart

# All tests
flutter test
```

### Format & Analyze

```bash
# Format code
dart format lib/views/wallets_manager/widgets/onboarding/

# Analyze
flutter analyze

# Fix lints
dart fix --apply
```

### Run App

```bash
# Development
flutter run -d chrome --dart-define=ENV=dev

# Test new flow
# 1. Clear app data
# 2. Launch app
# 3. Click "Create Wallet"
# 4. Complete flow
# 5. Verify seed backup happens
```

---

## Common Pitfalls & Solutions

### Pitfall 1: Seed Remains in Memory

**Problem**: Seed phrase stays in widget state  
**Solution**: Clear immediately after confirmation, use `_pendingSeedPhrase = null`

### Pitfall 2: User Can Skip Confirmation

**Problem**: Navigation allows bypassing confirmation  
**Solution**: Only provide back navigation (to seed display), no skip button

### Pitfall 3: hasBackup Not Updated

**Problem**: Flag remains false after confirmation  
**Solution**: Call `kdfSdk.confirmSeedBackup(hasBackup: true)` after verification

### Pitfall 4: Banner Shows Even After Backup

**Problem**: Banner logic incorrect  
**Solution**: Check current user's wallet config: `!currentUser.wallet.config.hasBackup`

### Pitfall 5: Seed Visible in Logs

**Problem**: Logging statements include seed  
**Solution**: Never log seed, use `[REDACTED]` in debug output

### Pitfall 6: Screenshot Not Protected

**Problem**: Seed can be screenshotted  
**Solution**: Wrap in `ScreenshotSensitive` widget

---

## Code Review Checklist (Before PR)

### Security

- [ ] No plaintext seed in logs
- [ ] No seed in error messages
- [ ] Screenshot protection enabled
- [ ] Seed cleared from memory
- [ ] hasBackup flag correctly set

### Functionality

- [ ] Seed backup warning shows
- [ ] Seed display shows all words
- [ ] Seed confirmation validates correctly
- [ ] Banner appears when needed
- [ ] Banner navigates correctly
- [ ] Cannot skip confirmation
- [ ] Existing wallets unaffected

### Code Quality

- [ ] Follows BLoC pattern
- [ ] No code duplication
- [ ] Proper error handling
- [ ] Clear variable names
- [ ] Comments on complex logic
- [ ] No TODOs left
- [ ] Follows style guide

### Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing done
- [ ] Edge cases covered
- [ ] Error scenarios tested

### Documentation

- [ ] Code comments added
- [ ] Translation keys documented
- [ ] Commit messages clear
- [ ] PR description complete

---

## Phase 1 Success Criteria

After Phase 1 is complete, you should be able to:

✅ **Create a new wallet and**:

1. See seed backup warning with 3 educational points
2. View 12-word seed phrase in organized grid
3. Confirm 4 random words from the seed
4. Only access wallet AFTER confirming seed
5. See that `wallet.config.hasBackup` is `true`

✅ **For existing wallets without backup**:

1. See prominent warning banner on wallet view
2. Click banner to start backup flow
3. Complete backup and see banner disappear

✅ **Security guarantees**:

1. Seed is never logged
2. Seed cannot be screenshotted
3. Seed is cleared from memory after backup
4. Cannot skip seed confirmation
5. User must correctly identify seed words

---

## Next Steps After Phase 1

Once Phase 1 is complete and tested:

1. **Review with Product Team**

   - Demo the seed backup flow
   - Collect feedback
   - Adjust if needed

2. **Beta Release**

   - Deploy to beta testers
   - Monitor analytics
   - Fix any issues

3. **Production Release**

   - Release as v1.1.0
   - Monitor crash reports
   - Gather user feedback

4. **Begin Phase 2**
   - Start implementing passcode system
   - Create start screen
   - Add biometric support

---

## Resources & References

### Figma

- **Main Design**: https://www.figma.com/design/yiMzhZa6fXrtUeYsoxXkDP/Work-in-progress?node-id=8831-39188
- **Seed Backup Warning**: Node `8994:12153`
- **Seed Display**: Node `8994:12253`
- **Seed Confirmation**: Node `8994:12339`

### Code References

- **Existing seed confirmation** (in Settings): `lib/views/settings/widgets/security_settings/seed_settings/seed_confirmation/seed_confirmation.dart`
- **Password dialog**: `lib/views/common/wallet_password_dialog/wallet_password_dialog.dart`
- **Screenshot protection**: `lib/shared/screenshot/screenshot_sensitivity.dart`

### External Resources

- **BIP39 Spec**: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
- **BIP39 Wordlist**: https://github.com/bitcoin/bips/blob/master/bip-0039/english.txt
- **Flutter Security**: https://docs.flutter.dev/security/overview

---

## Contact & Support

**Questions?** Reach out to:

- **Product Lead**: [Name]
- **Tech Lead**: [Name]
- **Design**: [Name]

**Slack Channels**:

- `#dev-wallet` - Development discussion
- `#design-review` - Design questions
- `#qa-testing` - Testing coordination

---

**Document Version**: 1.0  
**Created**: October 1, 2025  
**Last Updated**: October 1, 2025  
**Status**: Ready for Implementation  
**Estimated Completion**: Phase 1 by October 15, 2025

---

## Quick Start Guide

### For Developers Starting TODAY:

1. **Read This Document** ✅ (You're here!)

2. **Read the Full Plan**

   - Open `NEW_LOGIN_FLOW_IMPLEMENTATION_PLAN.md`
   - Review Phase 1 section

3. **Review Figma Designs**

   - Open Figma link
   - Study nodes: `8994:12153`, `8994:12253`, `8994:12339`

4. **Setup Development Environment**

   ```bash
   cd /Users/charl/Code/UTXO/komodo-wallet-dev
   flutter pub get
   ```

5. **Create Feature Branch**

   ```bash
   git checkout -b feature/seed-backup-flow
   ```

6. **Create Files** (see Day 1-2 above)

7. **Start Coding** (see Day 3-8 above)

8. **Test** (see Testing section)

9. **Submit PR**

   - Follow PR template
   - Request review
   - Address feedback

10. **Ship It!** 🚀

---

**GOOD LUCK!** 💪

Remember: This is a critical security fix. Take your time to do it right. Users' funds depend on it.

