import 'dart:developer';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class Elm327Sensor implements Sensor {
  final ble = FlutterReactiveBle();

  @override
  Future<void> init(SensorConfig sensorConfig) async {
    ble.scanForDevices(
      withServices: List.empty()
    ).listen((event) {
      log(event.toString());
    });
  }

  @override
  Future<List<SensorData>> read() async {
    return List.empty();
  }

}