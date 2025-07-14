class CustomFeedback {
  CustomFeedback({
    this.feedbackType,
    this.feedbackText,
    this.contactMethod,
    this.contactDetails,
  });

  FeedbackType? feedbackType;
  String? feedbackText;
  ContactMethod? contactMethod;
  String? contactDetails;

  @override
  String toString() {
    return toMap().toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'feedback_type': feedbackType?.name,
      'feedback_text': feedbackText,
      'contact_method': contactMethod?.name,
      'contact_details': contactDetails,
    };
  }

  String toFormattedDescription() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer
        .writeln('📋 ${feedbackType?.description ?? 'Unknown'}'.toUpperCase());
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('💬 USER FEEDBACK:');
    buffer.writeln('─' * 40);
    if (feedbackText?.trim().isNotEmpty == true) {
      final paragraphs = feedbackText!.trim().split('\n');
      for (int i = 0; i < paragraphs.length; i++) {
        final paragraph = paragraphs[i].trim();
        if (paragraph.isNotEmpty) {
          buffer.writeln('   $paragraph');
          if (i < paragraphs.length - 1) buffer.writeln();
        }
      }
    } else {
      buffer.writeln('   [No feedback text provided]');
    }
    buffer.writeln();
    buffer.writeln('📞 CONTACT INFORMATION:');
    buffer.writeln('─' * 40);
    if (contactMethod != null && contactDetails?.trim().isNotEmpty == true) {
      final contact = contactDetails!.trim();
      switch (contactMethod!) {
        case ContactMethod.email:
          buffer.writeln('   📧 Email: $contact');
          break;
        case ContactMethod.discord:
          buffer.writeln('   🎮 Discord: $contact');
          break;
        case ContactMethod.telegram:
          buffer.writeln(
              '   📱 Telegram: ${contact.startsWith('@') ? contact : '@$contact'}');
          break;
        case ContactMethod.matrix:
          buffer.writeln('   🔗 Matrix: $contact');
          break;
      }
      if (feedbackType == FeedbackType.support) {
        buffer.writeln(
            '   ⚠️  PRIORITY: Contact details provided for support request');
      }
    } else {
      buffer.writeln('   ❌ No contact information provided');
      if (feedbackType == FeedbackType.support) {
        buffer.writeln(
            '   ⚠️  WARNING: Support request without contact details!');
      }
    }
    return buffer.toString();
  }
}

enum FeedbackType {
  bugReport,
  featureRequest,
  support,
  other;
}

extension FeedbackTypeDescription on FeedbackType {
  String get description {
    switch (this) {
      case FeedbackType.bugReport:
        return 'Bug Report';
      case FeedbackType.featureRequest:
        return 'Feature Request';
      case FeedbackType.support:
        return 'Support Request';
      case FeedbackType.other:
        return 'Other';
    }
  }
}

enum ContactMethod {
  discord,
  matrix,
  telegram,
  email;
}

extension ContactMethodLabel on ContactMethod {
  String get label {
    switch (this) {
      case ContactMethod.discord:
        return 'Discord';
      case ContactMethod.matrix:
        return 'Matrix';
      case ContactMethod.telegram:
        return 'Telegram';
      case ContactMethod.email:
        return 'Email';
    }
  }
}
