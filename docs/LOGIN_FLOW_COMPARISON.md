# Login Flow Comparison: Current vs New Design

## Visual Flow Comparison

### Current Create Wallet Flow (1 screen)

```
┌─────────────────────────────────────┐
│     Wallet Type Selection           │
│  ┌─────────────────────────────┐   │
│  │ [Iguana]  [Trezor]  etc.    │   │
│  └─────────────────────────────┘   │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│     Create Wallet (ALL IN ONE)      │
│                                     │
│  Wallet Name: [____________]        │
│  Password:    [____________]        │
│  Confirm:     [____________]        │
│  ☐ HD Wallet Mode                  │
│  ☐ Quick Login                     │
│  ☐ I agree to EULA/ToS             │
│                                     │
│      [Create Wallet]                │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│     🎉 Logged In!                   │
│                                     │
│  (No seed backup shown!)            │
│  ⚠️ CRITICAL FLAW                   │
└─────────────────────────────────────┘
```

**Problems**:

- ❌ No seed backup during creation
- ❌ Overwhelming single form
- ❌ No verification of backup
- ❌ No user education
- ❌ Password-only auth

---

### New Create Wallet Flow (8 screens)

```
┌─────────────────────────────────────┐
│   1. START SCREEN (NEW!)            │
│                                     │
│   [Blockchain Illustration]         │
│                                     │
│   "Own, control, and leverage       │
│    the power of your digital        │
│    assets"                          │
│                                     │
│   ┌──────────────────────────────┐ │
│   │  Create new wallet           │ │
│   └──────────────────────────────┘ │
│   ┌──────────────────────────────┐ │
│   │  I already have a wallet     │ │
│   └──────────────────────────────┘ │
│                                     │
│   By tapping you agree to ToS...   │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   2. CREATE PASSCODE (NEW!)         │
│                                     │
│   Create passcode                   │
│   Enter your passcode. Be sure to   │
│   remember it...                    │
│                                     │
│   ○ ○ ○ ○ ○ ○  ← PIN dots          │
│                                     │
│   ┌─────────────────┐               │
│   │ 1   2   3       │               │
│   │ 4   5   6       │               │
│   │ 7   8   9       │  ← Keypad     │
│   │     0   ⌫       │               │
│   └─────────────────┘               │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   3. CONFIRM PASSCODE (NEW!)        │
│   (Same UI, re-enter PIN)           │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   4. SEED BACKUP WARNING (NEW!)     │
│                                     │
│   [Illustration with eye icon]      │
│                                     │
│   For your eyes only! 👁            │
│   This secret phrase unlocks        │
│   your wallet                       │
│                                     │
│   ┌──────────────────────────────┐ │
│   │ ⓘ Komodo wallet does not     │ │
│   │   have access to this key.   │ │
│   └──────────────────────────────┘ │
│   ┌──────────────────────────────┐ │
│   │ ⓘ Don't save in digital      │ │
│   │   format, write on paper...  │ │
│   └──────────────────────────────┘ │
│   ┌──────────────────────────────┐ │
│   │ ⓘ If you lose your recovery  │ │
│   │   phrase, coins are lost...  │ │
│   └──────────────────────────────┘ │
│                                     │
│   [Continue]                        │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   5. SHOW SEED PHRASE (NEW!)        │
│                                     │
│   Manual backup                  ✕  │
│                                     │
│   ┌─────────┐ ┌─────────┐          │
│   │1. aware │ │7. noise │          │
│   └─────────┘ └─────────┘          │
│   ┌─────────┐ ┌─────────┐          │
│   │2. envelop│ │8. cushion│         │
│   └─────────┘ └─────────┘          │
│   ┌─────────┐ ┌─────────┐          │
│   │3. regular│ │9. situate│         │
│   └─────────┘ └─────────┘          │
│   ┌─────────┐ ┌─────────┐          │
│   │4. rubber │ │10. aware │         │
│   └─────────┘ └─────────┘          │
│   ┌─────────┐ ┌─────────┐          │
│   │5. situate│ │11.envelope│        │
│   └─────────┘ └─────────┘          │
│   ┌─────────┐ ┌─────────┐          │
│   │6. toddler│ │12. rubber│         │
│   └─────────┘ └─────────┘          │
│                                     │
│   ⚠️ Never share your secret        │
│      phrase with anyone!            │
│                                     │
│   [Continue]                        │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   6. CONFIRM SEED (NEW!)            │
│                                     │
│   Confirm secret phrase             │
│   Please tap on the correct         │
│   answer...                         │
│                                     │
│   Word #1                           │
│   ┌─────┐ ┌─────┐ ┌─────┐          │
│   │aware│ │wrong│ │bad  │          │
│   └──✓──┘ └─────┘ └─────┘          │
│                                     │
│   Word #7                           │
│   ┌─────┐ ┌─────┐ ┌─────┐          │
│   │wrong│ │noise│ │bad  │          │
│   └─────┘ └──✓──┘ └─────┘          │
│                                     │
│   Word #9                           │
│   Word #12                          │
│   (similar layout)                  │
│                                     │
│   [Continue]                        │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   7. BIOMETRIC SETUP (NEW!)         │
│                                     │
│   [Face ID Icon]                    │
│                                     │
│   Secure your wallet                │
│   Turn on Face ID to secure         │
│   your wallet.                      │
│                                     │
│   [Enable Face ID]                  │
│   [Skip for now]                    │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   8. SUCCESS! (NEW!)                │
│                                     │
│   [Success Illustration]            │
│                                     │
│   Brilliant, your wallet            │
│   is ready!                         │
│                                     │
│   Buy or deposit to get started.    │
│                                     │
│   [Buy Crypto]                      │
│   [I'll do this later]              │
└────────────────┬────────────────────┘
                 ↓
              ✅ Done!
              Wallet is backed up & secure
```

