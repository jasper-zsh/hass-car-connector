import 'dart:convert';
import 'dart:developer';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/ui/form/mqtt_remote.dart';

typedef void ConfigCallback(Map<String, dynamic> config);

class RemoteConfigForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RemoteConfigFormState();
  }
}

class RemoteConfigFormState extends State<RemoteConfigForm> {
  final saveEvent = Event();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              try {
                saveEvent.broadcast();
              } catch (e) {
                log(e.toString());
              }
            },
          )
        ],
      ),
      body: MqttRemoteConfigForm(
        saveEvent: saveEvent,
        configCallback: (config) async {
          var remoteConfig = RemoteConfig(name: 'foo', type: 'mqtt', config: jsonEncode(config));
          await locator<RemoteService>().saveRemoteConfig(remoteConfig);
          Navigator.pop(context);
        },
      ),
    );
  }
}