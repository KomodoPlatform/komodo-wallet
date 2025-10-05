# Phase 3 Quick Reference: Import UX

## 🎯 Quick Summary

Phase 3 enhances wallet import with word-by-word seed entry, BIP39 autocomplete, and improved file import UI.

---

## 📁 New Files Created

### Import Components (`lib/views/wallets_manager/widgets/import/`)

1. **`import_method_selection.dart`** - Choose import method (phrase vs file)
2. **`word_input_field.dart`** - Individual word input with autocomplete
3. **`word_autocomplete_overlay.dart`** - Dropdown suggestions
4. **`word_count_selector.dart`** - Select 12/18/24 word phrase
5. **`import_by_phrase_screen.dart`** - Main phrase import screen
6. **`file_drop_zone.dart`** - Modern file upload UI
7. **`improved_import_by_file_screen.dart`** - Enhanced file import
8. **`legacy_seed_info_dialog.dart`** - Legacy seed explanation

### Updated Files

1. **`wallet_import_wrapper.dart`** - Refactored to use new components
2. **`assets/translations/en.json`** - Added 34 new translation keys
3. **`lib/generated/codegen_loader.g.dart`** - Regenerated translations

---

## 🔑 Key Features

### Import by Secret Phrase

- ✅ Word-by-word entry with autocomplete
- ✅ Real-time BIP39 validation
- ✅ Visual checkmarks for valid words
- ✅ Support for 12/18/24 word phrases
- ✅ Paste full seed support
- ✅ Auto-advance to next field

### Import by File

- ✅ Modern drag-and-drop UI
- ✅ Click to browse
- ✅ File validation
- ✅ Legacy seed support
- ✅ HD wallet mode toggle

---

## 🛠️ Usage Example

### Importing by Secret Phrase

```dart
// User flow:
1. Tap "Import wallet"
2. Select "Secret phrase"
3. Enter wallet name
4. Select word count (12/18/24)
5. Enter words with autocomplete
6. Create password
7. Import complete!
```

### Importing by File

```dart
// User flow:
1. Tap "Import wallet"
2. Select "Import seed file"
3. Drop file or click browse
4. Enter file password
5. Enter wallet name
6. Create new password
7. Toggle HD mode if needed
8. Check legacy seed if pre-May 2025
9. Import complete!
```

---

## 🎨 Component Architecture

```
WalletImportWrapper
├── ImportMethodSelection
│   ├── Method: Secret Phrase → ImportByPhraseScreen
│   │   ├── Wallet name field
│   │   ├── WordCountSelector (12/18/24)
│   │   ├── WordInputField (x6-24)
│   │   │   └── WordAutocompleteOverlay
│   │   └── Password step
│   └── Method: Seed File → ImprovedImportByFileScreen
│       ├── FileDropZone
│       ├── File password field
│       ├── Wallet name field
│       ├── New password fields
│       ├── HD mode toggle
│       └── LegacySeedInfoDialog
```

---

## 🧩 Integration Points

### In `iguana_wallets_manager.dart`

```dart
case WalletsManagerAction.import:
  return WalletImportWrapper(
    onImport: _importWallet,
    onCancel: _cancel,
  );
```

### BIP39 Validation

```dart
// From komodo_defi_types
final validator = context.read<KomodoDefiSdk>().mnemonicValidator;
final matches = validator.getAutocompleteMatches(text, maxResults: 5);
```

---

## 📝 Translation Keys

All keys start with `import*` or `legacy*`:

- `importMethodTitle` - "Add existing wallet"
- `importByPhraseTitle` - "Add existing wallet"
- `importWalletNameHint` - "Enter your wallet name"
- `importSecretPhraseLabel` - "Secret Phrase"
- `importFileDropZoneTitle` - "Drop your file here"
- `legacySeedDialogTitle` - "Legacy Komodo Wallet Seed"
- ... and 28 more

---

## ✅ Testing Checklist

### Phrase Import

- [ ] Autocomplete shows BIP39 words
- [ ] Valid words show checkmark
- [ ] Invalid words have no checkmark
- [ ] Can paste full seed
- [ ] Auto-advance works
- [ ] Import succeeds with valid seed
- [ ] Import fails with invalid seed

### File Import

- [ ] Can drop file
- [ ] Can click to browse
- [ ] File name displays
- [ ] Legacy checkbox shows dialog
- [ ] Import succeeds with valid file
- [ ] Import fails with wrong password

---

## 🐛 Common Issues

### Issue: Autocomplete not showing

**Solution**: Ensure `MnemonicValidator.init()` is called on app start

### Issue: Import fails with valid seed

**Solution**: Check if HD mode matches seed type (BIP39 required for HD)

### Issue: File import not working

**Solution**: Verify file is valid encrypted wallet backup

---

## 📚 Related Files

- Phase 3 Complete Doc: `docs/PHASE_3_IMPLEMENTATION_COMPLETE.md`
- Login Flow Comparison: `docs/LOGIN_FLOW_COMPARISON.md`
- New Login Flow Summary: `docs/NEW_LOGIN_FLOW_SUMMARY.md`

---

## 🚀 Quick Commands

```bash
# Format code
dart format lib/views/wallets_manager/widgets/import/

# Check lints
flutter analyze lib/views/wallets_manager/widgets/import/

# Regenerate translations
flutter pub run easy_localization:generate -S assets/translations -f keys -O lib/generated -o codegen_loader.g.dart
```

---

**Last Updated**: October 2, 2025  
**Status**: ✅ Production Ready