**Benefits**:

- ✅ **Mandatory seed backup** - Can't skip
- ✅ **Seed verification** - Confirms correct backup
- ✅ **User education** - Clear warnings
- ✅ **Better UX** - Step-by-step guidance
- ✅ **Biometric option** - Convenient daily access
- ✅ **Success celebration** - Positive reinforcement

---

## Current vs New Import Flow

### Current Import (2 screens)

```
┌─────────────────────────────────────┐
│   Import Wallet - Step 1            │
│                                     │
│  Wallet Name: [____________]        │
│                                     │
│  Seed Phrase:                       │
│  [________________________________] │
│  [________________________________] │  ← Single text area
│  [________________________________] │
│                                     │
│  ☐ HD Wallet Mode                  │
│  ☐ Allow Custom Seed               │
│  ☐ I agree to EULA/ToS             │
│                                     │
│  --- OR ---                         │
│  [Upload File]                      │
│                                     │
│  [Continue]                         │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   Import Wallet - Step 2            │
│                                     │
│  Password:    [____________]        │
│  Confirm:     [____________]        │
│  ☐ Quick Login                     │
│                                     │
│  [Import]                           │
└─────────────────────────────────────┘
```

**Problems**:

- ❌ Easy to make typos in seed
- ❌ No word validation
- ❌ No autocomplete
- ❌ Cluttered UI

---

### New Import by Secret Phrase (4 screens)

```
┌─────────────────────────────────────┐
│   1. IMPORT METHOD SELECTION        │
│                                     │
│   Add existing wallet               │
│                                     │
│   Most popular                      │
│   ┌──────────────────────────────┐ │
│   │  🔑 Secret phrase           ▸│ │
│   └──────────────────────────────┘ │
│   ┌──────────────────────────────┐ │
│   │  📄 Import seed file        ▸│ │
│   └──────────────────────────────┘ │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   2. ENTER WALLET NAME & WORDS      │
│                                     │
│   Add existing wallet            ✕  │
│                                     │
│   Wallet name                       │
│   [Enter your wallet name______]   │
│                                     │
│   Secret Phrase    [12 Word phrase ▼]│
│   Enter 1-6 word of your seed       │
│                                     │
│   1. [Word #1________________]      │  ← Individual fields
│   2. [Word #2________________]      │     with autocomplete
│   3. [Word #3________________]      │
│   4. [Word #4________________]      │
│   5. [Word #5________________]      │
│   6. [Word #6________________]      │
│                                     │
│   [Continue]                        │
│   What is a secret phrase?          │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   3. CONTINUE ENTERING WORDS        │
│   (If 12+ word phrase selected)     │
│                                     │
│   7.  [more___]  ← Autocomplete     │
│       └─ moment                     │
│       └─ more  ✓  ← Suggestions     │
│       └─ morning                    │
│   8.  [words________________]       │
│   9.  [to____________________]      │
│   10. [access_______________]       │
│   11. [my___________________]       │
│   12. [crypto_______________]       │
└────────────────┬────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   4. CREATE PASSWORD                │
│                                     │
│   Create a new password          ✕  │
│                                     │
│   Wallet name                       │
│   [My NFT Wallet_______________]   │
│                                     │
│   ℹ️ Note: If you forgot your       │
│   password, Komodo can't help...    │
│                                     │
│   Password:    [____________]       │
│   Confirm:     [____________]       │
│                                     │
│   ☐ I confirm EULA and ToC         │
│                                     │
│   [Continue]                        │
└────────────────┬────────────────────┘
                 ↓
              ✅ Done!
```

