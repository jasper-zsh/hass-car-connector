import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/remote/mqtt.dart';
import 'package:hass_car_connector/remote/remote.dart';
import 'package:hass_car_connector/repositories/remote_config.dart';
import 'package:hass_car_connector/sensor/dummy.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
      autoStart: true,
      autoStartOnBoot: true
    ),
    iosConfiguration: IosConfiguration()
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  await setupLocator();
  var reporter = ReporterService(
    remoteService: locator<RemoteService>()
  );
  await reporter.init();
  reporter.start();
}

class ReporterService {
  List<Remote> remotes = List.empty(growable: true);
  List<Sensor> sensors = List.empty(growable: true);

  RemoteService remoteService;

  ReporterService({
    required this.remoteService
  });

  Future<void> init() async {
    remotes = await remoteService.buildAllEnabledRemotes();
    for (var remote in remotes) {
      await remote.start();
    }

    var sensor = DummySensor();
    sensors.add(sensor);
  }

  void start() {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      var data = List<SensorData>.empty(growable: true);
      for (var sensor in sensors) {
        data.addAll(await sensor.read());
      }
      for (var remote in remotes) {
        remote.reportSensorDatas(data);
      }
    });
  }
}