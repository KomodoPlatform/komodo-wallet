import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';

class SettingsCurrencySwitcher extends StatelessWidget {
  const SettingsCurrencySwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.select(
      (SettingsBloc bloc) => bloc.state.fiatCurrency,
    );
    return Row(
      children: [
        const Text('Currency'),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: currency,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(FiatCurrencyChanged(value));
            }
          },
          items: const [
            DropdownMenuItem(value: 'usd', child: Text('USD')),
            DropdownMenuItem(value: 'eur', child: Text('EUR')),
          ],
        ),
      ],
    );
  }
}
