import 'package:event/event.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/repositories/sensor_config.dart';

var sensorUpdated = Event();

class SensorService {
  SensorConfigRepository sensorConfigRepository;

  SensorService({required this.sensorConfigRepository});

  Future<void> saveSensorConfig(SensorConfig sensorConfig) async {

  }
}