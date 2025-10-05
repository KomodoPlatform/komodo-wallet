import 'package:flutter/material.dart';

/// Page transition animations for onboarding flow
///
/// Phase 4: Provides smooth transitions between onboarding screens
/// including slide, fade, and scale animations.
class OnboardingPageTransitions {
  /// Slide transition from right to left (forward navigation)
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Fade transition (gentle navigation)
  static Route<T> fade<T>(Widget page, {int durationMs = 250}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: Duration(milliseconds: durationMs),
    );
  }

  /// Fade and scale transition (for important screens like success)
  static Route<T> fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        var scaleTween = Tween(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Slide and fade transition (smooth forward navigation)
  static Route<T> slideFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.3, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var slideTween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Vertical slide transition (from bottom to top)
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.3);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Extension on BuildContext for easier navigation with transitions
extension OnboardingNavigationExtension on BuildContext {
  /// Navigate with slide transition
  Future<T?> pushWithSlide<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(OnboardingPageTransitions.slideFromRight(page));
  }

  /// Navigate with fade transition
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(OnboardingPageTransitions.fade(page));
  }

  /// Navigate with fade+scale transition (for success screens)
  Future<T?> pushWithFadeScale<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(OnboardingPageTransitions.fadeScale(page));
  }

  /// Navigate with slide+fade transition
  Future<T?> pushWithSlideFade<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(OnboardingPageTransitions.slideFade(page));
  }

  /// Navigate with bottom slide transition
  Future<T?> pushWithBottomSlide<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(OnboardingPageTransitions.slideFromBottom(page));
  }
}
