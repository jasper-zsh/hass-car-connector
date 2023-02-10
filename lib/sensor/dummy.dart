import 'package:hass_car_connector/sensor/sensor.dart';

class DummySensor implements Sensor, Discoverable {
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
}