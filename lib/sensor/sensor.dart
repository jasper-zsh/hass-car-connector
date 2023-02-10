import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'sensor.g.dart';

@JsonSerializable()
class SensorData {
  String type;
  Map<String, dynamic> data;

  SensorData(this.type, this.data);

  factory SensorData.fromJson(Map<String, dynamic> json) => _$SensorDataFromJson(json);
  factory SensorData.fromJsonString(String json) => SensorData.fromJson(jsonDecode(json));
  Map<String, dynamic> toJson() => _$SensorDataToJson(this);
}

abstract class Sensor {
  Future<List<SensorData>> read();
}