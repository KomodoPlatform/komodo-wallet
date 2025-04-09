import 'package:flutter/material.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/views/common/pages/page_plate.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/backup_seed_notification.dart';

class PageLayout extends StatelessWidget {
  const PageLayout(
      {required this.content, this.header, this.noBackground = false});

  final Widget content;
  final Widget? header;
  final bool noBackground;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _MobileLayout(
        header: header,
        content: content,
        noBackground: noBackground,
      );
    }
    return _DesktopLayout(
      header: header,
      content: content,
      noBackground: noBackground,
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.content,
    this.header,
    this.noBackground = false,
  });

  final Widget? header;
  final Widget content;
  final bool noBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const BackupSeedNotification(),
        if (header != null) header!,
        Flexible(
          child: PagePlate(
            noBackground: noBackground,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                content,
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.content,
    this.header,
    this.noBackground = false,
  });

  final Widget content;
  final Widget? header;
  final bool noBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BackupSeedNotification(),
        Flexible(
          child: PagePlate(
            noBackground: noBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 23),
                if (header != null) header!,
                content,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
