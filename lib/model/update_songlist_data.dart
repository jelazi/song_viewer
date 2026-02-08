import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_songlist_data.g.dart';

@JsonSerializable()
@HiveType(typeId: 7)
class UpdateSongListData {
  @HiveField(0)
  DateTime lastUpdate;
  @HiveField(1)
  Map<String, DateTime> mapIdSongs;

  UpdateSongListData(this.lastUpdate, this.mapIdSongs);

  factory UpdateSongListData.fromJson(Map<String, dynamic> json) => _$UpdateSongListDataFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSongListDataToJson(this);
}
