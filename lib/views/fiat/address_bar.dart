import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/formatters.dart';
import 'package:web_dex/shared/utils/utils.dart';

class AddressBar extends StatelessWidget {
  const AddressBar({
    required this.receiveAddress,
    super.key,
  });

  final String? receiveAddress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onTap: () => copyToClipBoard(context, receiveAddress!),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (receiveAddress != null && receiveAddress!.isNotEmpty)
                  const Icon(Icons.copy, size: 16)
                else
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    truncateMiddleSymbols(receiveAddress ?? ''),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
