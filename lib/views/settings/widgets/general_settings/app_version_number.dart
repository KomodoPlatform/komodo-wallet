import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';

class AppVersionNumber extends StatelessWidget {
  const AppVersionNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            LocaleKeys.komodoWallet.tr(),
            style: _textStyle,
          ),
          SelectableText(
            '${LocaleKeys.version.tr()}: ${packageInformation.packageVersion}',
            style: _textStyle,
          ),
          SelectableText(
            '${LocaleKeys.commit.tr()}: ${packageInformation.commitHash}',
            style: _textStyle,
          ),
          const _ApiVersion(),
          const SizedBox(height: 4),
          const _BundledCoinsCommitConfig(),
        ],
      ),
    );
  }
}

class _BundledCoinsCommitConfig extends StatelessWidget {
  // ignore: unused_element_parameter
  const _BundledCoinsCommitConfig({super.key});

  // Get the value from `app_build/build_config.json` under the key
  // "coins"->"bundled_coins_repo_commit"
  Future<String> getBundledCoinsCommit() async {
    final buildConfigPath =
        'packages/komodo_defi_framework/app_build/build_config.json';
    final String commit = await rootBundle
        .loadString(buildConfigPath)
        .then(
          (String jsonString) =>
              json.decode(jsonString) as Map<String, dynamic>,
        )
        .then(
          (Map<String, dynamic> json) => json['coins'] as Map<String, dynamic>,
        )
        .then(
          (Map<String, dynamic> json) =>
              json['bundled_coins_repo_commit'] as String,
        );
    return commit;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.coinAssets.tr(), style: _textStyle),
        FutureBuilder<String>(
          future: getBundledCoinsCommit(),
          builder: (context, snapshot) {
            final String? commitHash =
                (!snapshot.hasData) ? null : _tryParseCommitHash(snapshot.data);

            return SelectableText(
              '${LocaleKeys.bundled.tr()}: ${commitHash ?? LocaleKeys.unknown.tr()}',
              style: _textStyle,
            );
          },
        ),
        SelectableText(
          // TODO!: add sdk getter for updated commit hash
          '${LocaleKeys.updated.tr()}: ${LocaleKeys.updated.tr()}',
          style: _textStyle,
        ),
      ],
    );
  }
}

class _ApiVersion extends StatelessWidget {
  // ignore: unused_element_parameter
  const _ApiVersion({super.key});

  @override
  Widget build(BuildContext context) {
    final mm2Api = RepositoryProvider.of<Mm2Api>(context);

    return Row(
      children: [
        Flexible(
          child: FutureBuilder<String?>(
            future: mm2Api.version(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final String? commitHash = _tryParseCommitHash(snapshot.data);
              if (commitHash == null) return const SizedBox.shrink();

              return SelectableText(
                '${LocaleKeys.api.tr()}: $commitHash',
                style: _textStyle,
              );
            },
          ),
        ),
      ],
    );
  }
}

String? _tryParseCommitHash(String? result) {
  if (result == null) return null;

  final RegExp regExp = RegExp(r'[0-9a-fA-F]{7,40}');
  final Match? match = regExp.firstMatch(result);

  // Only take first 7 characters of the first match
  return match?.group(0)?.substring(0, 7);
}

const _textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
