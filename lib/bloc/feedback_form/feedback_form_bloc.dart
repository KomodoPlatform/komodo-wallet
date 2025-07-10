import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feedback/feedback.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/services/feedback/feedback_models.dart';

part 'feedback_form_event.dart';
part 'feedback_form_state.dart';

class FeedbackFormBloc extends Bloc<FeedbackFormEvent, FeedbackFormState> {
  FeedbackFormBloc(this._onSubmit) : super(const FeedbackFormState()) {
    on<FeedbackFormTypeChanged>(_onTypeChanged);
    on<FeedbackFormMessageChanged>(_onMessageChanged);
    on<FeedbackFormContactMethodChanged>(_onContactMethodChanged);
    on<FeedbackFormContactDetailsChanged>(_onContactDetailsChanged);
    on<FeedbackFormSubmitted>(_onSubmitted);
  }

  final OnSubmit _onSubmit;

  void _onTypeChanged(
    FeedbackFormTypeChanged event,
    Emitter<FeedbackFormState> emit,
  ) {
    final contactError = _validateContactDetails(
      state.contactDetails,
      event.type,
      state.contactMethod,
    );
    emit(state.copyWith(
      feedbackType: event.type,
      contactDetailsError: contactError,
    ));
  }

  void _onMessageChanged(
    FeedbackFormMessageChanged event,
    Emitter<FeedbackFormState> emit,
  ) {
    final text = _sanitizeInput(event.message);
    emit(state.copyWith(
      feedbackText: text,
      feedbackTextError: _validateFeedbackText(text),
    ));
  }

  void _onContactMethodChanged(
    FeedbackFormContactMethodChanged event,
    Emitter<FeedbackFormState> emit,
  ) {
    final error = _validateContactDetails(
      state.contactDetails,
      state.feedbackType,
      event.method,
    );
    emit(state.copyWith(
        contactMethod: event.method, contactDetailsError: error));
  }

  void _onContactDetailsChanged(
    FeedbackFormContactDetailsChanged event,
    Emitter<FeedbackFormState> emit,
  ) {
    final details = _sanitizeInput(event.details);
    final error = _validateContactDetails(
      details,
      state.feedbackType,
      state.contactMethod,
    );
    emit(state.copyWith(contactDetails: details, contactDetailsError: error));
  }

  Future<void> _onSubmitted(
    FeedbackFormSubmitted event,
    Emitter<FeedbackFormState> emit,
  ) async {
    final feedbackErr = _validateFeedbackText(state.feedbackText);
    final contactErr = _validateContactDetails(
      state.contactDetails,
      state.feedbackType,
      state.contactMethod,
    );

    if (state.feedbackType == null ||
        feedbackErr != null ||
        contactErr != null) {
      emit(state.copyWith(
        feedbackTextError: feedbackErr,
        contactDetailsError: contactErr,
      ));
      return;
    }

    emit(state.copyWith(status: FeedbackFormStatus.submitting));
    try {
      final data = CustomFeedback(
        feedbackType: state.feedbackType,
        feedbackText: state.feedbackText,
        contactMethod: state.contactMethod,
        contactDetails:
            state.contactDetails.isNotEmpty ? state.contactDetails : null,
      );
      await _onSubmit(
        data.toFormattedDescription(),
        extras: data.toMap(),
      );
      emit(state.copyWith(status: FeedbackFormStatus.success));
    } catch (e) {
      emit(state.copyWith(
          status: FeedbackFormStatus.failure, errorMessage: '$e'));
    }
  }

  String? _validateFeedbackText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return LocaleKeys.feedbackValidatorEmptyError.tr();
    }
    if (trimmed.length > feedbackMaxLength) {
      return LocaleKeys.feedbackValidatorMaxLengthError.tr(
        args: [feedbackMaxLength.toString()],
      );
    }
    return null;
  }

  String? _validateContactDetails(
    String value,
    FeedbackType? type,
    ContactMethod? method,
  ) {
    final trimmed = value.trim();
    final hasMethod = method != null;
    final hasDetails = trimmed.isNotEmpty;

    if (type == FeedbackType.support) {
      if (!hasMethod || !hasDetails) {
        return LocaleKeys.contactRequiredError.tr();
      }
    } else {
      if ((hasMethod && !hasDetails) || (!hasMethod && hasDetails)) {
        return LocaleKeys.contactRequiredError.tr();
      }
    }

    if (!hasDetails) {
      return null;
    }

    if (trimmed.length > contactDetailsMaxLength) {
      return LocaleKeys.contactDetailsMaxLengthError.tr(
        args: [contactDetailsMaxLength.toString()],
      );
    }

    switch (method) {
      case ContactMethod.email:
        if (!_isValidEmail(trimmed)) {
          return LocaleKeys.emailValidatorError.tr();
        }
        break;
      case ContactMethod.discord:
        if (!_isValidDiscordUsername(trimmed)) {
          return LocaleKeys.discordUsernameValidatorError.tr();
        }
        break;
      case ContactMethod.telegram:
        if (!_isValidTelegramUsername(trimmed)) {
          return LocaleKeys.telegramUsernameValidatorError.tr();
        }
        break;
      case ContactMethod.matrix:
        if (!_isValidMatrixId(trimmed)) {
          return LocaleKeys.matrixIdValidatorError.tr();
        }
        break;
      case null:
        break;
    }
    return null;
  }

  String _sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(
            RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'data:[^,]*script[^,]*,', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  bool _isValidEmail(String email) => emailRegex.hasMatch(email);

  bool _isValidDiscordUsername(String username) =>
      discordUsernameRegex.hasMatch(username);

  bool _isValidTelegramUsername(String username) {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    return telegramUsernameRegex.hasMatch(clean);
  }

  bool _isValidMatrixId(String matrixId) => matrixIdRegex.hasMatch(matrixId);
}
