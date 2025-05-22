import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui/komodo_ui.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart';

class MessageSigningScreen extends StatefulWidget {
  final Coin coin;
  final VoidCallback? onBackButtonPressed;

  const MessageSigningScreen({
    super.key,
    required this.coin,
    this.onBackButtonPressed,
  });

  @override
  State<MessageSigningScreen> createState() => _MessageSigningScreenState();
}

class _MessageSigningScreenState extends State<MessageSigningScreen> {
  late Asset asset;

  @override
  void initState() {
    super.initState();
    asset = widget.coin.toSdkAsset(context.sdk);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CoinAddressesBloc(
        context.sdk,
        widget.coin.abbr,
      )..add(const LoadAddressesEvent()),
      child: _MessageSigningScreenContent(
        coin: widget.coin,
        asset: asset,
        onBackButtonPressed: widget.onBackButtonPressed,
      ),
    );
  }
}

class _MessageSigningScreenContent extends StatefulWidget {
  final Coin coin;
  final Asset asset;
  final VoidCallback? onBackButtonPressed;

  const _MessageSigningScreenContent({
    required this.coin,
    required this.asset,
    this.onBackButtonPressed,
  });

  @override
  State<_MessageSigningScreenContent> createState() =>
      _MessageSigningScreenContentState();
}

