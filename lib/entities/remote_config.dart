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
    required this.name,
    required this.type,
    required this.config,
    this.enabled = false
  });
}