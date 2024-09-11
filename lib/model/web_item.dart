import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'web_item.g.dart';

@JsonSerializable()
@HiveType(typeId: 4)
class WebItem {
  @HiveField(0)
  String title;
  @HiveField(1)
  String ref;
  WebItem({required this.title, required this.ref});
}
