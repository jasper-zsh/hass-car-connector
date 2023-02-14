import 'package:flutter/services.dart';

class Utils {
  static const methodChannel = MethodChannel('tech.ztimes.hass.car');

  static Future<void> minimize() async {
    await methodChannel.invokeMethod('minimize');
  }
}