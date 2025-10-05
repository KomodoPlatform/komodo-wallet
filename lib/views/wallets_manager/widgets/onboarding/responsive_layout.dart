import 'package:flutter/material.dart';

/// Responsive layout helper for onboarding screens
///
/// Phase 4: Provides desktop-optimized layouts and breakpoints
/// for responsive design across mobile, tablet, and desktop platforms.
class ResponsiveLayout {
  /// Mobile breakpoint (below 600px)
  static const double mobileBreakpoint = 600;

  /// Tablet breakpoint (600-1024px)
  static const double tabletBreakpoint = 1024;

  /// Desktop breakpoint (above 1024px)
  static const double desktopBreakpoint = 1024;

  /// Maximum content width for desktop to prevent overstretching
  static const double maxContentWidth = 600;

  /// Maximum content width for wide desktop layouts (like forms with sidebars)
  static const double maxWideContentWidth = 1200;

  /// Gradient used across onboarding/authentication backgrounds
  static const LinearGradient onboardingBackgroundGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF060B1C), Color(0xFF0C1020)],
  );

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get appropriate horizontal padding based on screen size
  static double getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 24.0;
    }
  }

  /// Get appropriate vertical padding based on screen size
  static double getVerticalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 32.0;
    } else {
      return 24.0;
    }
  }

  /// Combined page padding that scales with screen size
  static EdgeInsets getPagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: getVerticalPadding(context),
    );
  }

  /// Wrap content with max width constraint for desktop
  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    if (!isDesktop(context)) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? maxContentWidth),
        child: child,
      ),
    );
  }

  /// Build responsive layout with different widgets for mobile/desktop
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get font size multiplier based on screen size
  static double getFontSizeMultiplier(BuildContext context) {
    if (isDesktop(context)) {
      return 1.1;
    } else {
      return 1.0;
    }
  }

  /// Get appropriate icon size based on screen size
  static double getIconSize(BuildContext context, {required double baseSize}) {
    if (isDesktop(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize;
    }
  }
}

/// Responsive onboarding scaffold for consistent desktop/mobile layouts
///
/// Automatically centers content on desktop and applies appropriate
/// constraints and padding.
class ResponsiveOnboardingScaffold extends StatelessWidget {
  const ResponsiveOnboardingScaffold({
    required this.body,
    this.appBar,
    this.maxWidth,
    this.showBackButton = false,
    this.onBack,
    this.backgroundColor,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final double? maxWidth;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFF0C1020),
      appBar:
          appBar ??
          (showBackButton && onBack != null
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
                )
              : null),
      body: SafeArea(
        child: isDesktop
            ? Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth ?? ResponsiveLayout.maxContentWidth,
                  ),
                  child: body,
                ),
              )
            : body,
      ),
    );
  }
}

/// Desktop welcome layout with sidebar and main content area
///
/// Phase 4: Desktop-optimized welcome screen layout
class DesktopWelcomeLayout extends StatelessWidget {
  const DesktopWelcomeLayout({
    required this.sidebar,
    required this.mainContent,
    super.key,
  });

  final Widget sidebar;
  final Widget mainContent;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout.builder(
      context: context,
      mobile: mainContent,
      desktop: Row(
        children: [
          // Sidebar (40% width)
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF060B1C), Color(0xFF0C1020)],
                ),
                border: Border(
                  right: BorderSide(color: Color(0xFF2B2D40), width: 1),
                ),
              ),
              child: sidebar,
            ),
          ),
          // Main content (60% width)
          Expanded(flex: 6, child: mainContent),
        ],
      ),
    );
  }
}

/// Two-column form layout for desktop
///
/// Phase 4: Optimized form layouts for desktop screens
class DesktopTwoColumnLayout extends StatelessWidget {
  const DesktopTwoColumnLayout({
    required this.leftColumn,
    required this.rightColumn,
    this.columnSpacing = 48.0,
    super.key,
  });

  final Widget leftColumn;
  final Widget rightColumn;
  final double columnSpacing;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout.builder(
      context: context,
      mobile: Column(
        children: [leftColumn, const SizedBox(height: 24), rightColumn],
      ),
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftColumn),
          SizedBox(width: columnSpacing),
          Expanded(child: rightColumn),
        ],
      ),
    );
  }
}
