import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/views/wallets_manager/widgets/import/word_autocomplete_overlay.dart';

class WordInputField extends StatefulWidget {
  const WordInputField({
    required this.wordNumber,
    required this.controller,
    required this.mnemonicValidator,
    this.focusNode,
    this.nextFocusNode,
    this.onWordEntered,
    this.enabled = true,
    super.key,
  });

  final int wordNumber;
  final TextEditingController controller;
  final MnemonicValidator mnemonicValidator;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final void Function(String word)? onWordEntered;
  final bool enabled;

  @override
  State<WordInputField> createState() => _WordInputFieldState();
}

class _WordInputFieldState extends State<WordInputField> {
  List<String> _suggestions = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim().toLowerCase();

    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _isValid = false;
      });
      _removeOverlay();
      return;
    }

    // Get autocomplete matches
    final matches = widget.mnemonicValidator.getAutocompleteMatches(
      text,
      maxResults: 5,
    );

    setState(() {
      _suggestions = matches.toList();
      _isValid = matches.contains(text);
    });

    if (_suggestions.isNotEmpty && (widget.focusNode?.hasFocus ?? false)) {
      _showOverlay();
    } else {
      _removeOverlay();
    }

    // If exact match and valid, auto-advance to next field
    if (_isValid && widget.nextFocusNode != null) {
      widget.onWordEntered?.call(text);
      // Small delay for better UX
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.nextFocusNode?.requestFocus();
      });
    }
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus ?? false) {
      if (_suggestions.isNotEmpty) {
        _showOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            child: WordAutocompleteOverlay(
              suggestions: _suggestions,
              onSuggestionSelected: (word) {
                widget.controller.text = word;
                _removeOverlay();
                widget.onWordEntered?.call(word);
                widget.nextFocusNode?.requestFocus();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getFieldWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 200;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${widget.wordNumber}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: UiTextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              autocorrect: false,
              textInputAction: widget.nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-z]')),
                LengthLimitingTextInputFormatter(8),
              ],
              hintText: 'Word ${widget.wordNumber}',
              suffixIcon: _isValid
                  ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    )
                  : null,
              onFieldSubmitted: (value) {
                if (_isValid && widget.nextFocusNode != null) {
                  widget.nextFocusNode?.requestFocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
