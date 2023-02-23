import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hass_car_connector/service_locator.dart';
import 'package:logger/logger.dart';

typedef SendFunc = void Function(List<int> data);

class Elm327Protocol {
  Logger logger;
  StreamController<int> rawController = StreamController();
  SendFunc sendFunc;

  StringBuffer responseBuffer = StringBuffer();
  Completer<String>? completer;

  Elm327Protocol(this.logger, this.sendFunc) {
    rawController.stream.listen((event) {
      var c = String.fromCharCode(event);
      switch (c) {
        case '>': // end of response
          completer?.complete(responseBuffer.toString());
          completer = null;
          responseBuffer.clear();
          break;
        case '\r':  // new line
          // responseBuffer.write('\n');
          break;
        default:
          responseBuffer.write(c);
          break;
      }
    });
  }

  void receive(List<int> data) {
    for (var b in data) {
      rawController.add(b);
    }
  }

  Future<String> send(String data) async {
    completer = Completer();
    var raw = List<int>.from(utf8.encode(data))..add(0x0D);
    sendFunc(raw);
    var res = await completer!.future;
    logger.i('Data: $res');
    return res;
  }

  List<int> bitToOffset(Uint8List data) {
    var result = List<int>.empty(growable: true);
    for (var i = 0; i < data.length; i ++) {
      for (var j = 0; j < 8; j ++) {
        var mask = 1.toUnsigned(8) << (7 - j);
        if (data[i] & mask > 0) {
          result.add(i * 8 + j + 1);
        }
      }
    }
    return result;
  }

  Future<List<String>> service1Available() async {
    List<String> availablePIDs = ['00'];
    try {
      for (var i = 0x00; i < 0xFF; i += 0x20) {
        var cmd = i.toRadixString(16);
        if (cmd.length == 1) {
          cmd = '0$cmd';
        }
        if (!availablePIDs.contains(cmd)) {
          break;
        }
        var res = await requestService1(cmd);
        var offsets = bitToOffset(res);
        for (var offset in offsets) {
          var pid = (i + offset).toRadixString(16);
          if (pid.length == 1) {
            pid = '0$pid';
          }
          availablePIDs.add(pid.toUpperCase());
        }
      }
    } catch (e) {
      logger.i('PID sniff end: $e');
    }
    availablePIDs.sort();
    return availablePIDs;
  }

  Future<Uint8List> requestService1(String pid) async {
    var res = await send('01$pid');
    res = res.trim();
    if (!res.startsWith('41')) {
      throw Exception('Illegal response: $res');
    }
    var parts = List<String>.empty(growable: true);
    for (var i = 0; i + 2 <= res.length; i += 2) {
      parts.add(res.substring(i, i+2));
    }
    if (parts[1] != pid) {
      throw Exception('Response not match: expected $pid got ${parts[1]}');
    }
    var sData = parts.sublist(2);
    var data = Uint8List(sData.length);
    for (var i = 0; i < sData.length; i ++) {
      var b = int.parse(sData[i], radix: 16);
      data[i] = b;
    }
    return data;
  }

  Future<double> requestService1Value(String pid) async {
    var formula = service1FormulaMap[pid];
    if (formula == null) {
      throw Exception('Formula not defined for PID $pid');
    }
    var res = await requestService1(pid);

    return formula(res);
  }
}


typedef Service1Formula = double Function(Uint8List data);

double _airFuelRatio(Uint8List data) => (256.0 * data[0] + data[1]) * 2 / 65536;  // lambda

final service1FormulaMap = <String, Service1Formula>{
  '0B': (data) => data[0].toDouble(), // Intake manifold absolute pressure(MAP) (kPa)
  '0C': (data) => (256.0 * data[0] + data[1]) / 4,  // Engine speed(rpm)
  '0D': (data) => data[0].toDouble(), // Vehicle speed(km/h)
  '0F': (data) => data[0] - 40,   // Intake air temperature(°C)
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