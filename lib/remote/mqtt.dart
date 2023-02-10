import 'dart:convert';
import 'dart:developer';

import 'package:json_annotation/json_annotation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:hass_car_connector/remote/remote.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

part 'mqtt.g.dart';

@JsonSerializable()
class MqttRemoteConfig {
  String? scheme;
  String? host;
  int? port;
  String? path;
  String? username;
  String? password;
  String? identifier;

  MqttRemoteConfig({
    this.scheme,
    this.host,
    this.port,
    this.path,
    this.username,
    this.password,
    this.identifier = 'hass_car'
  });

  factory MqttRemoteConfig.fromJson(Map<String, dynamic> json) => _$MqttRemoteConfigFromJson(json);
  factory MqttRemoteConfig.fromJsonString(String json) => MqttRemoteConfig.fromJson(jsonDecode(json));
  Map<String, dynamic> toJson() => _$MqttRemoteConfigToJson(this);
}

class MqttSensorPayload {
  String topic;
  String payload;

  MqttSensorPayload({
    required this.topic,
    required this.payload
  });
}

class MqttRemote extends Remote {
  late MqttServerClient client;
  late MqttRemoteConfig config;

  @override
  Future<void> init(Map<String, dynamic> configMap) async {
    config = MqttRemoteConfig.fromJson(configMap);
    if (config.identifier == null || config.identifier!.isEmpty) {
      config.identifier = 'hass_car';
    }
    client = MqttServerClient("${config.scheme}://${config.host}${config.path}", "hass_car.${config.identifier}");
    if (['ws', 'wss'].contains(config.scheme)) {
      client.useWebSocket = true;
    }
    client.port = config.port!;
    client.autoReconnect = true;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
  }

  @override
  Future<void> start() async {
    await client.connect(config.username, config.password);
  }

  @override
  Future<void> stop() async {
    client.disconnect();
  }

  void onConnected() {
    log('MQTT remote connected');
  }
  void onDisconnected() {
    log('MQTT remote disconnected');
  }

  @override
  Future<void> reportSensorDatas(Iterable<SensorData> sensorDatas) async {
    var payloads = sensorDatas.map((e) => MqttSensorPayload(
      topic: "hass_car/${config.identifier}/${e.type}",
      payload: e.data
    ));
    for (var payload in payloads) {
      var builder = MqttClientPayloadBuilder();
      builder.addString(payload.payload);
      client.publishMessage(payload.topic, MqttQos.exactlyOnce, builder.payload!);
    }
  }
}