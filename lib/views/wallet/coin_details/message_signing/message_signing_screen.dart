import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/bloc/message_signing/message_signing_event.dart';
import 'package:web_dex/bloc/message_signing/message_signing_state.dart';
import 'package:web_dex/bloc/message_signing/message_signing_bloc.dart';
import 'package:web_dex/views/wallet/coin_details/message_signing/Widgets/message_signing_confirmation.dart';
import 'package:web_dex/views/wallet/coin_details/message_signing/Widgets/message_signing_header.dart';
import 'package:web_dex/views/wallet/coin_details/message_signing/Widgets/message_signing_form.dart';
import 'package:web_dex/views/wallet/coin_details/message_signing/Widgets/message_signed_result.dart';

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
  late final Asset asset;

  @override
  void initState() {
    super.initState();
    final sdk = context.read<KomodoDefiSdk>();
    asset = widget.coin.toSdkAsset(sdk);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MessageSigningBloc(context.read<KomodoDefiSdk>())
        ..add(MessageSigningAddressesRequested(asset)),
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
  final TextEditingController messageController = TextEditingController();
  bool showConfirmation = false;
  bool understood = false;

  @override
  void initState() {
    super.initState();
  }

  void _handleSignMessage(BuildContext context) {
    final message = messageController.text.trim();
    final selected = context.read<MessageSigningBloc>().state.selected;

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.pleaseSelectAddress.tr())),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.pleaseEnterMessage.tr())),
      );
      return;
    }

    setState(() {
      showConfirmation = true;
      understood = false;
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        MessageSigningHeader(
          title: LocaleKeys.signMessage.tr(),
          onBackButtonPressed: widget.onBackButtonPressed,
        ),
        Expanded(
          child: Container(
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
            child: BlocBuilder<MessageSigningBloc, MessageSigningState>(
                builder: (context, state) {
              final theme = Theme.of(context);
              Widget content;

              if (state.signedMessage != null) {
                final selected = state.selected ??
                    (state.addresses.isNotEmpty ? state.addresses.first : null);

                content = selected != null
                    ? MessageSignedResult(
                        theme: theme,
                        selected: selected,
                        message: messageController.text,
                        signedMessage: state.signedMessage!,
                      )
                    : const SizedBox();
              } else if (showConfirmation) {
                content = MessageSigningConfirmationCard(
                  theme: theme,
                  message: messageController.text.trim(),
                  coinAbbr: widget.coin.abbr,
                  understood: understood,
                  onCancel: () {
                    setState(() {
                      showConfirmation = false;
                      understood = false;
                    });
                  },
                  onUnderstoodChanged: (val) {
                    setState(() => understood = val);
                  },
                );
              } else {
                content = MessageSigningForm(
                  state: state,
                  theme: theme,
                  coin: widget.coin,
                  asset: widget.asset,
                  messageController: messageController,
                  onSignPressed: () => _handleSignMessage(context),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}