import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class DummySensor extends Sensor {
  Timer? timer;

  DummySensor(super.configMap, super.id, super.serviceInstance);

  @override
  Future<void> onInit(Map<String, dynamic> config) async {

  }

  @override
  Future<void> onStart() async {
    discoverySink?.add(DiscoveryData(
        type: 'sensor',
        objectId: 'odometer',
        friendlyName: 'Odometer',
        config: {
          'unit_of_measurement': 'km',
          'device_class': 'distance'
        }
    ));
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      dataSink?.add(SensorData('odometer', '55'));
    });
  }

  @override
  Future<void> onStop() async {
    timer?.cancel();
  }
}