import 'dart:math';

import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class TripCalc extends Value {
  double value = 0;
  int _lastTime = 0;
  double _lastSpeed = 0;

  @override
  String get status => 'Speed: ${_lastSpeed.toStringAsFixed(2)}   Trip: ${value.toStringAsFixed(3)}';

  @override
  List<String> get mustPIDs => ['010D'];

  @override
  void update(Map<String, double> result) {
    int time = DateTime.now().millisecondsSinceEpoch;
    var speed = result['010D']!;
    if (_lastTime > 0) {
      var dTime = time - _lastTime;
      var dSpeed = speed - _lastSpeed;
      if (value.isNaN || value.isInfinite) {
        value = 0;
      }
      value += (dTime * _lastSpeed + dSpeed * dTime / 2) / 1000 / 3600;
    }
    _lastTime = time;
    _lastSpeed = speed;
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