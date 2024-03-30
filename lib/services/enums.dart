import 'package:hive_flutter/hive_flutter.dart';
part 'enums.g.dart';

enum TypeTranspose {
  czech,
  german,
}

enum TypeLyric {
  undefined,
  original,
  translate,
}

@HiveType(typeId: 3)
enum TypeClickCard {
  @HiveField(0)
  none,
  @HiveField(1)
  preview,
  @HiveField(2)
  presentation,
  @HiveField(3)
  sheet,
  @HiveField(4)
  youtube,
}

enum WebAddress {
  velkyZpevnik,
  superMusic,
  proScholy,
}
