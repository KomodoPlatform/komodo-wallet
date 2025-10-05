import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/passcode/numeric_keypad.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/passcode/pin_dot_indicator.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Screen for creating a new 6-digit passcode.
///
/// Displays a numeric keypad for passcode entry with visual feedback
/// through PIN dots. Auto-advances when 6 digits are entered.
///
/// Design reference: Figma node 8969:727, 8986:852
class PasscodeEntryScreen extends StatefulWidget {
  const PasscodeEntryScreen({
    required this.onPasscodeEntered,
    this.onCancel,
    super.key,
  });

  /// Callback when 6 digits have been entered
  final ValueChanged<String> onPasscodeEntered;

  /// Optional callback for back/cancel button
  final VoidCallback? onCancel;

  @override
  State<PasscodeEntryScreen> createState() => _PasscodeEntryScreenState();
}

class _PasscodeEntryScreenState extends State<PasscodeEntryScreen> {
  String _passcode = '';
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
                          LocaleKeys.onboardingPasscodeCreateTitle.tr(),
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
                          LocaleKeys.onboardingPasscodeCreateHint.tr(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFFADAFC4),
                                fontSize: 16,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 64),
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
      });

      // Auto-submit when 6 digits entered
      if (_passcode.length == _passcodeLength) {
        // Small delay for visual feedback
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            widget.onPasscodeEntered(_passcode);
          }
        });
      }
    }
  }

  void _onDeleteTap() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _passcode = _passcode.substring(0, _passcode.length - 1);
      });
    }
  }
}
