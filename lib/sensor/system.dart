import 'dart:convert';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/entities/settings.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/settings.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

part 'system.g.dart';

@JsonSerializable()
class LocationData {
  double latitude;
  double longitude;
  @JsonKey(name: 'gps_accuracy')
  double? accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy
  });

  Map<String, dynamic> toJson() => _$LocationDataToJson(this);
}

class SystemSensor implements Sensor, Discoverable {
  @override
  Future<List<SensorData>> read() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return List.empty();
    }
    var data = List<SensorData>.empty(growable: true);
    Position? location;
    try {
      location = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 10)
      );
    } catch (e) {
      log('Get location timed out');
      location = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
    }
    if (location != null) {
      data.add(SensorData('location', jsonEncode(LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
      ))));
    }
    return data;
  }

  @override
  Future<List<DiscoveryData>> discovery() async {
    var identifier = await locator<SettingsService>().readSetting(carIdentifier);
    return [
      DiscoveryData(
        type: 'device_tracker',
        objectId: 'location',
        friendlyName: "Location",
        overrideConfig: {
          'mqtt': {
            'state_topic': "hass_car/$identifier/location/state",
            'json_attributes_topic': "hass_car/$identifier/location"
          }
        }
      ),
    ];
  }

  @override
  Future<void> init(Map<String, dynamic> config) async {

  }

  @override
  Future<void> start() async {

  }

  @override
  Future<void> stop() async {

  }
}