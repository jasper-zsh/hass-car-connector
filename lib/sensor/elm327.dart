import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/sensor/elm327/distance_since_code_cleared.dart';
import 'package:hass_car_connector/sensor/elm327/fuel.dart';
import 'package:hass_car_connector/sensor/elm327/trip_calc.dart';
import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'elm327/protocol.dart';

part 'elm327.g.dart';

@JsonSerializable()
class Elm327SensorStatus {
  String adapter = 'unknown';
  String car = 'disconnected';
  String protocol = "unknown";
  Set<String> observedPIDs = {};
  Map<String, String> valueStatuses = {};

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
  FlutterReactiveBle? ble;
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
    if (!await Permission.bluetoothConnect.isGranted) {
      logger.e('Bluetooth connect permission is not granted!');
      return;
    }
    ble = FlutterReactiveBle();
    connect();
  }

  void connect() {
    logger.i('Start to connect to adapter ${config.deviceName} ${config.deviceId}');
    conn = ble!.connectToDevice(id: config.deviceId!, connectionTimeout: const Duration(seconds: 15)).listen(onConnStateUpdated, onError: onConnError, onDone: onConnDone, cancelOnError: true);
  }

  void onConnStateUpdated(ConnectionStateUpdate state) {
    logger.i('$state');
    if (state.connectionState == DeviceConnectionState.connected) {
      onAdapterConnected();
    } else {
      setStatus(() {
        status?.adapter = state.connectionState.name;
      });
    }
  }

  void onConnError(dynamic e) async {
    setStatus(() {
      status?.adapter = DeviceConnectionState.disconnected.name;
    });
    logger.e('Connection error: $e');
    connect();
  }

  void onConnDone() {
    setStatus(() {
      status?.adapter = DeviceConnectionState.disconnected.name;
    });
    logger.i('Connection done');
    connect();
  }

  void onAdapterConnected() async {
    var services = await ble!.discoverServices(config.deviceId!);
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
      protocol = Elm327Protocol(logger, (data) {
        ble?.writeCharacteristicWithoutResponse(writer!, value: data);
      });
      readSubscription = ble!.subscribeToCharacteristic(reader!).listen((event) {
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
    await protocol?.send('ATS0');
    await protocol?.send('0100');
    var obdProtocol = await protocol?.send('ATDP');
    setStatus(() {
      status?.car = 'connected';
      status?.protocol = obdProtocol ?? 'unknown';
    });
    scanPIDs();
  }

  List<Value> supportedValues = [];
  Set<String> observedPIDs = {};

  Future<void> scanPIDs() async {
    var availablePIDs = await protocol!.service1Available();
    logger.i('Sniffed available service 1 PIDs: $availablePIDs');
    supportedValues = [];
    for (var value in values) {
      var supported = true;
      for (var pid in value.mustPIDs) {
        supported |= availablePIDs.contains(pid);
      }
      for (var pid in value.mustPIDs) {
        supported &= availablePIDs.contains(pid);
      }
      if (supported) {
        supportedValues.add(value);
      }
    }
    observedPIDs = {};
    for (var value in supportedValues) {
      observedPIDs.addAll(value.mustPIDs.where((element) => availablePIDs.contains(element)));
      observedPIDs.addAll(value.anyPIDs.where((element) => availablePIDs.contains(element)));
    }
    setStatus(() {
      status?.observedPIDs = observedPIDs;
    });
    for (var value in supportedValues) {
      value.clear();
      for (var d in value.discovery) {
        discoverySink?.add(d);
      }
    }
    status?.valueStatuses = {};
    running = true;
    Timer.run(() async {
      while (running) {
        var results = <String, double>{};
        for (var pid in observedPIDs) {
          try {
            var r = await protocol!.requestService1Value(pid);
            results[pid] = r;
          } catch (e) {
            logger.e('Failed to read PID $pid');
          }
        }
        for (var value in supportedValues) {
          try {
            var result = <String, double>{};
            for (var pid in value.mustPIDs) {
              if (results.containsKey(pid)) {
                result[pid] = results[pid]!;
              }
            }
            for (var pid in value.anyPIDs) {
              if (results.containsKey(pid)) {
                result[pid] = results[pid]!;
              }
            }
            value.update(result);
            status?.valueStatuses[value.runtimeType.toString()] = value.status;
          } catch (e) {
            logger.e('Failed to update value ${value.runtimeType.toString()}: $e');
          }
        }
        setStatus(() {});
      }
    });
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      for (var value in supportedValues) {
        for (var d in value.data) {
          dataSink?.add(d);
        }
      }
    });
  }

  @override
  Future<void> onStop() async {
    running = false;
    timer?.cancel();
    timer = null;
    await readSubscription?.cancel();
    await conn?.cancel();
    conn = null;
    ble = null;
    setStatus(() {
      status = Elm327SensorStatus();
    });
  }
}

final values = <Value>[
  TripCalc(), FuelValue({'displacement': 2.0}), DistanceSinceCodeCleared(),
];
