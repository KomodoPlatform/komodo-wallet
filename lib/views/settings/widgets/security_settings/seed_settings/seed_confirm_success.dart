import 'package:web_dex/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/common/app_assets.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class SeedConfirmSuccess extends StatelessWidget {
  const SeedConfirmSuccess();

  @override
  Widget build(BuildContext context) {
    return isMobile ? const _MobileLayout() : const _DesktopLayout();
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return DexScrollbar(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 25),
                  DexSvgImage(path: Assets.seedSuccess),
                  SizedBox(height: 20),
                  _Title(),
                  SizedBox(height: 9),
                  _Body(),
                  SizedBox(height: 20),
                  _Button(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 25),
              DexSvgImage(path: Assets.seedSuccess),
              SizedBox(height: 20),
              _Title(),
              SizedBox(height: 9),
              _Body(),
              SizedBox(height: 20),
              _Button(),
            ],
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.seedPhraseSuccessTitle.tr(),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16,
          ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 415),
      child: Row(
        children: [
          Expanded(
            child: Text(
              LocaleKeys.seedPhraseSuccessBody.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();
    const event = ResetEvent();
    gotoSecurityMain() => bloc.add(event);

    return UiPrimaryButton(
      key: const Key('seed-confirm-got-it'),
      width: 198,
      height: isMobile ? 52 : 40,
      onPressed: gotoSecurityMain,
      text: LocaleKeys.seedPhraseGotIt.tr(),
    );
  }
}
