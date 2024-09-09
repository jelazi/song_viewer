// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:html/dom.dart' as dom;

class WebSong {
  String title;
  String ref;
  String interpret;
  bool ischords = true;
  String id = '';
  List<dom.Node> nodes = [];
  String unformatText = '';
  String lyric = '';
  WebSong({
    required this.title,
    required this.ref,
    required this.interpret,
    this.ischords = true,
  });
}
