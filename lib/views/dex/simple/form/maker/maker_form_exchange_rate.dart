import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:komodo_wallet/blocs/maker_form_bloc.dart';
import 'package:komodo_wallet/views/dex/simple/form/exchange_info/exchange_rate.dart';

class MakerFormExchangeRate extends StatelessWidget {
  const MakerFormExchangeRate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<Rational?>(
        initialData: makerFormBloc.price,
        stream: makerFormBloc.outPrice,
        builder: (context, snapshot) {
          return ExchangeRate(
            base: makerFormBloc.sellCoin?.abbr,
            rel: makerFormBloc.buyCoin?.abbr,
            rate: snapshot.data,
          );
        });
  }
}
