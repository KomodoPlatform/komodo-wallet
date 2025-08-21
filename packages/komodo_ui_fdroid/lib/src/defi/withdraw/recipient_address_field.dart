import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/src/input/qr_code_scanner.dart';
import 'package:komodo_ui/src/utils/debouncer.dart';

/// A form field widget for entering and validating cryptocurrency recipient addresses.
///
/// This widget provides a rich interface for entering cryptocurrency addresses with
/// the following features:
///
/// * Address validation with error messages
/// * QR code scanning capability
/// * Clipboard paste functionality
/// * Address format preview
/// * Network identification
///
/// The widget maintains its own state and provides real-time feedback about the
/// validity of the entered address. It shows a loading indicator while validation
/// is in progress and provides clear error messages when validation fails.
///
/// The field supports both manual text input and automated input methods:
/// * Manual text entry with validation
/// * QR code scanning through device camera
/// * Paste from clipboard functionality
///
/// Example usage:
/// ```dart
/// RecipientAddressField(
///   address: currentAddress,
///   onChanged: (newAddress) {
///     // Handle address changes
///   },
///   validation: AddressValidation(
///     isValid: true,
///     invalidReason: null,
///   ),
///   asset: selectedAsset,
///   onQrScanned: (scannedAddress) {
///     // Handle QR code scan result
///   },
/// )
/// ```
///
/// The widget's appearance adapts to the current [Theme] and supports both light
/// and dark modes. It uses the theme's color scheme for visual feedback about
/// the address validity state.
///
/// See also:
///
///  * [QrCodeReaderOverlay], which provides the QR code scanning functionality
///  * [AddressValidation], which defines the structure for address validation
///  * [Asset], which provides information about the cryptocurrency being transferred
class RecipientAddressField extends StatefulWidget {
  /// Creates a form field for entering and validating cryptocurrency recipient addresses.
  ///
  /// The [address] parameter represents the current address value.
  ///
  /// The [onChanged] callback is called whenever the address value changes.
  ///
  /// If [onQrScanned] is provided, a QR code scanner button will be shown that allows
  /// scanning addresses using the device camera.
  ///
  /// The [validation] parameter provides validation state for the current address.
  ///
  /// When [isValidating] is true, a loading indicator is shown to indicate that
  /// address validation is in progress.
  ///
  /// The [errorText] callback can be used to provide custom error messages that
  /// override the default validation messages.
  ///
  /// If [asset] is provided, the widget will show the network information for the
  /// cryptocurrency being transferred.
  const RecipientAddressField({
    required this.address,
    required this.onChanged,
    this.onQrScanned,
    this.validation,
    this.isValidating = false,
    this.errorText,
    this.asset,
    super.key,
  });

  /// The current recipient address value.
  ///
  /// This value will be displayed in the text field and used as the initial value
  /// when the widget is first built.
  final String address;

  /// Called when the user changes the address value.
  ///
  /// This callback is debounced to prevent excessive validation calls when the
  /// user is actively typing. The debounce duration is 500ms by default.
  ///
  /// This callback should handle any necessary address validation and state updates
  /// in the parent widget.
  final ValueChanged<String> onChanged;

  /// Called when a QR code is successfully scanned.
  ///
  /// If this callback is provided, a QR code scanner button will be shown that
  /// allows the user to scan addresses using the device camera. The scanned
  /// address will be automatically populated in the text field and this callback
  /// will be invoked with the scanned value.
  ///
  /// If null, the QR code scanner button will not be shown.
  final ValueChanged<String>? onQrScanned;

  /// The current validation state of the address.
  ///
  /// This object contains information about whether the address is valid and
  /// any error message that should be displayed if it's invalid.
  ///
  /// If null, no validation state will be shown.
  final AddressValidation? validation;

  /// Whether the address is currently being validated.
  ///
  /// When true, a loading indicator will be shown to indicate that validation
  /// is in progress. This is useful when validation requires asynchronous
  /// operations like network calls.
  final bool isValidating;

