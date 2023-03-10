import 'package:floor/floor.dart';

@entity
class RemoteConfig {
  @PrimaryKey(autoGenerate: true)
  int? id;
  String name;
  String type;
  String config;
  bool enabled;

  RemoteConfig({
    this.id,
    this.name = "",
    this.type = "",
    this.config = "",
    this.enabled = false
  });
}