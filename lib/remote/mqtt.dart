import 'dart:convert';
import 'dart:developer';

import 'package:hass_car_connector/entities/settings.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/settings.dart';
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

  MqttRemoteConfig({
    this.scheme,
    this.host,
    this.port,
    this.path,
    this.username,
    this.password,
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

class MqttRemote implements Remote, Discovery {
  late MqttServerClient client;
  late MqttRemoteConfig config;
  late String identifier;

  @override
  Future<void> init(Map<String, dynamic> configMap) async {
    config = MqttRemoteConfig.fromJson(configMap);
    identifier = await locator<SettingsService>().readSetting(carIdentifier);
    if (identifier.isEmpty) {
      identifier = 'hass_car';
    }
    client = MqttServerClient("${config.scheme}://${config.host}${config.path}", "hass_car.$identifier");
    if (['ws', 'wss'].contains(config.scheme)) {
      client.useWebSocket = true;
    }
    client.port = config.port!;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
  }

  @override
  Future<void> start() async {
    await client.connect(config.username, config.password);
    client.autoReconnect = true;
  }

  @override
  Future<void> stop() async {
    client.autoReconnect = false;
    client.disconnect();
  }

  void onConnected() {
    log('[$hashCode]MQTT remote connected');
  }
  void onDisconnected() {
    log('[$hashCode]MQTT remote disconnected');
  }

  @override
  Future<void> reportSensorDatas(Iterable<SensorData> sensorDatas) async {
    var payloads = sensorDatas.map((e) => MqttSensorPayload(
      topic: "hass_car/$identifier/${e.type}",
      payload: e.data
    ));
    for (var payload in payloads) {
      var builder = MqttClientPayloadBuilder();
      builder.addString(payload.payload);
      client.publishMessage(payload.topic, MqttQos.exactlyOnce, builder.payload!);
    }
  }

  @override
  Future<void> discovery(Iterable<DiscoveryData> discoveryDatas) async {
    for (var data in discoveryDatas) {
      var topic = "homeassistant/${data.type}/$identifier/${data.objectId}/config";
      var builder = MqttClientPayloadBuilder();
      var baseConfig = <String, dynamic>{
        'state_topic': "hass_car/${identifier}/${data.objectId}",
        'name': "$identifier ${data.friendlyName}",
        'unique_id': "${identifier}_${data.objectId}",
        'object_id': '${identifier}_${data.objectId}',
      };
      baseConfig.addAll(data.config);
      var override = data.overrideConfig['mqtt'];
      if (override != null) {
        baseConfig.addAll(override);
      }
      builder.addString(jsonEncode(baseConfig));
      client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    }
  }
}