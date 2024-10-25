import 'package:app_theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_bloc.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_event.dart';
import 'package:web_dex/bloc/custom_token_import/bloc/custom_token_import_state.dart';
import 'package:web_dex/blocs/blocs.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

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
        width: 400,
        height: 500,
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
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed,
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              if (onBackPressed != null) const SizedBox(width: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
    // Initializing controllers with initial values from the BLoC state
    final state = context.read<CustomTokenImportBloc>().state;
    final networkController =
        TextEditingController(text: state.network?.abbr ?? '');
    final addressController = TextEditingController(text: state.address ?? '');
    final decimalsController = TextEditingController(
      text: state.decimals?.toString() ?? '',
    );

    return BlocListener<CustomTokenImportBloc, CustomTokenImportState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus &&
          current.formStatus == FormStatus.success,
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          onNextPage();
        }
      },
      child: BlocBuilder<CustomTokenImportBloc, CustomTokenImportState>(
        builder: (context, state) {
          final isSubmitEnabled = state.formStatus != FormStatus.submitting &&
              state.network != null &&
              state.address != null &&
              state.address!.isNotEmpty &&
              state.decimals != null;

          final flowCompleted = state.formStatus == FormStatus.success;

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
                      Icon(Icons.info, color: Colors.orange.shade300),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleKeys.importTokenWarning.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: networkController,
                  enabled: !flowCompleted,
                  onChanged: (value) {
                    final coin = coinsBloc.getCoin(value);
                    context
                        .read<CustomTokenImportBloc>()
                        .add(UpdateNetworkEvent(coin));
                  },
                  decoration: InputDecoration(
                    labelText: LocaleKeys.selectNetwork.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: addressController,
                  enabled: !flowCompleted,
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
                const SizedBox(height: 24),

                // Decimals Field
                TextFormField(
                  controller: decimalsController,
                  enabled: !flowCompleted,
                  onChanged: (value) {
                    context
                        .read<CustomTokenImportBloc>()
                        .add(UpdateDecimalsEvent(int.tryParse(value)));
                  },
                  decoration: InputDecoration(
                    labelText: LocaleKeys.decimals.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    (flowCompleted ? state.address : state.formErrorMessage) ??
                        '',
                    textAlign:
                        flowCompleted ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      color: flowCompleted
                          ? theme.custom.increaseColor
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                UiPrimaryButton(
                  onPressed: isSubmitEnabled
                      ? () {
                          context
                              .read<CustomTokenImportBloc>()
                              .add(const SubmitFetchCustomTokenEvent());
                        }
                      : null,
                  child:
                      state.formStatus == FormStatus.submitting || flowCompleted
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

class ImportSubmitPage extends StatelessWidget {
  final VoidCallback onPreviousPage;

  const ImportSubmitPage({required this.onPreviousPage, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomTokenImportBloc, CustomTokenImportState>(
      builder: (context, state) {
        final isSubmitEnabled = state.importStatus != FormStatus.submitting &&
            state.tokenData != null;

        final flowCompleted = state.importStatus == FormStatus.success;

        final usdBalance = state.tokenData?['usd_balance'] != null
            ? '\$${double.parse(state.tokenData!['usd_balance'].toString()).toStringAsFixed(2)} USD'
            : null;

        return BasePage(
          title: LocaleKeys.importToken.tr(),
          onBackPressed: () {
            context
                .read<CustomTokenImportBloc>()
                .add(const ResetFormStatusEvent());
            onPreviousPage();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.tokenData?['image_url'] != null)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset(
                          state.tokenData!['image_url'],
                          width: 48,
                          height: 48,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      state.tokenData?['abbr'] ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Balance',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.tokenData?['balance'] ?? '0'} ${state.tokenData?['abbr'] ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    if (usdBalance != null)
                      Text(
                        usdBalance,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                  ],
                ),
              ),
              if (state.importErrorMessage != null || flowCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    (flowCompleted
                            ? state.address
                            : state.importErrorMessage) ??
                        '',
                    textAlign:
                        flowCompleted ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      color: flowCompleted
                          ? theme.custom.increaseColor
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              UiPrimaryButton(
                onPressed: isSubmitEnabled
                    ? () {
                        if (flowCompleted) {
                          Navigator.of(context).pop();
                        } else {
                          context
                              .read<CustomTokenImportBloc>()
                              .add(const SubmitImportCustomTokenEvent());
                        }
                      }
                    : null,
                child: flowCompleted
                    ? Text(LocaleKeys.close.tr())
                    : state.importStatus == FormStatus.submitting
                        ? const UiSpinner(color: Colors.white)
                        : Text(LocaleKeys.importToken.tr()),
              ),
            ],
          ),
        );
      },
    );
  }
}
