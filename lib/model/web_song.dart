// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'web_item.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'web_song.g.dart';

@JsonSerializable()
@HiveType(typeId: 5)
class WebSong extends WebItem {
  @HiveField(2)
  String server = '';
  @HiveField(3)
  String interpret;
  @HiveField(4)
  bool ischords = true;
  @HiveField(5)
  String lyric = '';
  WebSong({
    required super.title,
    required super.ref,
    required this.interpret,
    this.ischords = true,
    this.server = '',
    this.lyric = '',
  });
}
