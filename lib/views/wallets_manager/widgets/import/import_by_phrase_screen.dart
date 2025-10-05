import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/word_count_selector.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/word_input_field.dart';

enum ImportByPhraseStep { walletNameAndWords, moreWords }

class ImportByPhraseScreen extends StatefulWidget {
  const ImportByPhraseScreen({
    required this.onContinue,
    required this.onCancel,
    this.isHdMode = true,
    super.key,
  });

  final void Function({required String walletName, required String seedPhrase})
  onContinue;
  final VoidCallback onCancel;
  final bool isHdMode;

  @override
  State<ImportByPhraseScreen> createState() => _ImportByPhraseScreenState();
}

class _ImportByPhraseScreenState extends State<ImportByPhraseScreen> {
  ImportByPhraseStep _step = ImportByPhraseStep.walletNameAndWords;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  int _wordCount = 12;
  List<TextEditingController> _wordControllers = [];
  List<FocusNode> _wordFocusNodes = [];
  final ScrollController _scrollController = ScrollController();

  late final MnemonicValidator _mnemonicValidator;

  @override
  void initState() {
    super.initState();
    _mnemonicValidator = context.read<KomodoDefiSdk>().mnemonicValidator;
    _initializeWordFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    for (final node in _wordFocusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeWordFields() {
    // Dispose existing controllers and focus nodes
    for (final controller in _wordControllers) {
      controller.dispose();
    }
    for (final node in _wordFocusNodes) {
      node.dispose();
    }

    _wordControllers = List.generate(
      _wordCount,
      (_) => TextEditingController(),
    );

    _wordFocusNodes = List.generate(_wordCount, (_) => FocusNode());
  }

  void _onWordCountChanged(int newCount) {
    setState(() {
      _wordCount = newCount;
      _initializeWordFields();
    });
  }

  bool get _canContinue {
    if (_step == ImportByPhraseStep.walletNameAndWords) {
      // Check first 6 words for 12-word phrase or first 9 words for longer
      final wordsToCheck = _wordCount == 12 ? 6 : 9;
      return _nameController.text.trim().isNotEmpty &&
          _wordControllers
              .take(wordsToCheck)
              .every((c) => _isValidWord(c.text.trim()));
    } else {
      // Check all words
      return _wordControllers.every((c) => _isValidWord(c.text.trim()));
    }
  }

  bool _isValidWord(String word) {
    if (word.isEmpty) return false;
    final matches = _mnemonicValidator.getAutocompleteMatches(word);
    return matches.contains(word.toLowerCase());
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_step == ImportByPhraseStep.walletNameAndWords && _wordCount > 12) {
      setState(() {
        _step = ImportByPhraseStep.moreWords;
      });
      return;
    }

    // Gather all words
    final seedPhrase = _wordControllers
        .map((c) => c.text.trim().toLowerCase())
        .join(' ');

    // Validate complete seed phrase
    final validationResult = _mnemonicValidator.validateMnemonic(
      seedPhrase,
      isHd: widget.isHdMode,
    );

    if (validationResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getValidationErrorMessage(validationResult)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    widget.onContinue(
      walletName: _nameController.text.trim(),
      seedPhrase: seedPhrase,
    );
  }

  String _getValidationErrorMessage(dynamic validationResult) {
    return LocaleKeys.mnemonicInvalidError.tr();
  }

  void _onBack() {
    if (_step == ImportByPhraseStep.moreWords) {
      setState(() {
        _step = ImportByPhraseStep.walletNameAndWords;
      });
      return;
    }
    widget.onCancel();
  }

  void _onPaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();

    if (text == null || text.isEmpty) {
      return;
    }

    final words = text.split(RegExp(r'\s+'));

    // Try to match word count
    if (words.length == 12 || words.length == 18 || words.length == 24) {
      setState(() {
        _wordCount = words.length;
        _initializeWordFields();
        for (int i = 0; i < words.length && i < _wordControllers.length; i++) {
          _wordControllers[i].text = words[i].toLowerCase();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleKeys.importSeedPasted.tr(args: [words.length.toString()]),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScreenshotSensitive(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _step == ImportByPhraseStep.walletNameAndWords
                      ? LocaleKeys.importByPhraseTitle.tr()
                      : LocaleKeys.importByPhraseContinueTitle.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: const Key('import-by-phrase-close'),
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == ImportByPhraseStep.walletNameAndWords) ...[
                      _buildWalletNameField(),
                      const SizedBox(height: 20),
                      WordCountSelector(
                        selectedCount: _wordCount,
                        onCountChanged: _onWordCountChanged,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LocaleKeys.importSecretPhraseLabel.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          UiUnderlineTextButton(
                            key: const Key('paste-seed-button'),
                            text: LocaleKeys.paste.tr(),
                            onPressed: _onPaste,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _wordCount == 12
                            ? LocaleKeys.importEnterWords16.tr()
                            : LocaleKeys.importEnterWords19.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWordInputs(
                        startIndex: 0,
                        endIndex: _wordCount == 12 ? 6 : 9,
                      ),
                    ],
                    if (_step == ImportByPhraseStep.moreWords) ...[
                      Text(
                        LocaleKeys.importEnterRemainingWords.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWordInputs(
                        startIndex: _wordCount == 12 ? 6 : 9,
                        endIndex: _wordCount,
                      ),
                    ],
                    const SizedBox(height: 24),
                    UiPrimaryButton(
                      key: const Key('import-by-phrase-continue'),
                      text: _step == ImportByPhraseStep.moreWords
                          ? LocaleKeys.import.tr()
                          : LocaleKeys.continue_.tr(),
                      onPressed: _canContinue ? _onContinue : null,
                    ),
                    const SizedBox(height: 12),
                    UiUnderlineTextButton(
                      key: const Key('import-by-phrase-back'),
                      text: LocaleKeys.back.tr(),
                      onPressed: _onBack,
                    ),
                    if (_step == ImportByPhraseStep.walletNameAndWords) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // Show help dialog
                            _showSecretPhraseHelp(context);
                          },
                          child: Text(
                            LocaleKeys.importWhatIsSecretPhrase.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletNameField() {
    final walletsRepository = context.read<WalletsRepository>();

    return UiTextFormField(
      key: const Key('import-phrase-wallet-name'),
      controller: _nameController,
      autofocus: true,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      validator: (String? value) =>
          walletsRepository.validateWalletName(value ?? ''),
      inputFormatters: [LengthLimitingTextInputFormatter(40)],
      hintText: LocaleKeys.importWalletNameHint.tr(),
      onFieldSubmitted: (_) {
        _wordFocusNodes.first.requestFocus();
      },
    );
  }

  Widget _buildWordInputs({required int startIndex, required int endIndex}) {
    return Column(
      children: List.generate(endIndex - startIndex, (index) {
        final wordIndex = startIndex + index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WordInputField(
            key: Key('word-input-$wordIndex'),
            wordNumber: wordIndex + 1,
            controller: _wordControllers[wordIndex],
            focusNode: _wordFocusNodes[wordIndex],
            nextFocusNode: wordIndex < endIndex - 1
                ? _wordFocusNodes[wordIndex + 1]
                : null,
            mnemonicValidator: _mnemonicValidator,
            onWordEntered: (word) {
              // Auto-scroll to next field if needed
              if (wordIndex < endIndex - 1) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    _scrollController.animateTo(
                      _scrollController.offset + 60,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
        );
      }),
    );
  }

  void _showSecretPhraseHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.importWhatIsSecretPhrase.tr()),
        content: Text(LocaleKeys.importSecretPhraseHelp.tr()),
        actions: [
          UiPrimaryButton(
            text: LocaleKeys.gotIt.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
