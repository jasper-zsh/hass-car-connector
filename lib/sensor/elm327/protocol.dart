import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hass_car_connector/service_locator.dart';
import 'package:logger/logger.dart';

typedef SendFunc = void Function(List<int> data);

class Elm327Protocol {
  final logger = locator<Logger>();
  StreamController<int> rawController = StreamController();
  SendFunc sendFunc;

  StringBuffer responseBuffer = StringBuffer();
  Completer<String>? completer;

  Elm327Protocol(this.sendFunc) {
    rawController.stream.listen((event) {
      var c = String.fromCharCode(event);
      switch (c) {
        case '>': // end of response
          completer?.complete(responseBuffer.toString());
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
}