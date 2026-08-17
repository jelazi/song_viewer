// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'web_item.dart';

part 'web_interpret.g.dart';

@JsonSerializable()
@HiveType(typeId: 6)
class WebInterpret extends WebItem {
  @HiveField(3, defaultValue: -1)
  int songs = -1;
  WebInterpret({required super.title, required super.ref, this.songs = -1});
}
