// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mqtt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MqttRemoteConfig _$MqttRemoteConfigFromJson(Map<String, dynamic> json) =>
    MqttRemoteConfig(
      scheme: json['scheme'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      path: json['path'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      identifier: json['identifier'] as String? ?? 'hass_car',
    );

Map<String, dynamic> _$MqttRemoteConfigToJson(MqttRemoteConfig instance) =>
    <String, dynamic>{
      'scheme': instance.scheme,
      'host': instance.host,
      'port': instance.port,
      'path': instance.path,
      'username': instance.username,
      'password': instance.password,
      'identifier': instance.identifier,
    };

MqttSensorPayload _$MqttSensorPayloadFromJson(Map<String, dynamic> json) =>
    MqttSensorPayload(
      topic: json['topic'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$MqttSensorPayloadToJson(MqttSensorPayload instance) =>
    <String, dynamic>{
      'value': instance.value,
    };
