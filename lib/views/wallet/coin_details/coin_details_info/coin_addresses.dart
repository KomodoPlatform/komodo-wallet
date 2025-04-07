import 'package:app_theme/app_theme.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_bloc.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_event.dart';
import 'package:web_dex/bloc/coin_addresses/bloc/coin_addresses_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_type_tag.dart';
import 'package:web_dex/views/wallet/coin_details/coin_page_type.dart';
import 'package:web_dex/views/wallet/coin_details/faucet/faucet_button.dart';
import 'package:web_dex/views/wallet/common/address_copy_button.dart';
import 'package:web_dex/views/wallet/common/address_icon.dart';
import 'package:web_dex/views/wallet/common/address_text.dart';

class CoinAddresses extends StatefulWidget {
  const CoinAddresses({
    super.key,
    required this.coin,
    required this.setPageType,
  });

  final Coin coin;
  final void Function(CoinPageType) setPageType;

  @override
  State<CoinAddresses> createState() => _CoinAddressesState();
}

class _CoinAddressesState extends State<CoinAddresses> {
  late CoinAddressesBloc _coinAddressesBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely store a reference to the bloc
    _coinAddressesBloc = context.read<CoinAddressesBloc>();
  }

  @override
  void dispose() {
    // Use the stored reference instead of looking it up through context
    _coinAddressesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        return BlocBuilder<CoinAddressesBloc, CoinAddressesState>(
          builder: (context, state) {
            return SliverToBoxAdapter(
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    color: theme.custom.dexPageTheme.frontPlate,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            status: state.status,
                            createAddressStatus: state.createAddressStatus,
                            hideZeroBalance: state.hideZeroBalance,
                            cantCreateNewAddressReasons:
                                state.cantCreateNewAddressReasons,
                          ),
                          const SizedBox(height: 12),
                          ...state.addresses.asMap().entries.map(
                            (entry) {
                              final index = entry.key;
                              final address = entry.value;
                              if (state.hideZeroBalance &&
                                  address.balance.spendable == Decimal.zero) {
                                return const SizedBox();
                              }

                              return AddressCard(
                                address: address,
                                index: index,
                                coin: widget.coin,
                                setPageType: widget.setPageType,
                              );
                            },
                          ),
                          if (state.status == FormStatus.submitting)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (state.status == FormStatus.failure ||
                              state.createAddressStatus == FormStatus.failure)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(
                                child: Text(
                                  state.errorMessage ??
                                      LocaleKeys.somethingWrong.tr(),
                                  style: TextStyle(
                                    color:
                                        theme.currentGlobal.colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isMobile)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CreateButton(
                        status: state.status,
                        createAddressStatus: state.createAddressStatus,
                        cantCreateNewAddressReasons:
                            state.cantCreateNewAddressReasons,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.status,
    required this.createAddressStatus,
    required this.hideZeroBalance,
    required this.cantCreateNewAddressReasons,
  });

  final FormStatus status;
  final FormStatus createAddressStatus;
  final bool hideZeroBalance;
  final Set<CantCreateNewAddressReason>? cantCreateNewAddressReasons;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const AddressesTitle(),
        const Spacer(),
        HideZeroBalanceCheckbox(
          hideZeroBalance: hideZeroBalance,
        ),
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: SizedBox(
              width: 200,
              child: CreateButton(
                status: status,
                createAddressStatus: createAddressStatus,
                cantCreateNewAddressReasons: cantCreateNewAddressReasons,
              ),
            ),
          ),
      ],
    );
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.index,
    required this.coin,
    required this.setPageType,
  });

  final PubkeyInfo address;
  final int index;
  final Coin coin;
  final void Function(CoinPageType) setPageType;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: theme.custom.dexPageTheme.emptyPlace,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        leading: isMobile ? null : AddressIcon(address: address.address),
        title: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AddressIcon(address: address.address),
                      const SizedBox(width: 8),
                      AddressText(address: address.address),
                      const SizedBox(width: 8),
                      if (coin.hasFaucet)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 80,
                            maxWidth: isMobile ? 100 : 160,
                          ),
                          child: FaucetButton(
                            coinAbbr: coin.abbr,
                            address: address,
                          ),
                        ),
                      SwapAddressTag(address: address),
                      const Spacer(),
                      AddressCopyButton(address: address.address),
                      QrButton(
                        coin: coin,
                        address: address,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Balance(address: address, coin: coin),
                  const SizedBox(height: 4),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    AddressText(address: address.address),
                    const SizedBox(width: 8),
                    AddressCopyButton(address: address.address),
                    QrButton(coin: coin, address: address),
                    if (coin.hasFaucet)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 80,
                          maxWidth: isMobile ? 100 : 160,
                        ),
                        child: FaucetButton(
                          coinAbbr: coin.abbr,
                          address: address,
                        ),
                      ),
                    SwapAddressTag(address: address),
                  ],
                ),
              ),
        trailing: isMobile ? null : _Balance(address: address, coin: coin),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.address,
    required this.coin,
  });

  final PubkeyInfo address;
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${doubleToString(address.balance.total.toDouble())} '
      '${abbr2Ticker(coin.abbr)} (${address.balance.total.toDouble()})',
      style: TextStyle(fontSize: isMobile ? 12 : 14),
    );
  }
}

class QrButton extends StatelessWidget {
  const QrButton({
    super.key,
    required this.address,
    required this.coin,
  });

