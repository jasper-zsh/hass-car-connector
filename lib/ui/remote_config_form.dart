import 'dart:convert';
import 'dart:developer';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
  final _formKey = GlobalKey<FormState>();

  late Map<String, dynamic> config;
  late String name;

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
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Name'
                  ),
                  onSaved: (value) {
                    setState(() {
                      name = value!;
                    });
                  },
                )
              ],
            )
          ),
          Expanded(child: MqttRemoteConfigForm(
            saveEvent: saveEvent,
            configCallback: (config) async {
              this.config = config;
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                var remoteConfig = RemoteConfig(name: name, type: 'mqtt', config: jsonEncode(this.config));
                await locator<RemoteService>().saveRemoteConfig(remoteConfig);
                remoteUpdated.broadcast();
                Navigator.pop(context);
              }
            },
          ))
        ],
      ),
    );
  }
}