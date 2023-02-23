import 'dart:typed_data';

import 'package:hass_car_connector/sensor/elm327/protocol.dart';
import 'package:logger/logger.dart';

void main() {
  var protocol = Elm327Protocol(Logger(), (data) {});
  var offsets = protocol.bitToOffset(Uint8List.fromList([0xBE, 0x3E, 0xB8, 0x11]));
  for (var offset in offsets) {
    print(offset.toRadixString(16));
  }
}