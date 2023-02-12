import 'dart:convert';
import 'dart:developer';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/remote/mqtt.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/ui/form/mqtt_remote.dart';

typedef void ConfigCallback(Map<String, dynamic> config);

class SaveEventArgs extends EventArgs {
  ConfigCallback configCallback;

  SaveEventArgs(this.configCallback);
}

class RemoteConfigForm extends StatefulWidget {
  RemoteConfig remoteConfig;

  RemoteConfigForm({super.key, required this.remoteConfig});

  @override
  State<StatefulWidget> createState() {
    return RemoteConfigFormState(remoteConfig);
  }
}

class RemoteConfigFormState extends State<RemoteConfigForm> {
  final saveEvent = Event<SaveEventArgs>();
  final _formKey = GlobalKey<FormState>();

  RemoteConfig remoteConfig;
  Map<String, dynamic> config;
  late String name;
  bool? testPassed;
  bool testing = false;

  RemoteConfigFormState(this.remoteConfig): config = {} {
    if (remoteConfig.config.isNotEmpty) {
      config = jsonDecode(remoteConfig.config);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _buildTestButton(BuildContext context) {
    if (testing) {
      return IconButton(onPressed: test, icon: Icon(Icons.running_with_errors));
    }
    switch (testPassed) {
      case true:
        return IconButton(onPressed: test, icon: Icon(Icons.check_rounded));
      case false:
        return IconButton(onPressed: test, icon: Icon(Icons.close_rounded));
      default:
        return IconButton(onPressed: test, icon: Icon(Icons.flash_on));
    }
  }

  void test() async {
    saveEvent.broadcast(SaveEventArgs((config) async {
      var remote = MqttRemote();
      try {
        setState(() {
          testing = true;
        });
        await remote.init(config);
        await remote.start();
        await remote.stop();
        setState(() {
          testPassed = true;
          testing = false;
        });
      } catch (e) {
        setState(() {
          testPassed = false;
          testing = false;
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          _buildTestButton(context),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              try {
                saveEvent.broadcast(SaveEventArgs((config) async {
                  this.config = config;
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    var remoteConfig = RemoteConfig(name: name, type: 'mqtt', config: jsonEncode(this.config));
                    await locator<RemoteService>().saveRemoteConfig(remoteConfig);
                    remoteUpdated.broadcast();
                    Navigator.pop(context);
                  }
                },
                ));
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
                  initialValue: remoteConfig.name,
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
            config: config,
          ))
        ],
      ),
    );
  }
}