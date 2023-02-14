import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/entities/settings.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/settings.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
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

@JsonSerializable()
class SystemSensorStatus {
  String locationStatus;

  SystemSensorStatus({
    required this.locationStatus
  });

  factory SystemSensorStatus.fromJson(Map<String, dynamic> json) => _$SystemSensorStatusFromJson(json);
  Map<String, dynamic> toJson() => _$SystemSensorStatusToJson(this);
}

class SystemSensor extends DiscoverableSensor<SystemSensorStatus> {
  final Logger logger = locator<Logger>();
  Timer? timer;

  SystemSensor() {
    status = SystemSensorStatus(
        locationStatus: 'unknown'
    );
  }

  @override
  Future<void> init(Map<String, dynamic> config) async {

  }

  @override
  Future<void> start() async {
    var identifier = await locator<SettingsService>().readSetting(carIdentifier);
    discoverySink.add(DiscoveryData(
        type: 'device_tracker',
        objectId: 'location',
        friendlyName: "Location",
        overrideConfig: {
          'mqtt': {
            'state_topic': "hass_car/$identifier/location/state",
            'json_attributes_topic': "hass_car/$identifier/location"
          }
        }
    ));
    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
      Position? location;
      try {
        location = await Geolocator.getCurrentPosition(
            forceAndroidLocationManager: true,
            timeLimit: const Duration(seconds: 10)
        );
        setStatus(() {
          status?.locationStatus = 'accurate';
        });
      } catch (e) {
        logger.w('Get location timed out');
        location = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
        setStatus(() {
          status?.locationStatus = 'last known';
        });
      }
      if (location != null) {
        dataSink.add(SensorData('location', jsonEncode(LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
        ))));
      } else {
        setStatus(() {
          status?.locationStatus = 'no location';
        });
      }
    });
  }

  @override
  Future<void> stop() async {
    timer?.cancel();
  }
}