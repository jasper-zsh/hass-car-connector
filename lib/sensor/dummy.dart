import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class DummySensor extends DiscoverableSensor {
  Timer? timer;

  @override
  Future<void> init(Map<String, dynamic> config) async {

  }

  @override
  Future<void> start() async {
    discoverySink.add(DiscoveryData(
        type: 'sensor',
        objectId: 'odometer',
        friendlyName: 'Odometer',
        config: {
          'unit_of_measurement': 'km',
          'device_class': 'distance'
        }
    ));
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      dataSink.add(SensorData('odometer', '55'));
    });
  }

  @override
  Future<void> stop() async {
    timer?.cancel();
  }
}