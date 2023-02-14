import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hass_car_connector/sensor/sensor.dart';
import 'package:hass_car_connector/sensor/system.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:logger/logger.dart';

class SystemSensorStatusWidget extends StatefulWidget {
  Sensor sensor;

  SystemSensorStatusWidget(this.sensor);

  @override
  State<StatefulWidget> createState() {
    return SystemSensorStatusState();
  }
}

class SystemSensorStatusState extends State<SystemSensorStatusWidget> {
  final logger = locator<Logger>();
  late StreamSubscription<Map<String, dynamic>> statusSubscription;

  SystemSensorStatus? status;

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
      this.status = SystemSensorStatus.fromJson(status);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Center(
        child: Text('Status unknown'),
      );
    }
    return Column(
      children: [
        Text("Location status: ${status!.locationStatus}"),
      ],
    );
  }
}