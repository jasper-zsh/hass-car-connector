import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hass_car_connector/sensor/elm327.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/sensor/system.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:logger/logger.dart';

class Elm327SensorStatusWidget extends StatefulWidget {
  Sensor sensor;

  Elm327SensorStatusWidget(this.sensor);

  @override
  State<StatefulWidget> createState() {
    return Elm327SensorStatusState();
  }
}

class Elm327SensorStatusState extends State<Elm327SensorStatusWidget> {
  final logger = locator<Logger>();
  late StreamSubscription<Map<String, dynamic>> statusSubscription;

  Elm327SensorStatus? status;

  @override
  void initState() {
    super.initState();
    statusSubscription = widget.sensor.getStatusStream().listen(onStatus, onError: (e) {
      logger.e('Failed to listen sensor status. $e');
    }, onDone: () {
      logger.i('Sensor status listen done.');
    });
  }

  @override
  void dispose() {
    super.dispose();
    statusSubscription.cancel();
  }

  void onStatus(Map<String, dynamic> status) {
    setState(() {
      this.status = Elm327SensorStatus.fromJson(status);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const Center(
        child: Text('Status unknown'),
      );
    }
    var children = [
      Text("Adapter: ${status!.adapter}"),
      Text('Car: ${status?.car}'),
      Text('Observed PIDs: ${status?.observedPIDs.join(',')}')
    ];
    if (status != null) {
      for (var e in status!.valueStatuses.entries) {
        children.add(Text("${e.key}: ${e.value}"));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}