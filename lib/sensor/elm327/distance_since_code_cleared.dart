import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class DistanceSinceCodeCleared extends Value {
  double value = 0;

  @override
  List<String> get mustPIDs => ['0131'];

  @override
  void clear() {
    value = 0;
  }

  @override
  String get status => value.toStringAsFixed(3);

  @override
  List<SensorData> get data => [SensorData('distance_since_code_cleared', value.toStringAsFixed(3))];

  @override
  List<DiscoveryData> get discovery => [DiscoveryData(
      type: 'sensor',
      objectId: 'distance_since_code_cleared',
      friendlyName: 'Distance since code cleared',
      config: {
        'unit_of_measurement': 'km',
        'device_class': 'distance',
        'state_class': 'total_increasing',
      }
  )];

  @override
  void update(Map<String, double> result) {
    value = result['0131']!;
  }

}