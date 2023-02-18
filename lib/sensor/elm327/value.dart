import 'package:hass_car_connector/sensor/sensor.dart';

abstract class Value {
  List<String> get dependPIDs;
  void update(Map<String, double> result);
  double get value;
  void clear();
  DiscoveryData get discovery;
  SensorData get data;
}