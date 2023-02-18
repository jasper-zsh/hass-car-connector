import 'dart:math';

import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class Distance implements Value {
  @override
  double value = 0;
  int _lastTime = 0;
  double _lastSpeed = 0;

  @override
  List<String> get dependPIDs => ['0D'];

  @override
  void update(Map<String, double> result) {
    int time = DateTime.now().millisecond;
    var speed = result['0D']!;
    if (_lastTime == 0) {
      _lastSpeed = speed;
      _lastTime = time;
      return;
    }
    var dTime = time - _lastTime;
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
  DiscoveryData get discovery => DiscoveryData(
    type: 'sensor',
    objectId: 'trip_calc',
    friendlyName: 'Trip Distance',
    config: {
      'unit_of_measurement': 'km',
      'device_class': 'distance'
    }
  );

  @override
  SensorData get data => SensorData('trip_calc', value.toString());
}