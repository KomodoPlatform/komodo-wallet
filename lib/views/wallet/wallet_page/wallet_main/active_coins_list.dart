import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/bloc/coins_bloc/asset_coin_extension.dart';
import 'package:web_dex/bloc/coins_bloc/coins_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_utils.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/coin_fiat_balance.dart';
import 'package:web_dex/views/wallet/coin_details/coin_details_info/coin_addresses.dart';
import 'package:web_dex/views/wallet/common/address_copy_button.dart';
import 'package:web_dex/views/wallet/common/address_icon.dart';
import 'package:web_dex/views/wallet/common/address_text.dart';
import 'package:web_dex/views/wallet/wallet_page/common/expandable_coin_list_item.dart';

class ActiveCoinsList extends StatelessWidget {
  const ActiveCoinsList({
    super.key,
    required this.searchPhrase,
    required this.withBalance,
    required this.onCoinItemTap,
  });

  final String searchPhrase;
  final bool withBalance;
  final Function(Coin) onCoinItemTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        final coins = state.walletCoins.values.toList();
        final Iterable<Coin> displayedCoins =
            _getDisplayedCoins(coins, context.sdk);

        if (displayedCoins.isEmpty &&
            (searchPhrase.isNotEmpty || withBalance)) {
          return SliverToBoxAdapter(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(LocaleKeys.walletPageNoSuchAsset.tr()),
            ),
          );
        }

        List<Coin> sorted =
            sortByPriorityAndBalance(displayedCoins.toList(), context.sdk);

        if (!context.read<SettingsBloc>().state.testCoinsEnabled) {
          sorted = removeTestCoins(sorted);
        }

        return SliverList.builder(
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final coin = sorted[index];

            // Fetch pubkeys if not already loaded
            if (!state.pubkeys.containsKey(coin.abbr)) {
              // TODO: Investigate if this is causing performance issues
              context.read<CoinsBloc>().add(CoinsPubkeysRequested(coin.abbr));
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ExpandableCoinListItem(
                // Changed from ExpandableCoinListItem
                key: Key('coin-list-item-${coin.abbr.toLowerCase()}'),
                coin: coin,
                pubkeys: state.pubkeys[coin.abbr],
                isSelected: false,
                onTap: () => onCoinItemTap(coin),
              ),
            );
          },
        );
      },
    );
  }

  Iterable<Coin> _getDisplayedCoins(Iterable<Coin> coins, KomodoDefiSdk sdk) =>
      filterCoinsByPhrase(coins, searchPhrase).where((Coin coin) {
        if (withBalance) {
          return (coin.lastKnownBalance(sdk)?.total ?? Decimal.zero) >
              Decimal.zero;
        }
        return true;
      }).toList();
}

class AddressBalanceList extends StatelessWidget {
  const AddressBalanceList({
    super.key,
    required this.coin,
    required this.onCreateNewAddress,
    required this.pubkeys,
    required this.cantCreateNewAddressReasons,
  });

  final Coin coin;
  final AssetPubkeys pubkeys;
  final VoidCallback onCreateNewAddress;
  final Set<CantCreateNewAddressReason>? cantCreateNewAddressReasons;

  bool get canCreateNewAddress => cantCreateNewAddressReasons?.isEmpty ?? true;

  @override
  Widget build(BuildContext context) {
    if (pubkeys.keys.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sort addresses by balance
    final sortedAddresses = [...pubkeys.keys]
      ..sort((a, b) => b.balance.spendable.compareTo(a.balance.spendable));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedAddresses.length,
          itemBuilder: (context, index) {
            final pubkey = sortedAddresses[index];
            return AddressBalanceCard(
              pubkey: pubkey,
              coin: coin,
            );
          },
        ),

        // Create address button
        if (canCreateNewAddress)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Tooltip(
              message: _getTooltipMessage(),
              child: ElevatedButton.icon(
                onPressed: canCreateNewAddress ? onCreateNewAddress : null,
                icon: const Icon(Icons.add),
                label: Text(LocaleKeys.createNewAddress.tr()),
              ),
            ),
          ),
      ],
    );
  }

  String _getTooltipMessage() {
    if (cantCreateNewAddressReasons?.isEmpty ?? true) {
      return '';
    }

    return cantCreateNewAddressReasons!.map((reason) {
      return switch (reason) {
        // TODO: Localise and possibly also move localisations to the SDK.
        CantCreateNewAddressReason.maxGapLimitReached =>
          'Maximum gap limit reached - please use existing unused addresses first',
        CantCreateNewAddressReason.maxAddressesReached =>
          'Maximum number of addresses reached for this asset',
        CantCreateNewAddressReason.missingDerivationPath =>
          'Missing derivation path configuration',
        CantCreateNewAddressReason.protocolNotSupported =>
          'Protocol does not support multiple addresses',
        CantCreateNewAddressReason.derivationModeNotSupported =>
          'Current wallet mode does not support multiple addresses',
        CantCreateNewAddressReason.noActiveWallet =>
          'No active wallet - please sign in first',
      };
    }).join('\n');
  }
}

class AddressBalanceCard extends StatelessWidget {
  const AddressBalanceCard({
    super.key,
    required this.pubkey,
    required this.coin,
  });

  final PubkeyInfo pubkey;
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address row
            Row(
              children: [
                AddressIcon(address: pubkey.address),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AddressText(address: pubkey.address),
                          AddressCopyButton(
                              address: pubkey.address, coinAbbr: coin.abbr),
                          if (pubkey.isActiveForSwap)
                            Chip(
                              label: Text(LocaleKeys.tradingAddress.tr()),
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                            ),
                        ],
                      ),
                      if (pubkey.derivationPath != null)
                        Text(
                          'Derivation: ${pubkey.derivationPath}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(),

            // Balance row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatBalance(pubkey.balance.spendable.toBigInt())} ${coin.abbr}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CoinFiatBalance(
                      coin.copyWith(),
                      style: Theme.of(context).textTheme.bodySmall,
                      // customBalance: pubkey.balance.spendable.toDouble(),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QrCode(
                                address: pubkey.address,
                                coinAbbr: coin.abbr,
                              ),
                              const SizedBox(height: 16),
                              SelectableText(pubkey.address),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatBalance(BigInt balance) {
    return doubleToString(balance.toDouble());
  }
}
