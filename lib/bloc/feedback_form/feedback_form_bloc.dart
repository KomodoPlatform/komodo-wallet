import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_event.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_repo.dart';
import 'package:web_dex/bloc/feedback_form/feedback_form_state.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/model/feedback_data.dart';
import 'package:web_dex/model/text_error.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/utils/utils.dart';

class FeedbackFormBloc extends Bloc<FeedbackFormEvent, FeedbackFormState> {
  FeedbackFormBloc({required FeedbackFormRepo feedbackFormRepo})
      : _feedbackFormRepo = feedbackFormRepo,
        super(const FeedbackFormInitialState()) {
    on<FeedbackFormSubmitted>(_onSubmitted);
    on<FeedbackFormReset>(_onReset);
  }
  final FeedbackFormRepo _feedbackFormRepo;

  Future<void> _onSubmitted(
      FeedbackFormSubmitted event, Emitter<FeedbackFormState> emit) async {
    if (state is FeedbackFormSendingState) return;
    final BaseError? emailError = _validateEmail(event.email);
    final BaseError? messageError = _validateMessage(event.message);
    if (emailError != null || messageError != null) {
      emit(FeedbackFormFailureState(
        emailError: emailError,
        messageError: messageError,
      ));
      return;
    }

    emit(const FeedbackFormSendingState());
    try {
      final bool isSuccess = await _feedbackFormRepo.send(
        FeedbackData(
          email: event.email,
          message: event.message,
        ),
      );
      if (isSuccess) {
        emit(const FeedbackFormSuccessState());
      } else {
        emit(FeedbackFormFailureState(
          sendingError: TextError(error: LocaleKeys.sendFeedbackError.tr()),
        ));
      }
    } catch (e, s) {
      emit(FeedbackFormFailureState(
        sendingError: TextError(error: LocaleKeys.sendFeedbackError.tr()),
      ));
      log(e.toString(),
          path: 'feedback_form_bloc -> error -> _onSubmitted',
          trace: s,
          isError: true);
    }
  }

  void _onReset(FeedbackFormReset event, Emitter<FeedbackFormState> emit) {
    emit(const FeedbackFormInitialState());
  }

  BaseError? _validateEmail(String email) {
    if (!emailRegExp.hasMatch(email)) {
      return TextError(error: LocaleKeys.emailValidatorError.tr());
    }

    return null;
  }

  BaseError? _validateMessage(String message) {
    if (message.isEmpty) {
      return TextError(error: LocaleKeys.feedbackValidatorEmptyError.tr());
    }
    if (message.length > 500) {
      return TextError(
          error: LocaleKeys.feedbackValidatorMaxLengthError.tr(args: ['500']));
    }
    return null;
  }
}
