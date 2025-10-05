import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Start/welcome screen shown on first app launch.
///
/// This screen provides the initial entry point for new users, offering
/// options to create a new wallet or import an existing one. It also displays
/// legal disclaimers and brand messaging.
///
/// Design reference: Figma node 9405:37677, 9586:584, 9602:6318
///
/// Phase 4: Enhanced with entrance animations and responsive desktop layout
class StartScreen extends StatefulWidget {
  const StartScreen({
    required this.onCreateWallet,
    required this.onImportWallet,
    super.key,
  });

  /// Callback when user taps "Create new wallet"
  final VoidCallback onCreateWallet;

  /// Callback when user taps "I already have a wallet"
  final VoidCallback onImportWallet;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1020),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF060B1C), Color(0xFF0C1020)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ResponsiveLayout.isDesktop(context)
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: ResponsiveLayout.maxContentWidth,
                        ),
                        child: _buildContent(context),
                      ),
                    )
                  : _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveLayout.getHorizontalPadding(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Hero illustration/logo
                _buildHeroSection(context),

                const SizedBox(height: 48),

                // Tagline
                _buildTagline(context),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: EdgeInsets.all(
            ResponsiveLayout.getHorizontalPadding(context),
          ),
          child: Column(
            children: [
              UiPrimaryButton(
                onPressed: widget.onCreateWallet,
                text: LocaleKeys.onboardingCreateNewWallet.tr(),
                height: 56,
              ),
              const SizedBox(height: 16),
              UiSecondaryButton(
                onPressed: widget.onImportWallet,
                text: LocaleKeys.onboardingAlreadyHaveWallet.tr(),
                height: 56,
              ),
              const SizedBox(height: 24),

              // Legal disclaimer
              _buildLegalDisclaimer(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final iconSize = ResponsiveLayout.getIconSize(context, baseSize: 64);

    return Column(
      children: [
        // Logo/Icon placeholder
        // TODO: Replace with actual logo/illustration from assets
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF171926),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            size: iconSize,
            color: const Color(0xFF3D77E9),
          ),
        ),
        const SizedBox(height: 24),

        // App name
        Text(
          'Komodo Wallet',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: const Color(0xFFE9EAEE),
            fontWeight: FontWeight.w700,
            fontSize: 32 * ResponsiveLayout.getFontSizeMultiplier(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Text(
      LocaleKeys.onboardingStartScreenTagline.tr(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(0xFFADAFC4),
        fontSize: 18,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLegalDisclaimer(BuildContext context) {
    return Text(
      LocaleKeys.onboardingStartScreenLegal.tr(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF797B89),
        fontSize: 12,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}
