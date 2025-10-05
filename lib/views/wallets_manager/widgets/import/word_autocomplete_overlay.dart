import 'package:flutter/material.dart';

class WordAutocompleteOverlay extends StatelessWidget {
  const WordAutocompleteOverlay({
    required this.suggestions,
    required this.onSuggestionSelected,
    super.key,
  });

  final List<String> suggestions;
  final void Function(String word) onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final word = suggestions[index];
          return InkWell(
            onTap: () => onSuggestionSelected(word),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: index < suggestions.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      )
                    : null,
              ),
              child: Text(word, style: theme.textTheme.bodyMedium),
            ),
          );
        },
      ),
    );
  }
}