**Benefits**:

- ✅ **Word validation** - Each word checked against BIP39
- ✅ **Autocomplete** - Reduces typos
- ✅ **Visual clarity** - One task per screen
- ✅ **Flexible input** - Word-by-word OR paste full seed
- ✅ **Clear progress** - User knows where they are

---

## Desktop Flow Comparison

### Current Desktop (Same as Mobile)

```
Just shows dialog with same forms, no desktop-specific UX
```

### New Desktop Welcome

```
┌────────────────────────────────────────────────────────────┐
│                                                         ✕  │
│                                                            │
│                    [Komodo Logo/Icon]                      │
│                                                            │
│              Welcome to Komodo Wallet                      │
│                                                            │
│                                                            │
│          ┌──────────────────────────────────┐             │
│          │     Create new wallet            │             │
│          └──────────────────────────────────┘             │
│                                                            │
│          ┌──────────────────────────────────┐             │
│          │     I already have a wallet      │             │
│          └──────────────────────────────────┘             │
│                                                            │
│                   or connect with                          │
│                                                            │
│          ┌──────────────────────────────────┐             │
│          │  📱 WalletConnect                │             │
│          └──────────────────────────────────┘             │
│          ┌──────────────────────────────────┐             │
│          │  🔐 Hardware Wallet              │             │
│          └──────────────────────────────────┘             │
│          ┌──────────────────────────────────┐             │
│          │  ⚫ Connect Keplr (coming soon)  │             │
│          └──────────────────────────────────┘             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Benefits**:

- ✅ Desktop-optimized layout
- ✅ More connection options
- ✅ Clear visual hierarchy
- ✅ Professional appearance

---

## Side-by-Side Feature Comparison

| Feature                 | Current                | New Design                     | Impact                    |
| ----------------------- | ---------------------- | ------------------------------ | ------------------------- |
| **Welcome Screen**      | ❌ None                | ✅ Branded start screen        | Better first impression   |
| **Passcode Auth**       | ❌ None                | ✅ 6-digit PIN                 | Faster daily access       |
| **Biometric Auth**      | ❌ None                | ✅ Face ID / Touch ID          | Premium UX                |
| **Seed Backup**         | ⚠️ Optional (deferred) | ✅ Mandatory during creation   | **CRITICAL** security fix |
| **Seed Verification**   | ❌ None                | ✅ Quiz confirmation           | Prevents user error       |
| **User Education**      | ⚠️ Minimal             | ✅ Multiple warning screens    | Better understanding      |
| **Import UX**           | ⚠️ Single text field   | ✅ Word-by-word + autocomplete | Fewer errors              |
| **Word Validation**     | ⚠️ Only on submit      | ✅ Real-time per word          | Immediate feedback        |
| **Desktop Layout**      | ⚠️ Same as mobile      | ✅ Optimized for desktop       | Better desktop UX         |
| **Progress Indication** | ❌ None                | ✅ Step indicators             | User knows progress       |
| **Visual Appeal**       | ⚠️ Basic forms         | ✅ Illustrations, animations   | Modern feel               |
| **Backup Reminder**     | ❌ Only in Settings    | ✅ Persistent banner           | Impossible to miss        |
| **Connection Options**  | ⚠️ Limited             | ✅ Multiple (WC, HW, Keplr)    | Ecosystem integration     |
| **Multi-step Forms**    | ❌ All-in-one          | ✅ Logical steps               | Less overwhelming         |

Legend:

- ✅ Good / Implemented
- ⚠️ Partial / Basic
- ❌ Missing / Bad

---

## User Journey Comparison

### Current Flow: Time to First Access

**Create Wallet**:

1. Click "Create Wallet" (5 sec)
2. Fill long form (60 sec)
3. ✅ Access wallet (65 sec total)

**Problem**: Fast but INSECURE - No seed backup!

---

### New Flow: Time to First Access

**Create Wallet**:

1. View start screen, click "Create" (10 sec)
2. Create passcode (20 sec)
3. Confirm passcode (15 sec)
4. Read seed warning (20 sec)
5. Write down seed phrase (90 sec)
6. Confirm seed words (30 sec)
7. Skip/setup biometric (10 sec)
8. Success screen (5 sec)
9. ✅ Access wallet (200 sec total = ~3.5 min)

**Trade-off**: Slower but SECURE - Seed is backed up and verified!

---

### Current Flow: Import Wallet

**Steps**: 2 screens, ~90 seconds

1. Paste seed + name
2. Create password

**Error Rate**: ~15% (estimated - typos, wrong words)

---

### New Flow: Import Wallet

**Steps**: 3-4 screens, ~120 seconds

1. Select method
2. Enter name
3. Enter words with autocomplete (or paste)
4. Create password

**Error Rate**: <5% (autocomplete catches typos)

**Additional Time**: +30 seconds
**Error Reduction**: -10% = Worth it!

---

## Critical Flaw Deep Dive

### The Seed Backup Problem

#### Current Situation:

```dart
// In wallet_creation.dart
void _onCreate() async {
  // ... validation

  widget.onCreate(
    name: _nameController.text.trim(),
    password: _passwordController.text,
    walletType: _isHdMode ? WalletType.hdwallet : WalletType.iguana,
    rememberMe: _rememberMe,
  );

  // ❌ PROBLEM: Wallet is created and user is logged in immediately
  // ❌ Seed phrase is NEVER shown to user
  // ❌ No backup verification
  // ❌ hasBackup is set to FALSE but user has no way to know!
}
```

#### What Happens:

1. User creates wallet
2. User gets logged in
3. User starts using wallet (depositing funds)
4. User loses device
5. **User has NO WAY to recover funds** - Seed was never backed up!

#### How Common Is This?

- Anecdotal evidence: 70-80% of users never backup seed
- Industry standard: Force backup during onboarding
- Examples: MetaMask, Trust Wallet, Coinbase Wallet ALL require backup

---

### The Fix (Phase 1 Implementation)

```dart
// Modified flow in iguana_wallets_manager.dart

