import 'dart:math';

import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class TripCalc extends Value {
  @override
  double value = 0;
  int _lastTime = 0;
  double _lastSpeed = 0;

  @override
  List<String> get mustPIDs => ['010D'];

  @override
  void update(Map<String, double> result) {
    int time = DateTime.now().millisecondsSinceEpoch;
    var speed = result['010D']!;
    if (_lastTime == 0) {
      _lastSpeed = speed;
      _lastTime = time;
      return;
    }
    var dTime = time - _lastTime;
    _lastTime = time;
    var minSpeed = min(speed, _lastSpeed);
    var dSpeed = (_lastSpeed - speed).abs();
    value += (dTime * minSpeed + dSpeed * dTime / 2) / 1000 / 3600;
  }

  @override
  void clear() {
    value = 0;
    _lastTime = 0;
    _lastSpeed = 0;
  }

  @override
  List<DiscoveryData> get discovery => [DiscoveryData(
    type: 'sensor',
    objectId: 'trip_calc',
    friendlyName: 'Trip Distance',
    config: {
      'unit_of_measurement': 'km',
      'device_class': 'distance',
      'state_class': 'total_increasing',
    }
  )];

  @override
  List<SensorData> get data => [SensorData('trip_calc', value.toStringAsFixed(3))];
}