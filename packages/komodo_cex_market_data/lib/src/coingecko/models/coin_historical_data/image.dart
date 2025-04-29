import 'package:equatable/equatable.dart';

class Image extends Equatable {
  const Image({this.thumb, this.small});

  factory Image.fromJson(Map<String, dynamic> json) => Image(
        thumb: json['thumb'] as String?,
        small: json['small'] as String?,
      );
  final String? thumb;
  final String? small;

  Map<String, dynamic> toJson() => {
        'thumb': thumb,
        'small': small,
      };

  Image copyWith({
    String? thumb,
    String? small,
  }) {
    return Image(
      thumb: thumb ?? this.thumb,
      small: small ?? this.small,
    );
  }

  @override
  List<Object?> get props => [thumb, small];
}