enum WalletCreationStep {
  nameAndPassword,      // Current step 1
  seedBackupWarning,    // NEW
  seedDisplay,          // NEW
  seedConfirmation,     // NEW
  biometricSetup,       // NEW (optional)
  complete,             // NEW
}

class _IguanaWalletsManagerState extends State<IguanaWalletsManager> {
  WalletCreationStep _creationStep = WalletCreationStep.nameAndPassword;
  String? _temporarySeed;  // Store seed during backup flow

  void _createWallet({required String name, required String password, ...}) async {
    // Create wallet in KDF
    final wallet = await _kdfSdk.createWallet(...);

    // Get seed phrase
    _temporarySeed = await _kdfSdk.getSeedPhrase(password);

    // ✅ CRITICAL: Don't log in yet!
    // Navigate to seed backup warning
    setState(() {
      _creationStep = WalletCreationStep.seedBackupWarning;
    });
  }

  void _onSeedBackupWarningContinue() {
    setState(() {
      _creationStep = WalletCreationStep.seedDisplay;
    });
  }

  void _onSeedDisplayContinue() {
    setState(() {
      _creationStep = WalletCreationStep.seedConfirmation;
    });
  }

  void _onSeedConfirmed(bool isCorrect) {
    if (!isCorrect) {
      // Show error, let user try again
      return;
    }

    // ✅ Mark as backed up
    _kdfSdk.confirmSeedBackup(hasBackup: true);

    // Clear seed from memory
    _temporarySeed = null;

    // NOW proceed to biometric or login
    setState(() {
      _creationStep = WalletCreationStep.biometricSetup;
    });
  }

