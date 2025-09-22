import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/version_info/version_info_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

class AppVersionNumber extends StatelessWidget {
  const AppVersionNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: BlocBuilder<VersionInfoBloc, VersionInfoState>(
        builder: (context, state) {
          if (state is VersionInfoLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(LocaleKeys.komodoWallet.tr(), style: _textStyle),
                if (state.appVersion != null)
                  SelectableText(
                    '${LocaleKeys.version.tr()}: ${state.appVersion}',
                    style: _textStyle,
                  ),
                if (state.commitHash != null)
                  SelectableText(
                    '${LocaleKeys.commit.tr()}: ${state.commitHash}',
                    style: _textStyle,
                  ),
                if (state.apiCommitHash != null)
                  SelectableText(
                    '${LocaleKeys.api.tr()}: ${state.apiCommitHash}',
                    style: _textStyle,
                  ),
                const SizedBox(height: 4),
                CoinsCommitInfo(state: state),
              ],
            );
          } else if (state is VersionInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is VersionInfoError) {
            return Text('Error: ${state.message}');
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class CoinsCommitInfo extends StatelessWidget {
  const CoinsCommitInfo({super.key, required this.state});

  final VersionInfoLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.coinAssets.tr(), style: _textStyle),
        if (state.currentCoinsCommit != null)
          SelectableText(
            '${LocaleKeys.bundled.tr()}: ${state.currentCoinsCommit}',
            style: _textStyle,
          ),
        if (state.latestCoinsCommit != null)
          SelectableText(
            '${LocaleKeys.updated.tr()}: ${state.latestCoinsCommit}',
            style: _textStyle,
          ),
      ],
    );
  }
}

const _textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