  /// Optional callback to provide custom error text.
  ///
  /// If provided, this callback will be called to get error text that overrides
  /// the default validation messages. This is useful for providing context-specific
  /// error messages.
  ///
  /// If this callback returns null, the default validation message will be used.
  final String? Function()? errorText;

  /// The cryptocurrency asset associated with this address field.
  ///
  /// If provided, the widget will display network information for the asset,
  /// helping users verify they're using the correct network for the transfer.
  ///
  /// If null, no network information will be displayed.
  final Asset? asset;

  @override
  State<RecipientAddressField> createState() => _RecipientAddressFieldState();
}

/// The state for the [RecipientAddressField] widget.
///
/// This state class manages:
/// * Text input control and focus management
/// * Paste button visibility
/// * Debounced validation callbacks
/// * QR code scanning integration
/// * Address preview formatting
///
/// The state maintains the text controller, focus node, and a debouncer for validation
/// to ensure smooth user interaction and prevent excessive validation calls.
class _RecipientAddressFieldState extends State<RecipientAddressField> {
  /// Controller for the address text input field.
  /// Initialized with [RecipientAddressField.address].
  late final TextEditingController _controller;

  /// Focus node for managing the text field's focus state.
  final FocusNode _focusNode = FocusNode();

  /// Debounces validation calls to prevent excessive API requests.
  /// Uses a 500ms delay by default.
  final _validationDebouncer = Debouncer();

  /// Whether the text field currently has focus.
  bool _hasFocus = false;

