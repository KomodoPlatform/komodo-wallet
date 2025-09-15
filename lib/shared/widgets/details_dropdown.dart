import 'package:flutter/material.dart';

class DetailsDropdown extends StatefulWidget {
  const DetailsDropdown({
    Key? key,
    required this.summary,
    required this.content,
  }) : super(key: key);

  final String summary;
  final Widget content;

  @override
  State<DetailsDropdown> createState() => _DetailsDropdownState();
}

class _DetailsDropdownState extends State<DetailsDropdown> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggle,
          child: Row(
            children: [
              Text(widget.summary),
              isOpen
                  ? const Icon(Icons.arrow_drop_up)
                  : const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (isOpen) ...[const SizedBox(height: 10), widget.content],
      ],
    );
  }

  void _toggle() {
    setState(() {
      isOpen = !isOpen;
    });
  }
}
