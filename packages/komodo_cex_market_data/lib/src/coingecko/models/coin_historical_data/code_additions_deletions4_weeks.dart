import 'package:equatable/equatable.dart';

class CodeAdditionsDeletions4Weeks extends Equatable {
  const CodeAdditionsDeletions4Weeks({this.additions, this.deletions});

  factory CodeAdditionsDeletions4Weeks.fromJson(Map<String, dynamic> json) {
    return CodeAdditionsDeletions4Weeks(
      additions: json['additions'] as dynamic,
      deletions: json['deletions'] as dynamic,
    );
  }
  final dynamic additions;
  final dynamic deletions;

  Map<String, dynamic> toJson() => {
        'additions': additions,
        'deletions': deletions,
      };

  CodeAdditionsDeletions4Weeks copyWith({
    dynamic additions,
    dynamic deletions,
  }) {
    return CodeAdditionsDeletions4Weeks(
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
    );
  }

  @override
  List<Object?> get props => [additions, deletions];
}
