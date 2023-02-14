import 'package:flutter/material.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/sensor.dart';
import 'package:hass_car_connector/ui/status/system.dart';

class SensorStatusPage extends StatelessWidget {
  SensorConfig sensorConfig;
  late Sensor sensor;

  SensorStatusPage(this.sensorConfig) {
    sensor = locator<SensorService>().buildSensor(sensorConfig, null);
    sensor.attach(sensorConfig.id!, null);
  }

  @override
  Widget build(BuildContext context) {
    Widget statusWidget;
    switch (sensorConfig.type) {
      case 'system':
        statusWidget = SystemSensorStatusWidget(sensor);
        break;
      default:
        statusWidget = Center(
          child: Text('No status available'),
        );
        break;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${sensorConfig.name} sensor status'),
      ),
      body: statusWidget,
    );
  }
}