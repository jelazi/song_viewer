import 'package:equatable/equatable.dart';

class QrLink extends Equatable {
  final String label;
  final String url;

  const QrLink({required this.label, required this.url});

  Map<String, dynamic> toJson() => {'label': label, 'url': url};

  factory QrLink.fromJson(Map<String, dynamic> json) => QrLink(
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  QrLink copyWith({String? label, String? url}) => QrLink(
        label: label ?? this.label,
        url: url ?? this.url,
      );

  static List<QrLink> get defaults => const [
        QrLink(label: 'Current Song', url: ''),
        QrLink(label: 'Web App', url: 'https://songsviewerweb.web.app/'),
        QrLink(label: 'Žižkovi', url: 'https://www.zizkovi.online/'),
      ];

  @override
  List<Object?> get props => [label, url];
}
