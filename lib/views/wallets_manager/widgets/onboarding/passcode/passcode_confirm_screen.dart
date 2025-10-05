import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
  import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/passcode/numeric_keypad.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/passcode/pin_dot_indicator.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Screen for confirming a passcode.
///
/// Validates the entered passcode against the original entry.
/// Shows error feedback if passcodes don't match.
///
/// Design reference: Figma node 8969:29722, 8986:895, 9079:26316
class PasscodeConfirmScreen extends StatefulWidget {
  const PasscodeConfirmScreen({
    required this.originalPasscode,
    required this.onPasscodeConfirmed,
    this.onCancel,
    super.key,
  });

  /// The original passcode to validate against
  final String originalPasscode;

  /// Callback when passcode is successfully confirmed
  final VoidCallback onPasscodeConfirmed;

  /// Optional callback for back/cancel button
  final VoidCallback? onCancel;

  @override
  State<PasscodeConfirmScreen> createState() => _PasscodeConfirmScreenState();
}

class _PasscodeConfirmScreenState extends State<PasscodeConfirmScreen> {
  String _passcode = '';
  String? _errorMessage;
  static const int _passcodeLength = 6;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);
    final verticalPadding = ResponsiveLayout.getVerticalPadding(context);

    return ResponsiveOnboardingScaffold(
      appBar: widget.onCancel != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onCancel,
              ),
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: ResponsiveLayout.onboardingBackgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          LocaleKeys.onboardingPasscodeConfirmTitle.tr(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: const Color(0xFFE9EAEE),
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          LocaleKeys.onboardingPasscodeConfirmHint.tr(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFFADAFC4),
                                fontSize: 16,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFF6B00),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFFF6B00),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B00),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        PinDotIndicator(
                          length: _passcodeLength,
                          filledCount: _passcode.length,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: NumericKeypad(
                    onNumberTap: _onNumberTap,
                    onDeleteTap: _onDeleteTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNumberTap(int number) {
    if (_passcode.length < _passcodeLength) {
      setState(() {
        _passcode += number.toString();
        _errorMessage = null; // Clear error when user starts typing
      });

      // Auto-validate when 6 digits entered
      if (_passcode.length == _passcodeLength) {
        _validatePasscode();
      }
    }
  }

  void _onDeleteTap() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _passcode = _passcode.substring(0, _passcode.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _validatePasscode() {
    if (_passcode == widget.originalPasscode) {
      // Success - small delay for visual feedback
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          widget.onPasscodeConfirmed();
        }
      });
    } else {
      // Error - show message and clear input
      setState(() {
        _errorMessage = LocaleKeys.onboardingPasscodeMismatch.tr();
      });

      // Clear passcode after a moment
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _passcode = '';
          });
        }
      });
    }
  }
}
