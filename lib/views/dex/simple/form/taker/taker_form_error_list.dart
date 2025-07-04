import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_bloc.dart';
import 'package:komodo_wallet/bloc/taker_form/taker_state.dart';
import 'package:komodo_wallet/model/dex_form_error.dart';
import 'package:komodo_wallet/views/dex/simple/form/error_list/dex_form_error_list.dart';

class TakerFormErrorList extends StatelessWidget {
  const TakerFormErrorList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TakerBloc, TakerState, List<DexFormError>>(
      selector: (state) => state.errors,
      builder: (context, errors) {
        return DexFormErrorList(errors: errors);
      },
    );
  }
}
