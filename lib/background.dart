import 'dart:async';
import 'dart:convert';
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

  StreamController<SensorData> dataStreamController = StreamController.broadcast();
  StreamController<DiscoveryData> discoveryStreamController = StreamController.broadcast();

  ServiceInstance service;
  RemoteService remoteService;
  SensorService sensorService;

  ReporterService({
    required this.remoteService,
    required this.sensorService,
    required this.service
  }): logger = locator<Logger>() {
    service.on('reload').listen((event) {
      reload();
    });
    dataStreamController.stream.listen((event) {
      logger.i('[SensorData] ${jsonEncode(event)}');
    });
    discoveryStreamController.stream.listen((event) {
      logger.i('[DiscoveryData] ${jsonEncode(event)}');
    });
  }

  Future<void> reload() async {
    logger.i('reloading reporter service...');
    await stop();
    await init();
    start();
    logger.i('reporting service reloaded.');
  }

  Future<void> init() async {
    remotes = await remoteService.buildAllEnabledRemotes();
    sensors = await sensorService.buildAllEnabledSensors(service);
    for (var sensor in sensors) {
      await sensor.init(
          dataSink: dataStreamController.sink,
          discoverySink: discoveryStreamController.sink);
      }
    for (var remote in remotes) {
      await remote.init();
    }
  }

  void start() async {
    for (var remote in remotes) {
      await remote.start(
        dataStream: dataStreamController.stream,
        discoveryStream: discoveryStreamController.stream
      );
    }
    for (var sensor in sensors) {
      await sensor.start();
    }
  }

  Future<void> stop() async {
    for (var remote in remotes) {
      await remote.stop();
    }
    for (var sensor in sensors) {
      await sensor.stop();
    }
  }
}