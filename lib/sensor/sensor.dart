import 'dart:async';
import 'dart:convert';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

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

@JsonSerializable()
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

  factory DiscoveryData.fromJson(Map<String, dynamic> json) => _$DiscoveryDataFromJson(json);
  Map<String, dynamic> toJson() => _$DiscoveryDataToJson(this);
}

abstract class Sensor<S> {
  final logger = locator<Logger>();
  ServiceInstance? serviceInstance;
  int? id;
  S? status;
  Map<String, dynamic> configMap;
  StreamSink<SensorData>? dataSink;
  StreamSink<DiscoveryData>? discoverySink;

  Sensor(this.configMap, this.id, this.serviceInstance);

  Future<void> init({
    StreamSink<SensorData>? dataSink,
    StreamSink<DiscoveryData>? discoverySink
  }) async {
    this.dataSink = dataSink;
    this.discoverySink = discoverySink;
    serviceInstance?.on('sensors/$id/getStatus').listen((event) {
      sendStatusInService();
    });
    await onInit(configMap);
  }

  Future<void> start() async {
    await onStart();
  }

  Future<void> stop() async {
    await onStop();
  }

  Stream<Map<String, dynamic>> getStatusStream() {
    var stream = FlutterBackgroundService().on("sensors/$id/status").map((event) {
      logger.i("Got sensor status $event");
      return jsonDecode(event!['status']) as Map<String, dynamic>;
    });
    getStatusInUI();
    return stream;
  }

  void getStatusInUI() {
    FlutterBackgroundService().invoke('sensors/$id/getStatus');
  }

  void sendStatusInService() {
    serviceInstance?.invoke("sensors/$id/status", {
      'status': jsonEncode(status)
    });
  }

  void setStatus(void Function() f) {
    f();
    if (serviceInstance != null && status != null) {
      sendStatusInService();
    }
  }

  Future<void> onInit(Map<String, dynamic> config);
  Future<void> onStart();
  Future<void> onStop();
}
