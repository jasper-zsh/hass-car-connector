import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:json_annotation/json_annotation.dart';

import 'elm327/protocol.dart';

part 'elm327.g.dart';

@JsonSerializable()
class Elm327SensorStatus {
  String adapter = 'unknown';
  String car = 'disconnected';

  Elm327SensorStatus();

  factory Elm327SensorStatus.fromJson(Map<String, dynamic> json) => _$Elm327SensorStatusFromJson(json);
  Map<String, dynamic> toJson() => _$Elm327SensorStatusToJson(this);
}

@JsonSerializable()
class Elm327SensorConfig {
  String? deviceName;
  String? deviceId;

  Elm327SensorConfig({
    this.deviceName,
    this.deviceId
  });

  factory Elm327SensorConfig.fromJson(Map<String, dynamic> json) => _$Elm327SensorConfigFromJson(json);
  Map<String, dynamic> toJson() => _$Elm327SensorConfigToJson(this);
}

class Elm327Sensor extends Sensor<Elm327SensorStatus> {
  final ble = FlutterReactiveBle();
  late Elm327SensorConfig config;
  StreamSubscription<ConnectionStateUpdate>? conn;
  QualifiedCharacteristic? reader, writer;
  StreamSubscription<List<int>>? readSubscription;
  Elm327Protocol? protocol;
  Timer? timer;

  Elm327Sensor(super.configMap, super.id, super.serviceInstance) {
    status = Elm327SensorStatus();
  }

  @override
  Future<void> onInit(Map<String, dynamic> config) async {
    this.config = Elm327SensorConfig.fromJson(config);
  }

  @override
  Future<void> onStart() async {
    conn = ble.connectToDevice(id: this.config.deviceId!).listen(onConnStateUpdated, onError: onConnError);
  }

  void onConnStateUpdated(ConnectionStateUpdate state) {
    if (state.connectionState == DeviceConnectionState.connected) {
      onAdapterConnected();
    } else {
      setStatus(() {
        status?.adapter = state.connectionState.name;
      });
    }
  }

  void onConnError(dynamic e) {
    logger.e('Connection error: $e');
  }

  void onAdapterConnected() async {
    var services = await ble.discoverServices(config.deviceId!);
    services = services.where((element) => element.serviceId.toString().startsWith('0000fff0')).toList();
    if (services.isEmpty) {
      setStatus(() {
        status?.adapter = 'unsupported';
      });
    }
    var elmService = services[0];
    for (var ch in elmService.characteristics) {
      if (ch.isReadable) {
        reader = QualifiedCharacteristic(characteristicId: ch.characteristicId, serviceId: ch.serviceId, deviceId: config.deviceId!);
      } else if (ch.isWritableWithResponse) {
        writer = QualifiedCharacteristic(characteristicId: ch.characteristicId, serviceId: ch.serviceId, deviceId: config.deviceId!);
      }
    }
    if (reader != null && writer != null) {
      protocol = Elm327Protocol((data) {
        ble.writeCharacteristicWithoutResponse(writer!, value: data);
      });
      readSubscription = ble.subscribeToCharacteristic(reader!).listen((event) {
        protocol?.receive(event);
      });
      logger.i('Found elm service $elmService');
      setStatus(() {
        status?.adapter = 'connected';
      });
      connectToCar();
    } else {
      logger.i('Elm service unsupported, maybe bad match policy?');
      setStatus(() {
        status?.adapter = 'unsupported';
      });
    }
  }

  void connectToCar() async {
    await protocol?.send("ATZ");
    await protocol?.send('ATE0');
    // await send('ATL0');
    await protocol?.send('ATSP0');
    await protocol?.send('ATDP0');
    await protocol?.send('0100');
    scanPIDs();
  }

  List<String> availablePids = List.empty(growable: true);

  Future<void> scanPIDs() async {
    availablePids = List.empty(growable: true);
    for (var pid in formulaMap.keys) {
      pid = '01$pid';
      var result = await protocol!.send(pid);
      if (!result.startsWith('NO DATA')) {
        availablePids.add(pid);
      }
    }
    logger.i('Available PIDs: $availablePids');
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      for (var pid in availablePids) {
        var r = await readPid(pid);
        logger.i('PID: $pid Value: $r');
      }
    });
  }

  Future<double> readPid(String pid) async {
    var s = await protocol!.send(pid);
    var parts = s.trim().split(' ');
    var formula = formulaMap[parts[1]];
    var sData = parts.sublist(2);
    var data = Uint8List(sData.length);
    for (var i = 0; i < sData.length; i ++) {
      var b = int.parse(sData[i], radix: 16);
      data[i] = b;
    }
    return formula!(data);
  }

  @override
  Future<void> onStop() async {
    timer?.cancel();
    timer = null;
    await readSubscription?.cancel();
    await conn?.cancel();
  }
}

typedef Service1Formula = double Function(Uint8List data);

final formulaMap = <String, Service1Formula>{
  '31': (data) => 256.0 * data[0] + data[1],  // Distance since code cleared(km)
  '5E': (data) => (256.0 * data[0] + data[1]) / 20, // Fuel rate(L/h)
  'A6': (data) => (data[0]<<24 + data[1]<<16 + data[2]<<8 + data[3]) / 10 // Odometer
};