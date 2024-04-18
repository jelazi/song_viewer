import 'package:easy_localization/easy_localization.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class User {
  @HiveField(0)
  String name;
  @HiveField(1)
  String password;
  @HiveField(2)
  TypeUser typeUser = TypeUser.none;

  List<String> allowedGroup = [];

  User(this.name, this.password);

  User.empty()
      : name = '',
        password = '';

  String get nameTypeUser {
    switch (typeUser) {
      case TypeUser.none:
        return 'none'.tr();
      case TypeUser.viewer:
        return 'viewer'.tr();
      case TypeUser.editor:
        return 'editor'.tr();
      case TypeUser.admin:
        return 'admin'.tr();
      case TypeUser.superuser:
        return 'superuser'.tr();
    }
  }

  static TypeUser getTypeUserByName(String nameTypeUser) {
    if (nameTypeUser == 'none'.tr()) {
      return TypeUser.none;
    }
    if (nameTypeUser == 'viewer'.tr()) {
      return TypeUser.viewer;
    }
    if (nameTypeUser == 'editor'.tr()) {
      return TypeUser.editor;
    }
    if (nameTypeUser == 'admin'.tr()) {
      return TypeUser.admin;
    }
    if (nameTypeUser == 'superuser'.tr()) {
      return TypeUser.superuser;
    }

    return TypeUser.none;
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  copy(User newUser) {
    name = newUser.name;
    password = newUser.password;
    typeUser = newUser.typeUser;
    allowedGroup.clear();
    for (String group in newUser.allowedGroup) {
      allowedGroup.add(group);
    }
  }
}

@HiveType(typeId: 1)
enum TypeUser {
  @HiveField(0)
  none,
  @HiveField(1)
  viewer,
  @HiveField(2)
  editor,
  @HiveField(3)
  admin,
  @HiveField(4)
  superuser,
}
