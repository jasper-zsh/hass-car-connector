import 'package:hass_car_connector/sensor/sensor.dart';

abstract class Remote {
  Future<void> init(Map<String, dynamic> configMap);
  Future<void> start();
  Future<void> stop();
  Future<void> reportSensorDatas(Iterable<SensorData> sensorDatas);
}