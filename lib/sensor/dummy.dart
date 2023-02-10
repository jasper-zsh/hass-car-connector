import 'package:hass_car_connector/sensor/sensor.dart';

class DummySensor extends Sensor {
  @override
  Future<List<SensorData>> read() async {
    return [
      SensorData('odometer', '55'),
    ];
  }
}