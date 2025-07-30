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
          text: disclaimerTocTitle2,
          style: Theme.of(context).textTheme.titleLarge),
      TextSpan(
          text: disclaimerTocParagraph2,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle3,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocTitle4,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph3,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle5,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph4,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle6,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph5,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle7,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph6,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle8,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph7,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle9,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph8,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle10,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph9,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle11,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph10,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle12,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph11,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle13,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph12,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle14,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph13,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle15,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph14,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle16,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph15,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle17,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocTitle19,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph18,
          style: Theme.of(context).textTheme.bodyMedium),
      TextSpan(
          text: disclaimerTocTitle20,
          style: Theme.of(context).textTheme.titleSmall),
      TextSpan(
          text: disclaimerTocParagraph19,
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
