import 'package:hass_car_connector/sensor/sensor.dart';

abstract class Value {
  List<String> get mustPIDs => List.empty();
  List<String> get anyPIDs => List.empty();
  void update(Map<String, double> result);
  String get status => "No status";
  void clear();
  List<DiscoveryData> get discovery;
  List<SensorData> get data;
}