  /// Whether to show the paste button.
  /// True when the field is empty, false when it contains text.
  bool _showPasteButton = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.address);
    _focusNode.addListener(_onFocusChange);

    // Update paste button visibility based on initial text
    _showPasteButton = widget.address.isEmpty;
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(RecipientAddressField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.address != _controller.text) {
      _controller.text = widget.address;
      _showPasteButton = widget.address.isEmpty;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      _controller.text = clipboardData.text!;
      widget.onChanged(clipboardData.text!);
      setState(() {
        _showPasteButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = widget.validation?.isValid ?? false;
    final hasText = _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recipient Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.asset != null)
              Text(
                'Network: ${widget.asset!.id.chainId.formattedChainId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Enter recipient address or scan QR code',
            filled: true,
            fillColor:
                _hasFocus
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surface.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getStatusColor(theme)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getStatusColor(theme)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(width: 2, color: _getStatusColor(theme)),
            ),
            prefixIcon:
                hasText && isValid
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : null,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showPasteButton)
                  TextButton(
                    onPressed: _pasteFromClipboard,
                    child: const Text('Paste'),
                  )
                else if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                      setState(() {
                        _showPasteButton = true;
                      });
                    },
                    tooltip: 'Clear',
                  ),
                const SizedBox(width: 4),
                if (widget.onQrScanned != null)
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanQrCode,
                    tooltip: 'Scan QR code',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                _buildStatusIndicator(),
              ],
            ),
            errorText: _getErrorText(),
          ),
          onChanged: (value) {
            // Update UI state immediately
            setState(() {
              _showPasteButton = value.isEmpty;
            });

            // Debounce the validation callback
            _validationDebouncer.run(() {
              if (mounted) {
                widget.onChanged(value);
              }
            });
          },
          style: theme.textTheme.bodyLarge,
        ),
        if (_shouldShowValidationMessage()) ...[
          const SizedBox(height: 8),
          _buildValidationMessage(),
        ],
        if (hasText && isValid) ...[
          const SizedBox(height: 8),
          _buildAddressPreview(),
        ],
      ],
    );
  }

  /// Determines the color to use for the input field border based on the current state.
  ///
  /// The color reflects different states of the input:
  /// * Primary color when validating or valid
  /// * Error color when invalid
  /// * Outline color when empty
  ///
  /// This provides visual feedback about the validation state of the address.
  Color _getStatusColor(ThemeData theme) {
    if (widget.isValidating) return theme.colorScheme.primary;
    if (_controller.text.isEmpty) return theme.colorScheme.outline;
    if (widget.errorText?.call() != null) return theme.colorScheme.error;
    if (widget.validation != null) {
      return widget.validation!.isValid
          ? theme.colorScheme.primary
          : theme.colorScheme.error;
    }
    return theme.colorScheme.outline;
  }

  /// Determines whether to show the validation error message.
  ///
  /// The validation message is shown when all of these conditions are met:
  /// * The input field is not empty
  /// * A validation result is available
  /// * The validation result indicates the address is invalid
  /// * There is a non-empty error message to display
  ///
  /// This prevents showing unnecessary error messages while the user is typing
  /// or when there's no meaningful error to display.
  bool _shouldShowValidationMessage() {
    if (_controller.text.isEmpty || widget.validation == null) return false;
    return !widget.validation!.isValid &&
        widget.validation!.invalidReason?.isNotEmpty == true;
  }

  /// Builds the status indicator widget that shows the current validation state.
  ///
  /// When [widget.isValidating] is true, displays a small circular progress
  /// indicator to show that address validation is in progress. Otherwise,
  /// returns a spacer to maintain consistent layout.
  ///
  /// The progress indicator uses the theme's primary color and is sized
  /// appropriately for the input field's suffix area.
  Widget _buildStatusIndicator() {
    final theme = Theme.of(context);

    if (widget.isValidating) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return const SizedBox(width: 4);
  }

  /// Determines the error text to display below the input field.
  ///
  /// The error text is determined in the following order:
  /// 1. Returns null if the input is empty (no error shown)
  /// 2. Uses custom error text if provided through [widget.errorText]
  /// 3. Uses validation error message if address is invalid
  /// 4. Returns null if address is valid
  ///
  /// This prioritizes custom error messages over default validation messages,
  /// allowing for context-specific error handling while maintaining a consistent
  /// fallback for standard validation errors.
  String? _getErrorText() {
    if (_controller.text.isEmpty) {
      return null;
    }

    // Check for error override first
    final errorOverride = widget.errorText?.call();
    if (errorOverride != null) {
      return errorOverride;
    }

    // Show validation error if address is invalid
    if (widget.validation != null &&
        !widget.validation!.isValid &&
        _controller.text.isNotEmpty) {
      return widget.validation!.invalidReason ?? 'Invalid address format';
    }

    return null;
  }

  /// Builds a validation error message container that appears below the input field.
  ///
  /// Creates a visually distinct error message container with:
  /// * Warning icon for clear error indication
  /// * Error message text from the validation result
  /// * Error-themed background and text colors
  /// * Rounded corners and padding for visual separation
  ///
  /// The message uses the theme's error container colors for consistent
  /// error presentation across the application.
  Widget _buildValidationMessage() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.validation!.invalidReason!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a preview widget that displays a validated address in a user-friendly format.
  ///
  /// For improved readability, long addresses are truncated to show only the first
  /// and last 8 characters with an ellipsis in between. Short addresses (16 characters
  /// or less) are shown in full.
  ///
  /// The preview includes:
  /// * A checkmark icon indicating the address is valid
  /// * The truncated address with a "Valid address:" prefix
  /// * A copy button that copies the full address to the clipboard
  ///
  /// When the copy button is pressed, a snackbar appears to confirm the copy action.
  ///
  /// The preview uses the theme's primary container colors to visually distinguish
  /// it from error states and provide a consistent success indication.
  Widget _buildAddressPreview() {
    final theme = Theme.of(context);

    // Display only the start and end of the address for clarity
    final address = _controller.text;
    final previewAddress =
        address.length > 16
            ? '${address.substring(0, 8)}...${address.substring(address.length - 8)}'
            : address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Valid address: $previewAddress',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied to clipboard')),
              );
            },
            tooltip: 'Copy address',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _scanQrCode() async {
    final scannedAddress = await QrCodeReaderOverlay.show(context);

    if (mounted && scannedAddress != null) {
      // Update the text field with the scanned address
      _controller.text = scannedAddress;
      widget.onQrScanned?.call(scannedAddress);
      widget.onChanged(scannedAddress);
      setState(() {
        _showPasteButton = false;
      });
    }
  }
}
