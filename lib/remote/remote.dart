import 'dart:async';

import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:logger/logger.dart';

abstract class Remote {
  final logger = locator<Logger>();
  StreamSubscription<SensorData>? dataSubscription;
  StreamSubscription<DiscoveryData>? discoverySubscription;
  Map<String, dynamic> configMap;

  Remote(this.configMap);

  Future<void> onInit(Map<String, dynamic> configMap);
  Future<void> onStart();
  Future<void> onData(SensorData data) async {}
  Future<void> onDiscovery(DiscoveryData discoveryData) async {}
  Future<void> onStop();

  Future<void> init() async {
    await onInit(configMap);
  }

  Future<void> start({
    Stream<SensorData>? dataStream,
    Stream<DiscoveryData>? discoveryStream
  }) async {
    await onStart();
    dataSubscription = dataStream?.listen((event) {
      try {
        onData(event);
      } catch (e) {
        logger.e('Failed to send sensor data', e);
      }
    });
    discoverySubscription = discoveryStream?.listen((event) {
      try {
        onDiscovery(event);
      } catch (e) {
        logger.e('Failed to send discovery data', e);
      }
    });
  }
  Future<void> stop() async {
    dataSubscription?.cancel();
    discoverySubscription?.cancel();
    await onStop();
  }
}
