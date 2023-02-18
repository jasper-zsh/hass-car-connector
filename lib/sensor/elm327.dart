import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/elm327/distance.dart';
import 'package:hass_car_connector/sensor/elm327/value.dart';
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
  var running = false;

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

  Map<List<String>, Value> supportedValues = {};
  Set<String> observedPIDs = {};

  Future<void> scanPIDs() async {
    var availablePids = List.empty(growable: true);
    for (var pid in formulaMap.keys) {
      pid = '01$pid';
      var result = await protocol!.send(pid);
      if (!result.startsWith('NO DATA')) {
        availablePids.add(pid);
      }
    }
    logger.i('Available PIDs: $availablePids');
    supportedValues = {};
    for (var value in values) {
      var supported = true;
      for (var pid in value.dependPIDs) {
        supported &= availablePids.contains(pid);
      }
      if (supported) {
        supportedValues[value.dependPIDs] = value;
      }
    }
    for (var pids in supportedValues.keys) {
      observedPIDs.addAll(pids);
    }
    for (var value in supportedValues.values) {
      value.clear();
      discoverySink?.add(value.discovery);
    }
    Timer.run(() async {
      while (running) {
        var results = <String, double>{};
        for (var pid in observedPIDs) {
          var r = await readPid(pid);
          results[pid] = r;
        }
        for (var entry in supportedValues.entries) {
          var result = <String, double>{};
          for (var pid in entry.key) {
            result[pid] = results[pid]!;
          }
          entry.value.update(result);
        }
      }
    });
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      for (var value in supportedValues.values) {
        dataSink?.add(value.data);
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
    running = false;
    timer?.cancel();
    timer = null;
    await readSubscription?.cancel();
    await conn?.cancel();
  }
}

final values = <Value>[
  Distance(),
];

typedef Service1Formula = double Function(Uint8List data);

final formulaMap = <String, Service1Formula>{
  '0D': (data) => data[0].toDouble(), // Vehicle speed(km/h)
  '10': (data) => (256.0 * data[0] + data[1]) / 100,  // Air flow rate(g/s)
  '31': (data) => 256.0 * data[0] + data[1],  // Distance since code cleared(km)
  '5E': (data) => (256.0 * data[0] + data[1]) / 20, // Fuel rate(L/h)
  'A6': (data) => (data[0]<<24 + data[1]<<16 + data[2]<<8 + data[3]) / 10 // Odometer
};