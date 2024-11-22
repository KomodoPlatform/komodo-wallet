import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_bloc.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_event.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/coin_type.dart';
import 'package:web_dex/model/coin_utils.dart';

class CustomTokenImportDialog extends StatefulWidget {
  const CustomTokenImportDialog({Key? key}) : super(key: key);

  @override
  CustomTokenImportDialogState createState() => CustomTokenImportDialogState();
}

class CustomTokenImportDialogState extends State<CustomTokenImportDialog> {
  final PageController _pageController = PageController();

  Future<void> navigateToPage(int pageIndex) async {
    return _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  Future<void> goToNextPage() async {
    if (_pageController.page == null) return;

    await navigateToPage(_pageController.page!.toInt() + 1);
  }

  Future<void> goToPreviousPage() async {
    if (_pageController.page == null) return;

    await navigateToPage(_pageController.page!.toInt() - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 450,
        height: 450,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ImportFormPage(
              onNextPage: goToNextPage,
            ),
            ImportSubmitPage(
              onPreviousPage: goToPreviousPage,
            ),
          ],
        ),
      ),
    );
  }
}

class BasePage extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBackPressed;

  const BasePage({
    required this.title,
    required this.child,
    this.onBackPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBackPressed != null)
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onBackPressed,
                  iconSize: 36,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              if (onBackPressed != null) const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ImportFormPage extends StatelessWidget {
  final VoidCallback onNextPage;

  const ImportFormPage({required this.onNextPage, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.read<CustomTokenImportBloc>().state;
    final addressController = TextEditingController(text: state.address ?? '');

    return BlocListener<CustomTokenImportBloc, CustomTokenImportState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success ||
            state.formStatus == FormStatus.failure) {
          onNextPage();
        }
      },
      child: BlocBuilder<CustomTokenImportBloc, CustomTokenImportState>(
        builder: (context, state) {
          final initialState = state.formStatus == FormStatus.initial;

          final isSubmitEnabled = initialState &&
              state.network != null &&
              state.address != null &&
              state.address!.isNotEmpty;

          return BasePage(
            title: LocaleKeys.importCustomToken.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade300.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade300),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleKeys.importTokenWarning.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<CoinType>(
                  value: state.network,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.selectNetwork.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: CoinType.values
                      .where((CoinType coinType) =>
                          getEvmPlatformCoin(coinType) != null)
                      .map((CoinType coinType) {
                    return DropdownMenuItem<CoinType>(
                      value: coinType,
                      child: Text(getCoinTypeNameLong(coinType)),
                    );
                  }).toList(),
                  onChanged: !initialState
                      ? null
                      : (CoinType? value) {
                          if (value != null) {
                            context
                                .read<CustomTokenImportBloc>()
                                .add(UpdateNetworkEvent(value));
                          }
                        },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: addressController,
                  enabled: initialState,
                  onChanged: (value) {
                    context
                        .read<CustomTokenImportBloc>()
                        .add(UpdateAddressEvent(value));
                  },
                  decoration: InputDecoration(
                    labelText: LocaleKeys.tokenContractAddress.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const Spacer(),
                UiPrimaryButton(
                  onPressed: isSubmitEnabled
                      ? () {
                          context
                              .read<CustomTokenImportBloc>()
                              .add(const SubmitFetchCustomTokenEvent());
                        }
                      : null,
                  child: state.formStatus == FormStatus.initial
                      ? Text(LocaleKeys.importToken.tr())
                      : const UiSpinner(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ImportSubmitPage extends StatelessWidget {
  final VoidCallback onPreviousPage;

  const ImportSubmitPage({required this.onPreviousPage, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomTokenImportBloc, CustomTokenImportState>(
      listenWhen: (previous, current) =>
          previous.importStatus != current.importStatus,
      listener: (context, state) {
        if (state.importStatus == FormStatus.success) {
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<CustomTokenImportBloc, CustomTokenImportState>(
        builder: (context, state) {
          final isSubmitEnabled = state.importStatus != FormStatus.submitting &&
              state.importStatus != FormStatus.success &&
              state.coin != null;

          final newCoin = state.coin;

          return BasePage(
            title: LocaleKeys.importCustomToken.tr(),
            onBackPressed: () {
              context
                  .read<CustomTokenImportBloc>()
                  .add(const ResetFormStatusEvent());
              onPreviousPage();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: state.coin == null
                  ? [
                      Expanded(
                        child: Column(
                          children: [
                            Image.asset(
                              '$assetsPath/logo/not_found.png',
                              height: 300,
                              filterQuality: FilterQuality.high,
                            ),
                            Text(
                              LocaleKeys.tokenNotFound.tr(),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (newCoin?.logoImage != null)
                              Image(
                                image: newCoin!.logoImage!,
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, size: 80);
                                },
                              ),
                            const SizedBox(height: 12),
                            Text(
                              newCoin!.abbr,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              LocaleKeys.balance.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${newCoin.balance} ${newCoin.abbr} (${newCoin.getFormattedUsdBalance})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      if (state.importErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            state.importErrorMessage ?? '',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      UiPrimaryButton(
                        onPressed: isSubmitEnabled
                            ? () {
                                context
                                    .read<CustomTokenImportBloc>()
                                    .add(const SubmitImportCustomTokenEvent());
                              }
                            : null,
                        child: state.importStatus == FormStatus.submitting ||
                                state.importStatus == FormStatus.success
                            ? const UiSpinner(color: Colors.white)
                            : Text(LocaleKeys.importToken.tr()),
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }
}
