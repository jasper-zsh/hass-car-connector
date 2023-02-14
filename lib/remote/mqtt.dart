import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:hass_car_connector/entities/settings.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/settings.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
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

class MqttRemote extends DiscoveryRemote {
  final logger = locator<Logger>();

  late MqttServerClient client;
  late MqttRemoteConfig config;
  late String identifier;
  StreamSubscription<SensorData>? dataSubscription;

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
  Future<void> onData(SensorData data) async {
    var payload = MqttSensorPayload(
        topic: "hass_car/$identifier/${data.type}",
        payload: data.data
    );
    var builder = MqttClientPayloadBuilder();
    builder.addString(payload.payload);
    client.publishMessage(payload.topic, MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  Future<void> onDiscovery(DiscoveryData discoveryData) async {
    var topic = "homeassistant/${discoveryData.type}/$identifier/${discoveryData.objectId}/config";
    var builder = MqttClientPayloadBuilder();
    var baseConfig = <String, dynamic>{
      'state_topic': "hass_car/${identifier}/${discoveryData.objectId}",
      'name': "$identifier ${discoveryData.friendlyName}",
      'unique_id': "${identifier}_${discoveryData.objectId}",
      'object_id': '${identifier}_${discoveryData.objectId}',
    };
    baseConfig.addAll(discoveryData.config);
    var override = discoveryData.overrideConfig['mqtt'];
    if (override != null) {
      baseConfig.addAll(override);
    }
    builder.addString(jsonEncode(baseConfig));
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  Future<void> stop() async {
    client.autoReconnect = false;
    client.disconnect();
    dataSubscription?.cancel();
  }

  void onConnected() {
    logger.i('[$hashCode]MQTT remote connected');
  }
  void onDisconnected() {
    logger.i('[$hashCode]MQTT remote disconnected');
  }
}