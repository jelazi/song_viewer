// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'web_item.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'web_song.g.dart';

@JsonSerializable()
@HiveType(typeId: 5)
class WebSong extends WebItem {
  /// All fields carry a `defaultValue` so that records written by older app
  /// versions — which did not have the field yet — stay readable instead of
  /// failing with a null cast while opening the box.
  @HiveField(2, defaultValue: '')
  String server = '';
  @HiveField(3, defaultValue: '')
  String interpret;
  @HiveField(4, defaultValue: true)
  bool ischords = true;
  @HiveField(5, defaultValue: '')
  String lyric = '';

  /// Optional YouTube link associated with the song (e.g. from worshipchords.com).
  @HiveField(6, defaultValue: '')
  String youtube = '';
  WebSong({
    required super.title,
    required super.ref,
    required this.interpret,
    this.ischords = true,
    this.server = '',
    this.lyric = '',
    this.youtube = '',
  });
}
