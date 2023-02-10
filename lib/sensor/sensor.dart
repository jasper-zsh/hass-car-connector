import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'sensor.g.dart';

@JsonSerializable()
class SensorData {
  String type;
  String data;

  SensorData(this.type, this.data);

  factory SensorData.fromJson(Map<String, dynamic> json) => _$SensorDataFromJson(json);
  factory SensorData.fromJsonString(String json) => SensorData.fromJson(jsonDecode(json));
  Map<String, dynamic> toJson() => _$SensorDataToJson(this);
}

class DiscoveryData {
  String type;
  String objectId;
  String friendlyName;
  Map<String, dynamic> config;
  Map<String, Map<String, dynamic>> overrideConfig;

  DiscoveryData({
    required this.type,
    required this.objectId,
    required this.friendlyName,
    this.config = const{},
    this.overrideConfig = const {}
  });
}

abstract class Sensor {
  Future<List<SensorData>> read();
}

abstract class Discoverable {
  Future<List<DiscoveryData>> discovery();
}