class _MessageSigningScreenContentState
    extends State<_MessageSigningScreenContent> {
  PubkeyInfo? selectedAddress;
  final TextEditingController messageController = TextEditingController();
  String? signedMessage;
  String? errorMessage;
  bool isLoading = false;
  bool isLoadingAddresses = true;
  AssetPubkeys? pubkeys;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoadingAddresses = true;
    });

    try {
      final addresses = await context.sdk.pubkeys.getPubkeys(widget.asset);

      setState(() {
        pubkeys = addresses;
        isLoadingAddresses = false;
        if (addresses.keys.isNotEmpty) {
          selectedAddress = addresses.keys.first;
        }
      });
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
        errorMessage =
            LocaleKeys.failedToLoadAddresses.tr(args: [e.toString()]);
      });
    }
  }

  Future<void> _signMessage() async {
    if (selectedAddress == null) {
      setState(() {
        errorMessage = LocaleKeys.pleaseSelectAddress.tr();
      });
      return;
    }

    if (messageController.text.isEmpty) {
      setState(() {
        errorMessage = LocaleKeys.pleaseEnterMessage.tr();
      });
      return;
    }

    setState(() {
      isLoading = true;
      signedMessage = null;
      errorMessage = null;
    });

    try {
      final signResult = await context.sdk.messageSigning.signMessage(
        coin: widget.coin.abbr,
        address: selectedAddress!.address,
        message: messageController.text,
      );

      setState(() {
        signedMessage = signResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = LocaleKeys.failedToSignMessage.tr(args: [e.toString()]);
        isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.clipBoard.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectEnabled = pubkeys != null && pubkeys!.keys.length > 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              color: theme.colorScheme.surface.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signing Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage != null && !isLoadingAddresses)
                      ErrorMessageWidget(errorMessage: errorMessage!)
                    else
                      AddressSelectInput(
                        addresses: pubkeys?.keys ?? [],
                        selectedAddress: selectedAddress,
                        onAddressSelected: !isSelectEnabled
                            ? null
                            : (address) {
                                setState(() {
                                  selectedAddress = address;
                                  signedMessage = null;
                                  errorMessage = null;
                                });
                              },
                        assetName: widget.asset.id.name,
                      ),
                    const SizedBox(height: 20),
                    Text(
                      LocaleKeys.messageToSign.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    EnhancedMessageInput(
                      controller: messageController,
                      hintText: LocaleKeys.enterMessage.tr(),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: UiPrimaryButton(
                        text: LocaleKeys.signMessageButton.tr(),
                        onPressed: isLoading ? null : _signMessage,
                        width: double.infinity,
                        height: 56,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (signedMessage != null) ...[
              const SizedBox(height: 24),
              EnhancedSignedMessageCard(
                selectedAddress: selectedAddress!,
                message: messageController.text,
                signedMessage: signedMessage!,
                onCopyToClipboard: _copyToClipboard,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Enhanced Signed Message Card
class EnhancedSignedMessageCard extends StatelessWidget {
  final PubkeyInfo selectedAddress;
  final String message;
  final String signedMessage;
  final Function(String) onCopyToClipboard;

  const EnhancedSignedMessageCard({
    super.key,
    required this.selectedAddress,
    required this.message,
    required this.signedMessage,
    required this.onCopyToClipboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildSectionHeader(context, LocaleKeys.address.tr()),
              _buildContentSection(
                context,
                selectedAddress.address,
                icon: Icons.account_balance_wallet,
                onCopy: () => onCopyToClipboard(selectedAddress.address),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, LocaleKeys.message.tr()),
              _buildContentSection(
                context,
                message,
                icon: Icons.chat_bubble_outline,
                onCopy: () => onCopyToClipboard(message),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, LocaleKeys.signedMessage.tr()),
              _buildContentSection(
                context,
                signedMessage,
                icon: Icons.vpn_key_outlined,
                onCopy: () => onCopyToClipboard(signedMessage),
                isSignature: true,
              ),
              const SizedBox(height: 24),
              _buildCopyAllButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    String content, {
    required IconData icon,
    required VoidCallback onCopy,
    bool isSignature = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withOpacity(0.7),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CopyableTextField(
        content: content,
        onCopy: onCopy,
        icon: icon,
        isSignature: isSignature,
      ),
    );
  }

  Widget _buildCopyAllButton(BuildContext context) {
    return UiPrimaryButton.flexible(
      child: Text(LocaleKeys.copyAllDetails.tr()),
      onPressed: () => onCopyToClipboard(
        'Address:\n${selectedAddress.address}\n\n'
        'Message:\n$message\n\n'
        'Signature:\n$signedMessage',
      ),
    );
  }
}

// Copyable Text Field Component
class CopyableTextField extends StatefulWidget {
  final String content;
  final VoidCallback onCopy;
  final IconData icon;
  final bool isSignature;

  const CopyableTextField({
    super.key,
    required this.content,
    required this.onCopy,
    required this.icon,
    this.isSignature = false,
  });

  @override
  State<CopyableTextField> createState() => _CopyableTextFieldState();
}

class _CopyableTextFieldState extends State<CopyableTextField>
    with SingleTickerProviderStateMixin {
  bool _isCopied = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyWithAnimation() {
    widget.onCopy();
    setState(() {
      _isCopied = true;
    });
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _copyWithAnimation,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    widget.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      letterSpacing: widget.isSignature ? 0 : 0.5,
                      fontFamily: widget.isSignature ? 'monospace' : null,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _isCopied ? _fadeAnimation.value : 1.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _isCopied
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        _isCopied ? Icons.check : Icons.copy,
                        size: 16,
                        color: _isCopied
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Error Message Widget
class ErrorMessageWidget extends StatelessWidget {
  final String errorMessage;

  const ErrorMessageWidget({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        errorMessage,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}

// Enhanced Address Selection Widget

// Enhanced Message Input Widget
class EnhancedMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;

  const EnhancedMessageInput({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  State<EnhancedMessageInput> createState() => _EnhancedMessageInputState();
}

class _EnhancedMessageInputState extends State<EnhancedMessageInput> {
  late int charCount = 0;

  @override
  void initState() {
    super.initState();
    charCount = widget.controller.text.length;
    widget.controller.addListener(_updateCharCount);
  }

  void _updateCharCount() {
    setState(() {
      charCount = widget.controller.text.length;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharCount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              filled: true,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              letterSpacing: 0.5,
              height: 1.5,
            ),
            maxLines: 4,
            cursorColor: theme.colorScheme.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$charCount characters',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
