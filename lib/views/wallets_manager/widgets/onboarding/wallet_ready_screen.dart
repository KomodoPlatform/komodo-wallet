import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Success screen shown after wallet setup is complete.
///
/// Congratulates the user and offers next actions like buying crypto
/// or proceeding to the wallet.
///
/// Design reference: Figma node 8971:30112
class WalletReadyScreen extends StatelessWidget {
  const WalletReadyScreen({
    required this.onContinue,
    this.onBuyCrypto,
    super.key,
  });

  /// Callback when user wants to continue to wallet
  final VoidCallback onContinue;

  /// Optional callback when user wants to buy crypto
  final VoidCallback? onBuyCrypto;

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
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        _buildSuccessIllustration(),
                        const SizedBox(height: 48),
                        Text(
                          LocaleKeys.onboardingSuccessTitle.tr(),
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
                          LocaleKeys.onboardingSuccessDescription.tr(),
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
                  if (onBuyCrypto != null) ...[
                    UiPrimaryButton(
                      onPressed: onBuyCrypto,
                      text: LocaleKeys.onboardingSuccessBuyCrypto.tr(),
                      height: 56,
                    ),
                    const SizedBox(height: 16),
                  ],
                  UiSecondaryButton(
                    onPressed: onContinue,
                    text: onBuyCrypto != null
                        ? LocaleKeys.onboardingSuccessLater.tr()
                        : LocaleKeys.continueText.tr(),
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

  Widget _buildSuccessIllustration() {
    return const _AnimatedSuccessIllustration();
  }
}

/// Animated success illustration with celebration effects
///
/// Phase 4: Enhanced with pulsing rings and checkmark animation
class _AnimatedSuccessIllustration extends StatefulWidget {
  const _AnimatedSuccessIllustration();

  @override
  State<_AnimatedSuccessIllustration> createState() =>
      _AnimatedSuccessIllustrationState();
}

class _AnimatedSuccessIllustrationState
    extends State<_AnimatedSuccessIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkmarkScaleAnimation;
  late Animation<double> _ring1Animation;
  late Animation<double> _ring2Animation;
  late Animation<double> _ring1OpacityAnimation;
  late Animation<double> _ring2OpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Checkmark appears with bounce
    _checkmarkScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_controller);

    // Rings expand outward with fade
    _ring1Animation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _ring2Animation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _ring1OpacityAnimation = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _ring2OpacityAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFF171926),
                  shape: BoxShape.circle,
                ),
              ),

              // Animated ring 2 (outer)
              Transform.scale(
                scale: _ring2Animation.value,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(
                        0xFF00D395,
                      ).withOpacity(_ring2OpacityAnimation.value),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Animated ring 1 (inner)
              Transform.scale(
                scale: _ring1Animation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(
                        0xFF00D395,
                      ).withOpacity(_ring1OpacityAnimation.value),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Animated checkmark circle
              Transform.scale(
                scale: _checkmarkScaleAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D395),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
