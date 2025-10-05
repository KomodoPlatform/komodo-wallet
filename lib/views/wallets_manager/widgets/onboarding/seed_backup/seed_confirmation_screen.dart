import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Seed confirmation screen that verifies the user has correctly written down
/// their seed phrase.
///
/// This screen is based on Figma designs (node 8994:12339, 9079:25713).
/// It randomly selects 4 words from the seed phrase and presents multiple
/// choice questions to verify the user has backed up their seed correctly.
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
      final wrongWords = words.where((w) => w != correctWord).toList()
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
    return ScreenshotSensitive(
      child: ResponsiveOnboardingScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
          title: Text(
            LocaleKeys.onboardingSeedBackupConfirmTitle.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: ResponsiveLayout.onboardingBackgroundGradient,
          ),
          child: Column(
            children: [
              Expanded(child: _buildScrollableContent(context)),
              _buildBottomButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);
    final verticalPadding = ResponsiveLayout.getVerticalPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.onboardingSeedBackupConfirmHint.tr(),
                style: const TextStyle(color: Color(0xFFADAFC4), fontSize: 14),
              ),
              const SizedBox(height: 32),
              ..._verifications.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildWordQuestion(entry.value, entry.key),
                );
              }),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF6B00)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Color(0xFFFF6B00),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFF6B00)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_attemptsRemaining < 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    LocaleKeys.onboardingSeedBackupAttemptsRemaining.tr(
                      args: ['$_attemptsRemaining'],
                    ),
                    style: const TextStyle(
                      color: Color(0xFF797B89),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);
    final verticalPadding = ResponsiveLayout.getVerticalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        verticalPadding,
      ),
      child: UiPrimaryButton(
        onPressed: _isAllSelected ? _onVerify : null,
        text: LocaleKeys.continueText.tr(),
        height: 50,
      ),
    );
  }

  Widget _buildWordQuestion(
    SeedWordVerification verification,
    int questionIndex,
  ) {
    final selectedWord = _selectedWords[questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.onboardingSeedBackupWordNumber.tr(
            args: ['${verification.wordIndex + 1}'],
          ),
          style: const TextStyle(
            color: Color(0xFFADAFC4),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: verification.options.map((option) {
            final isThisSelected = selectedWord == option;
            final isCorrect =
                isThisSelected && option == verification.correctWord;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D77E9) : const Color(0xFF2B2D40),
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: const Color(0xFF3D77E9), width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected && isCorrect)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.check,
                        size: 16 * value,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            Flexible(
              child: Text(
                word,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFADAFC4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          _errorMessage = LocaleKeys.onboardingSeedBackupIncorrectSelection
              .tr();
          // Clear selections
          _selectedWords.clear();
        }
      });
    }
  }
}

/// Data class representing a seed word verification question.
class SeedWordVerification {
  SeedWordVerification({
    required this.wordIndex,
    required this.correctWord,
    required this.options,
  });

  final int wordIndex;
  final String correctWord;
  final List<String> options;
}
