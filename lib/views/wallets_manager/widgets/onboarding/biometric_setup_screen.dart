import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/services/biometric/biometric_service.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Screen for setting up biometric authentication (Face ID/Touch ID).
///
/// Offers the user the option to enable biometric authentication for
/// convenient wallet access. Can be skipped if user prefers passcode only.
///
/// Design reference: Figma node 8969:29795, 9071:15464
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({
    required this.biometricService,
    required this.onComplete,
    this.onSkip,
    super.key,
  });

  final BiometricService biometricService;
  final ValueChanged<bool> onComplete; // true if enabled, false if skipped
  final VoidCallback? onSkip;

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  String _biometricType = 'Biometric';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
  }

  Future<void> _loadBiometricType() async {
    final type = await widget.biometricService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricType = type;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);
    final verticalPadding = ResponsiveLayout.getVerticalPadding(context);

    return ResponsiveOnboardingScaffold(
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
                      children: [
                        const SizedBox(height: 60),
                        _buildBiometricIcon(),
                        const SizedBox(height: 48),
                        Text(
                          LocaleKeys.onboardingBiometricTitle.tr(),
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
                          LocaleKeys.onboardingBiometricDescription.tr(
                            args: [_biometricType],
                          ),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFFADAFC4),
                                fontSize: 16,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
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
              child: Column(
                children: [
                  UiPrimaryButton(
                    onPressed: _isLoading ? null : _onEnableBiometric,
                    text: LocaleKeys.onboardingBiometricEnable.tr(
                      args: [_biometricType],
                    ),
                    height: 56,
                  ),
                  const SizedBox(height: 16),
                  UiSecondaryButton(
                    onPressed: _isLoading ? null : _onSkip,
                    text: LocaleKeys.onboardingBiometricSkipForNow.tr(),
                    height: 56,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricIcon() {
    IconData icon;
    if (_biometricType.contains('Face')) {
      icon = Icons.face;
    } else if (_biometricType.contains('Touch') ||
        _biometricType.contains('Fingerprint')) {
      icon = Icons.fingerprint;
    } else {
      icon = Icons.security;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 64, color: const Color(0xFF3D77E9)),
    );
  }

  Future<void> _onEnableBiometric() async {
    setState(() => _isLoading = true);

    try {
      final authenticated = await widget.biometricService.authenticate(
        reason: LocaleKeys.onboardingBiometricAuthReason.tr(),
      );

      if (authenticated) {
        await widget.biometricService.setEnabled(true);
        if (mounted) {
          widget.onComplete(true);
        }
      } else {
        // Authentication failed - show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleKeys.onboardingBiometricAuthFailed.tr()),
              backgroundColor: const Color(0xFFFF6B00),
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.onboardingBiometricError.tr()),
            backgroundColor: const Color(0xFFFF6B00),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSkip() {
    widget.onComplete(false);
    widget.onSkip?.call();
  }
}
