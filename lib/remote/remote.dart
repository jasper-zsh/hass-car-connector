import 'dart:async';

import 'package:hass_car_connector/sensor/sensor.dart';

abstract class Remote {
  StreamController<SensorData> dataStreamController = StreamController();
  StreamSubscription<SensorData>? dataSubscription;

  Future<void> init(Map<String, dynamic> configMap);
  Future<void> start();
  Future<void> onData(SensorData data);
  Future<void> stop();

  void listen() {
    dataSubscription = dataStreamController.stream.listen(onData);
  }
  void subscribe(Stream<SensorData> dataStream) {
    dataStream.pipe(dataStreamController);
  }
  void destroy() {
    dataStreamController.close();
  }
}

abstract class DiscoveryRemote extends Remote {
  StreamController<DiscoveryData> discoveryStreamController = StreamController();
  StreamSubscription<DiscoveryData>? discoverySubscription;

  Future<void> onDiscovery(DiscoveryData discoveryData);

  @override
  void listen() {
    super.listen();
    discoverySubscription = discoveryStreamController.stream.listen(onDiscovery);
  }
  void subscribeDiscovery(Stream<DiscoveryData> dataStream) {
    dataStream.pipe(discoveryStreamController);
  }
  void destroy() {
    super.destroy();
    discoveryStreamController.close();
  }
}