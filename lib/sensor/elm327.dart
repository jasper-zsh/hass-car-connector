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

import 'elm327/protocol.dart';

part 'elm327.g.dart';

@JsonSerializable()
class Elm327SensorStatus {
  String adapter = 'unknown';
  String car = 'disconnected';
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
    ble = FlutterReactiveBle();
    conn = ble!.connectToDevice(id: this.config.deviceId!).listen(onConnStateUpdated, onError: onConnError);
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

  void onConnError(dynamic e) {
    setStatus(() {
      status?.adapter = DeviceConnectionState.disconnected.name;
    });
    logger.e('Connection error: $e');
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
      protocol = Elm327Protocol((data) {
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
    setStatus(() {
      status?.car = 'connected';
    });
    scanPIDs();
  }

  List<Value> supportedValues = [];
  Set<String> observedPIDs = {};

  Future<void> scanPIDs() async {
    var availablePids = List.empty(growable: true);
    for (var pid in service1FormulaMap.keys) {
      pid = '01$pid';
      var result = await protocol!.send(pid);
      if (!result.startsWith('NO DATA')) {
        availablePids.add(pid);
      }
    }
    logger.i('Available PIDs: $availablePids');
    supportedValues = [];
    for (var value in values) {
      var supported = true;
      for (var pid in value.mustPIDs) {
        supported |= availablePids.contains(pid);
      }
      for (var pid in value.mustPIDs) {
        supported &= availablePids.contains(pid);
      }
      if (supported) {
        supportedValues.add(value);
      }
    }
    observedPIDs = {};
    for (var value in supportedValues) {
      observedPIDs.addAll(value.mustPIDs.where((element) => availablePids.contains(element)));
      observedPIDs.addAll(value.anyPIDs.where((element) => availablePids.contains(element)));
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
          var r = await readPid(pid);
          if (r != null) {
            results[pid] = r;
          }
        }
        for (var value in supportedValues) {
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

  Future<double?> readPid(String pid) async {
    var s = await protocol!.send(pid);
    if (s.startsWith('NO DATA')) {
      return null;
    }
    var parts = List<String>.empty(growable: true);
    s = s.trim();
    if (s.isEmpty) {
      logger.e('Illegal empty response');
      return 0;
    }
    for (var i = 0; i + 2 <= s.length; i += 2) {
      parts.add(s.substring(i, i+2));
    }
    var formula = service1FormulaMap[parts[1]];
    if (formula == null) {
      logger.e('Formula not defined for PID ${parts[1]}');
      return null;
    }
    var sData = parts.sublist(2);
    var data = Uint8List(sData.length);
    for (var i = 0; i < sData.length; i ++) {
      var b = int.parse(sData[i], radix: 16);
      data[i] = b;
    }
    return formula(data);
  }

  @override
  Future<void> onStop() async {
    running = false;
    timer?.cancel();
    timer = null;
    await readSubscription?.cancel();
    await conn?.cancel();
    ble = null;
    setStatus(() {
      status = Elm327SensorStatus();
    });
  }
}

final values = <Value>[
  TripCalc(), FuelValue(), DistanceSinceCodeCleared(),
];

typedef Service1Formula = double Function(Uint8List data);

double _airFuelRatio(Uint8List data) => (256.0 * data[0] + data[1]) * 2 / 65536;  // lambda

final service1FormulaMap = <String, Service1Formula>{
  '0D': (data) => data[0].toDouble(), // Vehicle speed(km/h)
  '10': (data) => (256.0 * data[0] + data[1]) / 100,  // Air flow rate(g/s)
  '24': _airFuelRatio,
  '25': _airFuelRatio,
  '26': _airFuelRatio,
  '27': _airFuelRatio,
  '28': _airFuelRatio,
  '29': _airFuelRatio,
  '2A': _airFuelRatio,
  '2B': _airFuelRatio,
  '31': (data) => 256.0 * data[0] + data[1],  // Distance since code cleared(km)
  '34': _airFuelRatio,
  '35': _airFuelRatio,
  '36': _airFuelRatio,
  '37': _airFuelRatio,
  '38': _airFuelRatio,
  '39': _airFuelRatio,
  '3A': _airFuelRatio,
  '3B': _airFuelRatio,
  '5E': (data) => (256.0 * data[0] + data[1]) / 20, // Fuel rate(L/h)
  'A6': (data) => (data[0]<<24 + data[1]<<16 + data[2]<<8 + data[3]) / 10 // Odometer
};