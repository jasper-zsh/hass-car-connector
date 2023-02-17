import 'dart:convert';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hass_car_connector/sensor/elm327.dart';
import 'package:hass_car_connector/ui/ble_scanner.dart';
import 'package:hass_car_connector/ui/sensor_config_form.dart';

class Elm327SensorConfigForm extends StatefulWidget {
  Map<String, dynamic>? config;
  Event<SaveEventArgs>? saveEvent;

  Elm327SensorConfigForm({this.config, this.saveEvent});

  @override
  State<StatefulWidget> createState() {
    return Elm327SensorConfigFormState();
  }
}

class Elm327SensorConfigFormState extends State<Elm327SensorConfigForm> {
  final _formKey = GlobalKey<FormState>();

  late Elm327SensorConfig config;
  late TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController();

    if (widget.config != null) {
      config = Elm327SensorConfig.fromJson(widget.config!);
    } else {
      config = Elm327SensorConfig();
    }
    _deviceNameController.text = config.deviceName ?? '';
    widget.saveEvent?.subscribe(onSave);
  }

  @override
  void didUpdateWidget(covariant Elm327SensorConfigForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.saveEvent?.unsubscribe(onSave);
    widget.saveEvent?.subscribe(onSave);
  }

  @override
  void dispose() {
    super.dispose();
    _deviceNameController.dispose();
    widget.saveEvent?.unsubscribe(onSave);
  }

  void onSave(SaveEventArgs? args) {
    args?.configCallback(config.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push<DiscoveredDevice>(context, MaterialPageRoute(builder: (context) {
                return BleScanner(
                  onDeviceSelected: (device) {
                    setState(() {
                      config.deviceName = device.name;
                      config.deviceId = device.id;
                      _deviceNameController.text = device.name;
                    });
                  },
                );
              }));
            },
            child: TextFormField(
              decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Device'
              ),
              controller: _deviceNameController,
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }
}