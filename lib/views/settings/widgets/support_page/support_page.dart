import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:komodo_wallet/common/app_assets.dart';
import 'package:komodo_wallet/common/screen.dart';
import 'package:komodo_wallet/generated/codegen_loader.g.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/views/settings/widgets/support_page/support_item.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class SupportPage extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  SupportPage({Key? key = const Key('support-page')}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return SingleChildScrollView(
        controller: ScrollController(),
        child: getSettingContent(context),
      );
    } else {
      return getSettingContent(context);
    }
  }

  Widget getSettingContent(BuildContext context) {
    return Container(
      margin: isMobile
          ? const EdgeInsets.symmetric(horizontal: 15)
          : isTablet
              ? const EdgeInsets.all(30)
              : const EdgeInsets.all(0.0),
      padding: isMobile
          ? null
          : const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: !isMobile,
            child: SelectableText(
              LocaleKeys.support.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Stack(
              children: [
                const _DiscordIcon(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18.0,
                    horizontal: 5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: isMobile ? 0 : 160),
                        child: SelectableText(
                          LocaleKeys.supportAskSpan.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      UiBorderButton(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        prefix: Icon(
                          Icons.discord,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        text: LocaleKeys.supportDiscordButton.tr(),
                        fontSize: isMobile ? 13 : 14,
                        width: 400,
                        height: 40,
                        allowMultiline: true,
                        onPressed: () {
                          launchURLString(
                            'https://komodoplatform.com/discord',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            LocaleKeys.supportFrequentlyQuestionSpan.tr(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 30),
          /*
            if (!isMobile)
              Flexible(
                child: DexScrollbar(
                  isMobile: isMobile,
                  scrollController: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                    itemCount: supportInfo.length,
                    itemBuilder: (context, i) => SupportItem(
                      data: supportInfo[i],
                    ),
                  ),
                ),
              ),
            if (isMobile)
            */
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            child: Column(
              children: supportInfo.asMap().entries.map((entry) {
                return SupportItem(
                  data: entry.value,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscordIcon extends StatelessWidget {
  const _DiscordIcon();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -100,
      top: -85,
      child: Visibility(
        visible: !isMobile,
        child: const SizedBox(
          width: 285,
          height: 220,
          child: Opacity(
            opacity: 0.1,
            child: DexSvgImage(path: Assets.discord),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, String>> supportInfo = [
  {
    'title': LocaleKeys.supportInfoTitle1.tr(),
    'content': LocaleKeys.supportInfoContent1.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle2.tr(),
    'content': LocaleKeys.supportInfoContent2.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle3.tr(),
    'content': LocaleKeys.supportInfoContent3.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle4.tr(),
    'content': LocaleKeys.supportInfoContent4.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle5.tr(),
    'content': LocaleKeys.supportInfoContent5.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle6.tr(),
    'content': LocaleKeys.supportInfoContent6.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle7.tr(),
    'content': LocaleKeys.supportInfoContent7.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle8.tr(),
    'content': LocaleKeys.supportInfoContent8.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle9.tr(),
    'content': LocaleKeys.supportInfoContent9.tr(),
  },
  {
    'title': LocaleKeys.supportInfoTitle10.tr(),
    'content': LocaleKeys.supportInfoContent10.tr(),
  }
];
