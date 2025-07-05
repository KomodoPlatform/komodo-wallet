import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/widgets/disclaimer/constants.dart';
import 'package:web_dex/shared/widgets/disclaimer/tos_content.dart';

class Disclaimer extends StatefulWidget {
  const Disclaimer({Key? key, required this.onClose}) : super(key: key);
  final Function() onClose;

  @override
  State<Disclaimer> createState() => _DisclaimerState();
}

class _DisclaimerState extends State<Disclaimer> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final List<TextSpan> disclaimerToSText = <TextSpan>[
      TextSpan(
          text: disclaimerEulaTitle2,
          style: Theme.of(context).textTheme.titleLarge),
      TextSpan(
          text: disclaimerEulaParagraph2,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle3,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaTitle4,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph3,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle5,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph4,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle6,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph5,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle7,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph6,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle8,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph7,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle9,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph8,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle10,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph9,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle11,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph10,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle12,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph11,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle13,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph12,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle14,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph13,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle15,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph14,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle16,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph15,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle17,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph16,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle18,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph17,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle19,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph18,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerEulaTitle20,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerEulaParagraph19,
          style: Theme.of(context).textTheme.bodyMedium)
    ];

    return Column(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height * 2 / 3,
          child: SingleChildScrollView(
            controller: ScrollController(),
            child: TosContent(disclaimerToSText: disclaimerToSText),
          ),
        ),
        const SizedBox(height: 24),
        UiPrimaryButton(
          key: const Key('close-disclaimer'),
          onPressed: widget.onClose,
          width: 300,
          text: LocaleKeys.close.tr(),
        ),
      ],
    );
  }
}
