import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class DummySensor extends Sensor implements Discoverable {
  @override
  Future<List<SensorData>> read() async {
    return [
      SensorData('odometer', '55'),
    ];
  }

  @override
  Future<List<DiscoveryData>> discovery() async {
    return [
      DiscoveryData(
        type: 'sensor',
        objectId: 'odometer',
        friendlyName: 'Odometer',
        config: {
          'unit_of_measurement': 'km',
          'device_class': 'distance'
        }
      )
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