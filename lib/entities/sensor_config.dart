import 'package:floor/floor.dart';

@entity
class SensorConfig {
  @PrimaryKey(autoGenerate: true)
  int? id;
  String type;
  String? name;
  String config;
  bool enabled;

  SensorConfig({
    this.id,
    this.type = '',
    this.name,
    this.config = '',
    this.enabled = false
  });
}