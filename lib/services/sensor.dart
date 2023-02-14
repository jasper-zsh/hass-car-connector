import 'dart:convert';
import 'dart:developer';

import 'package:event/event.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/repositories/sensor_config.dart';
import 'package:hass_car_connector/sensor/dummy.dart';
import 'package:hass_car_connector/sensor/elm327.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/sensor/system.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:logger/logger.dart';

var sensorUpdated = Event();

typedef SensorFactory = Sensor Function(ServiceInstance? serviceInstance);

var sensorFactories = <String, SensorFactory>{
  'elm327': (serviceInstance) => Elm327Sensor(
    backgroundService: serviceInstance
  ),
  'system': (serviceInstance) => SystemSensor(),
  'dummy': (serviceInstance) => DummySensor(),
};

class SensorService {
  final logger = locator<Logger>();
  SensorConfigRepository sensorConfigRepository;

  SensorService({required this.sensorConfigRepository});

  Sensor buildSensor(SensorConfig sensorConfig, ServiceInstance? serviceInstance) {
    var factory = sensorFactories[sensorConfig.type];
    if (factory == null) {
      logger.e('Sensor factory ${sensorConfig.type} not registered.');
      throw Exception('Sensor factory ${sensorConfig.type} not registered.');
    }
    return factory(serviceInstance);
  }

  Future<Map<int, Sensor>> buildAllEnabledSensors(ServiceInstance? serviceInstance) async {
    var sensors = <int, Sensor>{};
    var configs = await sensorConfigRepository.findEnabled();
    for (var config in configs) {
      var sensor = buildSensor(config, serviceInstance);
      Map<String, dynamic> c = {};
      if (config.config.isNotEmpty) {
        c = jsonDecode(config.config);
      }
      await sensor.init(c);
      sensors[config.id!] = sensor;
    }
    return sensors;
  }

  Future<void> saveSensorConfig(SensorConfig sensorConfig) async {
    if (sensorConfig.id == null) {
      sensorConfig.id = await sensorConfigRepository.insertSensorConfig(sensorConfig);
    } else {
      await sensorConfigRepository.updateSensorConfig(sensorConfig);
    }
    sensorUpdated.broadcast();
  }
}