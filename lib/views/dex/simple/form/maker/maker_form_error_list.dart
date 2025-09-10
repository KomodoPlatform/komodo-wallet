import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/blocs/maker_form_bloc.dart';
import 'package:web_dex/model/dex_form_error.dart';
import 'package:web_dex/views/dex/simple/form/error_list/dex_form_error_list.dart';

class MakerFormErrorList extends StatelessWidget {
  const MakerFormErrorList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final makerFormBloc = RepositoryProvider.of<MakerFormBloc>(context);
    return StreamBuilder<List<DexFormError>>(
      initialData: makerFormBloc.getFormErrors(),
      stream: makerFormBloc.outFormErrors,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return DexFormErrorList(errors: snapshot.data!);
      },
    );
  }
}
