import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/views/dex/simple/form/exchange_info/dex_compared_to_cex.dart';

class MakerFormCompareToCex extends StatelessWidget {
  const MakerFormCompareToCex({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<Rational?>(
      initialData: makerFormBloc.price,
      stream: makerFormBloc.outPrice,
      builder: (context, snapshot) {
        return DexComparedToCex(
          base: makerFormBloc.sellCoin,
          rel: makerFormBloc.buyCoin,
          rate: snapshot.data,
        );
      },
    );
  }
}
