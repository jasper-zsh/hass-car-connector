import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/remote/remote.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/services/sensor.dart';
import 'package:logger/logger.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      autoStartOnBoot: true
    ),
    iosConfiguration: IosConfiguration()
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  await setupLocator(service);
  var reporter = ReporterService(
    service: service,
    sensorService: locator<SensorService>(),
    remoteService: locator<RemoteService>()
  );
  await reporter.init();
  reporter.start();
}

class ReporterService {
  final Logger logger;

  List<Remote> remotes = List.empty(growable: true);
  List<Sensor> sensors = List.empty(growable: true);

  ServiceInstance service;
  RemoteService remoteService;
  SensorService sensorService;

  Timer? periodicTimer;

  ReporterService({
    required this.remoteService,
    required this.sensorService,
    required this.service
  }): logger = locator<Logger>() {
    service.on('reload').listen((event) {
      reload();
    });
  }

  Future<void> reload() async {
    logger.i('reloading reporter service...');
    await stop();
    await init();
    start();
    logger.i('reporting service reloaded.');
  }

  void clean() {
    for (var remote in remotes) {
      remote.destroy();
    }
    for (var sensor in sensors) {
      sensor.destroy();
    }
  }

  Future<void> init() async {
    clean();
    remotes = await remoteService.buildAllEnabledRemotes();
    for (var remote in remotes) {
      remote.listen();
    }
    var sensorsMap = await sensorService.buildAllEnabledSensors(service);
    for (var entry in sensorsMap.entries) {
      entry.value.attach(entry.key, service);
      sensors.add(entry.value);
    }

    for (var remote in remotes) {
      for (var sensor in sensorsMap.values) {
        remote.subscribe(sensor.dataStream);
        if (remote is DiscoveryRemote && sensor is DiscoverableSensor) {
          remote.subscribeDiscovery(sensor.discoveryStream);
        }
      }
    }
  }

  void start() async {
    for (var remote in remotes) {
      await remote.start();
    }
    for (var sensor in sensors) {
      await sensor.start();
    }
  }

  Future<void> stop() async {
    if (periodicTimer == null) return;
    periodicTimer!.cancel();
    periodicTimer = null;
    for (var remote in remotes) {
      await remote.stop();
    }
    for (var sensor in sensors) {
      await sensor.stop();
    }
  }
}