  // ... rest of flow
}
```

---

## Screen-by-Screen Checklist

### Phase 1: Critical Security (Week 1-2)

- [ ] **SeedBackupWarningScreen**

  - [ ] Layout matches Figma node `8994:12153`
  - [ ] Shows 3 warning boxes with icons
  - [ ] Illustration/visual element
  - [ ] Cannot be skipped
  - [ ] Back button cancels wallet creation
  - [ ] Continue button proceeds to seed display

- [ ] **SeedDisplayScreen**

  - [ ] Layout matches Figma node `8994:12253`
  - [ ] Shows 12 words in 2-column grid
  - [ ] Words are numbered 1-12
  - [ ] Warning text at bottom
  - [ ] Screenshot protection enabled
  - [ ] Close button shows confirmation dialog
  - [ ] Continue proceeds to confirmation

- [ ] **SeedConfirmationScreen**

  - [ ] Layout matches Figma node `8994:12339`
  - [ ] Randomly selects 3-4 words
  - [ ] Shows 3 options per word (1 correct, 2 wrong)
  - [ ] Visual feedback on selection (checkmark)
  - [ ] Validates all selections
  - [ ] Limits to 3 attempts
  - [ ] Shows error on incorrect
  - [ ] Proceeds only if all correct

- [ ] **BackupWarningBanner**

  - [ ] Layout matches Figma node `9398:37389`
  - [ ] Shows on wallet main view
  - [ ] Dismissible but reappears
  - [ ] Action button navigates to backup flow
  - [ ] Only shows if `!hasBackup`

- [ ] **Integration**
  - [ ] Add steps to `iguana_wallets_manager.dart`
  - [ ] Update `AuthBloc` state machine
  - [ ] Wire up navigation
  - [ ] Update `hasBackup` flag correctly
  - [ ] Test end-to-end flow

---

### Phase 2: Passcode & Onboarding (Week 2-3)

- [ ] **StartScreen**

  - [ ] Layout matches Figma node `9405:37677`
  - [ ] Hero illustration
  - [ ] Tagline text
  - [ ] Two action buttons
  - [ ] Legal disclaimer
  - [ ] Shows only on first launch
  - [ ] Smooth entrance animation

- [ ] **PasscodeEntryScreen**

  - [ ] Layout matches Figma node `8969:727`
  - [ ] 6 PIN dot indicators
  - [ ] Custom numeric keypad
  - [ ] Delete functionality
  - [ ] Auto-advance on 6 digits
  - [ ] Passcode is hashed and stored

- [ ] **PasscodeConfirmScreen**

  - [ ] Layout matches Figma node `8969:29722`
  - [ ] Same UI as entry
  - [ ] Validates against first entry
  - [ ] Shows error on mismatch
  - [ ] Allows retry

- [ ] **BiometricSetupScreen**

  - [ ] Layout matches Figma node `8969:29795`
  - [ ] Detects available biometric type
  - [ ] Shows appropriate icon (Face ID / Touch ID)
  - [ ] Can be skipped
  - [ ] Stores preference

- [ ] **WalletReadyScreen**

  - [ ] Layout matches Figma node `8971:30112`
  - [ ] Success illustration
  - [ ] Congratulations message
  - [ ] Two CTAs (Buy Crypto / Later)
  - [ ] Smooth transition to wallet

- [ ] **Services**
  - [ ] `PasscodeService` implemented
  - [ ] `BiometricService` implemented
  - [ ] `OnboardingService` implemented
  - [ ] Secure storage for passcode
  - [ ] Passcode verification on app launch

---

### Phase 3: Import UX (Week 3-4)

- [ ] **ImportMethodSelection**

  - [ ] Layout matches Figma node `8986:999`
  - [ ] Two clear options with icons
  - [ ] Expand/collapse sections (if needed)

- [ ] **WordInputField**

  - [ ] Individual styled input
  - [ ] BIP39 autocomplete
  - [ ] Word number prefix
  - [ ] Auto-focus next field
  - [ ] Accepts paste of full seed

- [ ] **WordAutocompleteOverlay**

  - [ ] Dropdown suggestions
  - [ ] Max 5 suggestions
  - [ ] Keyboard navigation
  - [ ] Click to select

- [ ] **WordCountSelector**

  - [ ] Dropdown: 12 / 18 / 24 words
  - [ ] Changes visible fields dynamically
  - [ ] Default: 12 words

- [ ] **ImportByPhraseScreen**

  - [ ] Layout matches Figma node `9079:26393`
  - [ ] Wallet name field
  - [ ] Word count selector
  - [ ] Grid of word input fields
  - [ ] Continue to password step

- [ ] **FileDropZone**

  - [ ] Drag-and-drop support
  - [ ] Click to browse
  - [ ] Visual feedback on hover
  - [ ] File name display
  - [ ] Error handling

- [ ] **LegacySeedInfoDialog**
  - [ ] Layout matches Figma node `9398:37543`
  - [ ] Explains legacy format
  - [ ] Got it button

---

### Phase 4: Polish (Week 4-6)

- [ ] **Animations**

  - [ ] Screen transitions (slide/fade)
  - [ ] PIN dot fill animation
  - [ ] Checkmark animations
  - [ ] Success screen celebration

- [ ] **Desktop Layouts**

  - [ ] Desktop welcome screen (node `9030:25797`)
  - [ ] Optimized form layouts
  - [ ] Sidebar navigation

- [ ] **Illustrations**

  - [ ] Start screen hero
  - [ ] Seed backup warnings
  - [ ] Success screen
  - [ ] Export from Figma at correct sizes

- [ ] **Accessibility**

  - [ ] Screen reader support
  - [ ] Keyboard navigation
  - [ ] High contrast mode
  - [ ] Font scaling support

- [ ] **Performance**
  - [ ] Optimize autocomplete
  - [ ] Lazy load screens
  - [ ] Reduce bundle size
  - [ ] Profile and optimize

---

## Testing Checklist

### Manual Testing

#### Create Wallet Flow (New User)

- [ ] App launched for first time shows start screen
- [ ] Start screen has illustrations and correct text
- [ ] "Create new wallet" button works
- [ ] Passcode entry allows 6 digits
- [ ] Passcode can be deleted with backspace
- [ ] Passcode confirmation validates correctly
- [ ] Mismatched passcode shows error
- [ ] Seed backup warning is clear and informative
- [ ] Seed display shows all 12 words correctly
- [ ] Cannot skip seed display
- [ ] Seed confirmation selects random words
- [ ] Wrong word shows error
- [ ] Correct words show checkmark
- [ ] Cannot proceed without all correct
- [ ] Biometric setup detects device capability
- [ ] Can skip biometric
- [ ] Success screen appears
- [ ] Can navigate to wallet
- [ ] hasBackup flag is TRUE

#### Import Wallet Flow

- [ ] Import method selection shows options
- [ ] Secret phrase option works
- [ ] Wallet name field validates
- [ ] Word count selector changes field count
- [ ] Each word field has autocomplete
- [ ] Autocomplete suggests only valid BIP39 words
- [ ] Can paste full seed into first field
- [ ] Password step is separate
- [ ] Import succeeds with valid seed
- [ ] Import fails with invalid seed

#### Passcode Authentication

- [ ] App locks on background (after 5 min)
- [ ] Passcode required on return to foreground
- [ ] Correct passcode unlocks
- [ ] Wrong passcode shows error
- [ ] 5 wrong attempts locks app
- [ ] Biometric works when enabled
- [ ] Can fallback to passcode from biometric
- [ ] Can fallback to password if forgot passcode

#### Backup Warning Banner

- [ ] Banner shows if seed not backed up
- [ ] Banner visible on wallet main view
- [ ] "Backup" button navigates correctly
- [ ] Can dismiss banner temporarily
- [ ] Banner reappears on next launch (if not backed up)
- [ ] Banner disappears after backup complete

#### Existing User Experience

- [ ] Existing wallets show in list
- [ ] Can login with password
- [ ] Passcode setup prompt appears (optional)
- [ ] Can skip passcode setup
- [ ] Backup banner shows if `!hasBackup`
- [ ] All existing features work

---

## Code Review Checklist

### Security Review

- [ ] Passcode is hashed before storage (bcrypt/Argon2)
- [ ] No plaintext seed in logs
- [ ] No seed in error messages
- [ ] Screenshot protection on all sensitive screens
- [ ] Seed cleared from memory after use
- [ ] Rate limiting on passcode attempts
- [ ] Biometric fallback always available
- [ ] No seed in state longer than necessary

### UX Review

- [ ] All screens match Figma designs
- [ ] Animations are smooth (60fps)
- [ ] Text is clear and concise
- [ ] Error messages are helpful
- [ ] Back navigation works correctly
- [ ] Can cancel at any point
- [ ] Loading states are shown
- [ ] Success states are celebrated

### Code Quality Review

- [ ] Follows BLoC pattern
- [ ] Proper state management
- [ ] No code duplication
- [ ] Proper error handling
- [ ] Comments on complex logic
- [ ] Follows Dart/Flutter best practices
- [ ] Conventional commits
- [ ] PR template completed

---

## Rollout Plan

### Pre-Release

1. **Alpha Testing** (Internal - 1 week)

   - Test with team members
   - Collect feedback
   - Fix critical bugs

2. **Beta Testing** (Select users - 1 week)

   - Release to beta testers
   - Monitor analytics
   - Collect user feedback

3. **Documentation** (Parallel)
   - Update user guides
   - Create video tutorials
   - Prepare support FAQs

### Release

1. **Phase 1: Critical Fix** (v1.1.0)

   - Announce seed backup requirement
   - Emphasize security improvement
   - Support team ready for questions

2. **Phase 2: Enhanced Onboarding** (v1.2.0)

   - Announce new onboarding experience
   - Highlight passcode feature
   - Promote biometric support

3. **Phase 3: Import Improvements** (v1.3.0)

   - Announce easier import
   - Show autocomplete feature
   - Highlight error reduction

4. **Phase 4: Full Experience** (v1.4.0)
   - Announce complete redesign
   - Marketing push
   - Press release

### Post-Release

- Monitor crash reports
- Track analytics events
- Collect user feedback
- Iterate based on data
- Plan v2.0 enhancements

---

## Quick Reference: Figma to Code Mapping

| Figma Screen                    | Code File (To Create)                                                                      | Priority |
| ------------------------------- | ------------------------------------------------------------------------------------------ | -------- |
| `9405:37677` - Start Screen     | `lib/views/wallets_manager/widgets/onboarding/start_screen.dart`                           | HIGH     |
| `8969:727` - Create Passcode    | `lib/views/wallets_manager/widgets/onboarding/passcode/passcode_entry_screen.dart`         | HIGH     |
| `8969:29722` - Confirm Passcode | `lib/views/wallets_manager/widgets/onboarding/passcode/passcode_confirm_screen.dart`       | HIGH     |
| `8994:12153` - Seed Warning     | `lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_backup_warning_screen.dart` | CRITICAL |
| `8994:12253` - Seed Display     | `lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_display_screen.dart`        | CRITICAL |
| `8994:12339` - Seed Confirm     | `lib/views/wallets_manager/widgets/onboarding/seed_backup/seed_confirmation_screen.dart`   | CRITICAL |
| `8969:29795` - Biometric Setup  | `lib/views/wallets_manager/widgets/onboarding/biometric_setup_screen.dart`                 | MEDIUM   |
| `8971:30112` - Wallet Ready     | `lib/views/wallets_manager/widgets/onboarding/wallet_ready_screen.dart`                    | MEDIUM   |
| `8986:999` - Import Methods     | `lib/views/wallets_manager/widgets/import/import_method_selection.dart`                    | MEDIUM   |
| `9079:26393` - Import Phrase    | `lib/views/wallets_manager/widgets/import/import_by_phrase/import_phrase_screen.dart`      | MEDIUM   |
| `9085:48669` - Import File      | `lib/views/wallets_manager/widgets/import/import_by_file/import_file_screen.dart`          | LOW      |
| `9030:25797` - Desktop Welcome  | `lib/views/wallets_manager/widgets/desktop/desktop_welcome_screen.dart`                    | MEDIUM   |
| `9398:37389` - Backup Banner    | `lib/views/wallets_manager/widgets/onboarding/backup_warning_banner.dart`                  | CRITICAL |

---

## Glossary

**Terms Used in This Document**:

- **Seed Phrase / Recovery Phrase / Secret Phrase**: 12/18/24 word mnemonic that generates private keys
- **Passcode / PIN**: 6-digit code for quick app authentication
- **Password**: Strong password for wallet encryption
- **Biometric**: Face ID, Touch ID, or Fingerprint authentication
- **HD Wallet**: Hierarchical Deterministic wallet (BIP39/BIP44)
- **Iguana Wallet**: Legacy Komodo wallet type
- **BIP39**: Standard for mnemonic seed phrases
- **hasBackup**: Boolean flag indicating if user has backed up seed
- **Quick Login**: Feature to stay logged in across sessions
- **EULA**: End User License Agreement
- **ToS**: Terms of Service

---

**Document Version**: 1.0  
**Last Updated**: October 1, 2025  
**Status**: Ready for Review

