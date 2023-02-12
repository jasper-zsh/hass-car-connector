import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/remote/mqtt.dart';
import 'package:hass_car_connector/remote/remote.dart';
import 'package:hass_car_connector/repositories/remote_config.dart';
import 'package:hass_car_connector/sensor/dummy.dart';
import 'package:hass_car_connector/sensor/elm327.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/sensor/system.dart';
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
    service: service,
    remoteService: locator<RemoteService>()
  );
  await reporter.init();
  reporter.start();
}

class ReporterService {
  List<Remote> remotes = List.empty(growable: true);
  List<Sensor> sensors = List.empty(growable: true);

  ServiceInstance service;
  RemoteService remoteService;

  Timer? periodicTimer;

  ReporterService({
    required this.remoteService,
    required this.service
  }) {
    service.on('reload').listen((event) {
      reload();
    });
  }

  Future<void> reload() async {
    log('reloading reporter service...');
    await stop();
    await init();
    start();
    log('reporting service reloaded.');
  }

  Future<void> init() async {
    remotes = await remoteService.buildAllEnabledRemotes();
    for (var remote in remotes) {
      await remote.start();
    }

    var sensor = DummySensor();
    sensors.add(sensor);
    sensors.add(SystemSensor());
    sensors.add(Elm327Sensor(
      backgroundService: service,
    ));

    for (var remote in remotes) {
      if (remote is Discovery) {
        for (var sensor in sensors) {
          if (sensor is Discoverable) {
            await (remote as Discovery).discovery(
              await (sensor as Discoverable).discovery()
            );
          }
        }
      }
    }
  }

  void start() {
    if (periodicTimer != null) return;
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

  Future<void> stop() async {
    if (periodicTimer == null) return;
    periodicTimer!.cancel();
    periodicTimer = null;
    for (var remote in remotes) {
      await remote.stop();
    }
  }
}