  final PubkeyInfo address;
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 18,
      icon: const Icon(Icons.qr_code, size: 16),
      color: Theme.of(context).textTheme.bodyMedium!.color,
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleKeys.receive.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocaleKeys.onlySendToThisAddress
                        .tr(args: [abbr2Ticker(coin.abbr)]),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          LocaleKeys.network.tr(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        CoinTypeTag(coin),
                      ],
                    ),
                  ),
                  QrCode(
                    address: address.address,
                    coinAbbr: coin.abbr,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.scanTheQrCode.tr(),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PubkeyReceiveDialog extends StatelessWidget {
  const PubkeyReceiveDialog({
    super.key,
    required this.coin,
    required this.address,
  });

  final Coin coin;
  final PubkeyInfo address;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LocaleKeys.receive.tr(),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleKeys.onlySendToThisAddress
                  .tr(args: [abbr2Ticker(coin.abbr)]),
              style: const TextStyle(fontSize: 14),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.network.tr(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  CoinTypeTag(coin),
                ],
              ),
            ),
            QrCode(
              address: address.address,
              coinAbbr: coin.abbr,
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.scanTheQrCode.tr(),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class SwapAddressTag extends StatelessWidget {
  const SwapAddressTag({
    super.key,
    required this.address,
  });

  final PubkeyInfo address;

  @override
  Widget build(BuildContext context) {
    return address.isActiveForSwap
        ? Padding(
            padding: EdgeInsets.only(left: isMobile ? 4 : 8),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 8,
                horizontal: isMobile ? 8 : 12.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                LocaleKeys.swapAddress.tr(),
                style: TextStyle(fontSize: isMobile ? 9 : 12),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}

class AddressesTitle extends StatelessWidget {
  const AddressesTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.addresses.tr(),
      style:
          TextStyle(fontSize: isMobile ? 14 : 24, fontWeight: FontWeight.bold),
    );
  }
}

class HideZeroBalanceCheckbox extends StatelessWidget {
  final bool hideZeroBalance;

  const HideZeroBalanceCheckbox({
    super.key,
    required this.hideZeroBalance,
  });

  @override
  Widget build(BuildContext context) {
    return UiCheckbox(
      key: const Key('addresses-with-balance-checkbox'),
      text: LocaleKeys.hideZeroBalanceAddresses.tr(),
      value: hideZeroBalance,
      onChanged: (value) {
        context
            .read<CoinAddressesBloc>()
            .add(UpdateHideZeroBalanceEvent(value));
      },
    );
  }
}

class CreateButton extends StatelessWidget {
  const CreateButton({
    super.key,
    required this.status,
    required this.createAddressStatus,
    required this.cantCreateNewAddressReasons,
  });

  final FormStatus status;
  final FormStatus createAddressStatus;
  final Set<CantCreateNewAddressReason>? cantCreateNewAddressReasons;

  @override
  Widget build(BuildContext context) {
    final tooltipMessage = _getTooltipMessage();

    return Tooltip(
      message: tooltipMessage,
      child: UiPrimaryButton(
        height: 40,
        borderRadius: 20,
        backgroundColor: isMobile ? theme.custom.dexPageTheme.emptyPlace : null,
        text: createAddressStatus == FormStatus.submitting
            ? '${LocaleKeys.creating.tr()}...'
            : LocaleKeys.createAddress.tr(),
        prefix: createAddressStatus == FormStatus.submitting
            ? null
            : const Icon(Icons.add, size: 16),
        onPressed: canCreateNewAddress &&
                status != FormStatus.submitting &&
                createAddressStatus != FormStatus.submitting
            ? () {
                context
                    .read<CoinAddressesBloc>()
                    .add(const SubmitCreateAddressEvent());
              }
            : null,
      ),
    );
  }

  bool get canCreateNewAddress => cantCreateNewAddressReasons?.isEmpty ?? true;

  String _getTooltipMessage() {
    if (cantCreateNewAddressReasons?.isEmpty ?? true) {
      return '';
    }

    return cantCreateNewAddressReasons!.map((reason) {
      return switch (reason) {
        CantCreateNewAddressReason.maxGapLimitReached =>
          LocaleKeys.maxGapLimitReached.tr(),
        CantCreateNewAddressReason.maxAddressesReached =>
          LocaleKeys.maxAddressesReached.tr(),
        CantCreateNewAddressReason.missingDerivationPath =>
          LocaleKeys.missingDerivationPath.tr(),
        CantCreateNewAddressReason.protocolNotSupported =>
          LocaleKeys.protocolNotSupported.tr(),
        CantCreateNewAddressReason.derivationModeNotSupported =>
          LocaleKeys.derivationModeNotSupported.tr(),
        CantCreateNewAddressReason.noActiveWallet =>
          LocaleKeys.noActiveWallet.tr(),
      };
    }).join('\n');
  }
}

class QrCode extends StatelessWidget {
  final String address;
  final String coinAbbr;

  const QrCode({
    super.key,
    required this.address,
    required this.coinAbbr,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: QrImageView(
            data: address,
            backgroundColor: Theme.of(context).textTheme.bodyMedium!.color!,
            foregroundColor: theme.custom.dexPageTheme.emptyPlace,
            version: QrVersions.auto,
            size: 200.0,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
        ),
        Positioned(
          child: CoinIcon(coinAbbr, size: 40),
        ),
      ],
    );
  }
}
