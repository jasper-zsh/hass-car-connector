import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'elm327.g.dart';

@JsonSerializable()
class Elm327SensorConfig {
  String? deviceName;
  String? deviceId;

  Elm327SensorConfig({
    this.deviceName,
    this.deviceId
  });

  factory Elm327SensorConfig.fromJson(Map<String, dynamic> json) => _$Elm327SensorConfigFromJson(json);
  Map<String, dynamic> toJson() => _$Elm327SensorConfigToJson(this);
}

class Elm327Sensor implements Sensor {
  final ble = FlutterReactiveBle();
  ServiceInstance? backgroundService;
  late Elm327SensorConfig config;
  late StreamSubscription<ConnectionStateUpdate> conn;

  Elm327Sensor({this.backgroundService});

  @override
  Future<void> init(Map<String, dynamic> config) async {
    this.config = Elm327SensorConfig.fromJson(config);
  }

  @override
  Future<void> start() async {
    conn = ble.connectToDevice(id: this.config.deviceId!).listen(onConnStateUpdated, onError: onConnError);
  }

  void onConnStateUpdated(ConnectionStateUpdate state) {}

  void onConnError(dynamic e) {
    log('Connection error: $e');
  }

  @override
  Future<void> stop() async {
    await conn.cancel();
  }

  @override
  Future<List<SensorData>> read() async {
    return List.empty();
  }

}