import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/views/wallets_manager/widgets/onboarding/responsive_layout.dart';

/// Seed display screen that shows the user's seed phrase in a grid layout.
///
/// This screen is based on Figma designs (node 8994:12253).
/// It displays the seed phrase words in a 2-column grid with numbering
/// and includes screenshot protection to prevent accidental leakage.
class SeedDisplayScreen extends StatelessWidget {
  const SeedDisplayScreen({
    required this.seedPhrase,
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  final String seedPhrase;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final words = seedPhrase.split(' ');
    final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);
    final verticalPadding = ResponsiveLayout.getVerticalPadding(context);

    return ScreenshotSensitive(
      child: ResponsiveOnboardingScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
          title: Text(
            LocaleKeys.onboardingSeedBackupManualBackupTitle.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
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
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildSeedGrid(words),
                          const SizedBox(height: 32),
                          _buildWarningBanner(),
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
                child: UiPrimaryButton(
                  onPressed: onContinue,
                  text: LocaleKeys.continueText.tr(),
                  height: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedGrid(List<String> words) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3.2,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        return _buildWordPill(index + 1, words[index]);
      },
    );
  }

  Widget _buildWordPill(int number, String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D40),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            '$number.',
            style: const TextStyle(
              color: Color(0xFF797B89),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              word,
              style: const TextStyle(
                color: Color(0xFFADAFC4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171926),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B00)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFFF6B00), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.onboardingSeedBackupNeverShare.tr(),
              style: const TextStyle(color: Color(0xFFADAFC4), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
