import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  String? serviceUUID;

  Elm327SensorConfig({
    this.deviceName,
    this.deviceId,
    this.serviceUUID,
  });

  factory Elm327SensorConfig.fromJson(Map<String, dynamic> json) => _$Elm327SensorConfigFromJson(json);
  Map<String, dynamic> toJson() => _$Elm327SensorConfigToJson(this);
}

class Elm327Sensor extends Sensor<Elm327SensorStatus> {
  final blue = FlutterBluePlus.instance;
  late Elm327SensorConfig config;
  BluetoothDevice? device;
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
    connect();
  }

  void connect() async {
    blue.setLogLevel(LogLevel.info);
    logger.i('Start to connect to adapter ${config.deviceName} ${config.deviceId}');
    var devices = await blue.connectedDevices;
    for (var device in devices) {
      if (device.id.id == config.deviceId!) {
        this.device = device;
        logger.i('Found connected device: $device');
        onAdapterConnected();
        return;
      }
    }
    setStatus(() {
      status?.adapter = 'scanning';
    });
    blue.startScan(timeout: const Duration(seconds: 5));
    blue.scanResults.listen((event) async {
      for (var r in event) {
        if (r.device.id.id == config.deviceId!) {
          device = r.device;
          blue.stopScan();
          logger.i('Connecting to device $device');
          await device?.connect();
          onAdapterConnected();
          return;
        }
      }
    });
  }

  void onAdapterConnected() async {
    var services = await device!.discoverServices();
    services = services.where((element) => element.uuid.toString().startsWith('0000fff0')).toList();
    if (services.isEmpty) {
      setStatus(() {
        status?.adapter = 'unsupported';
      });
    }
    var elmService = services[0];
    BluetoothCharacteristic? reader, writer;
    for (var ch in elmService.characteristics) {
      if (ch.properties.notify) {
        reader = ch;
      } else if (ch.properties.write) {
        writer = ch;
      }
    }
    if (reader != null && writer != null) {
      protocol = Elm327Protocol(logger, (data) {
        writer?.write(data);
      });
      await reader.setNotifyValue(true);
      readSubscription = reader.value.listen((event) {
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
    await device?.disconnect();
    setStatus(() {
      status = Elm327SensorStatus();
    });
  }
}

final values = <Value>[
  TripCalc(), FuelValue({'displacement': 2.0}), DistanceSinceCodeCleared(),
];
