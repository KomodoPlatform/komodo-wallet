import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/widgets/disclaimer/constants.dart';
import 'package:web_dex/shared/widgets/disclaimer/tos_content.dart';

class Eula extends StatefulWidget {
  const Eula({Key? key, required this.onClose}) : super(key: key);
  final Function() onClose;

  @override
  State<Eula> createState() => _EulaState();
}

class _EulaState extends State<Eula> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final List<TextSpan> disclaimerToSText = <TextSpan>[
      TextSpan(
          text: disclaimerEulaTitle1,
          style: Theme.of(context).textTheme.titleLarge),
      TextSpan(
          text: disclaimerEulaParagraph1,
          style: Theme.of(context).textTheme.bodyMedium),
    ];

    return Column(
      children: <Widget>[
        SizedBox(
            height: MediaQuery.of(context).size.height * 2 / 3,
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: TosContent(disclaimerToSText: disclaimerToSText),
            )),
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
