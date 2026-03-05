import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_playlist_data.g.dart';

@JsonSerializable()
@HiveType(typeId: 8)
class UpdatePlaylistData {
  @HiveField(0)
  DateTime lastUpdate;
  @HiveField(1)
  Map<String, DateTime> mapIdPlaylists;

  UpdatePlaylistData(this.lastUpdate, this.mapIdPlaylists);

  factory UpdatePlaylistData.fromJson(Map<String, dynamic> json) => _$UpdatePlaylistDataFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePlaylistDataToJson(this);
}
