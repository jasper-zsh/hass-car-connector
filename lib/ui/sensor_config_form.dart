import 'dart:convert';
import 'dart:developer';

import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/remote/mqtt.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/services/sensor.dart';
import 'package:hass_car_connector/ui/form/elm327_sensor.dart';
import 'package:hass_car_connector/ui/form/mqtt_remote.dart';

typedef void ConfigCallback(Map<String, dynamic> config);

class SaveEventArgs extends EventArgs {
  ConfigCallback configCallback;

  SaveEventArgs(this.configCallback);
}

class SensorConfigForm extends StatefulWidget {
  SensorConfig sensorConfig;

  SensorConfigForm({super.key, required this.sensorConfig});

  @override
  State<StatefulWidget> createState() {
    return SensorConfigFormState(sensorConfig);
  }
}

class SensorConfigFormState extends State<SensorConfigForm> {
  final saveEvent = Event<SaveEventArgs>();
  final _formKey = GlobalKey<FormState>();

  SensorConfig sensorConfig;
  Map<String, dynamic> config;
  late String name;
  bool? testPassed;
  bool testing = false;
  TextEditingController? _nameController;

  SensorConfigFormState(this.sensorConfig): config = {} {
    if (sensorConfig.config.isNotEmpty) {
      config = jsonDecode(sensorConfig.config);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _nameController?.dispose();
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
            onPressed: () async {
              try {
                saveEvent.broadcast(SaveEventArgs((config) async {
                  this.config = config;
                  sensorConfig.config = jsonEncode(config);
                }));

                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  await locator<SensorService>().saveSensorConfig(sensorConfig);
                  Navigator.pop(context);
                }
              } catch (e) {
                log(e.toString());
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
                      initialValue: sensorConfig.name,
                      onSaved: (value) {
                        setState(() {
                          sensorConfig.name = value!;
                        });
                      },
                    ),
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        border: UnderlineInputBorder()
                      ),
                      items: [
                        DropdownMenuItem(child: Text('ELM327'), value: 'elm327',),
                        DropdownMenuItem(child: Text('System'), value: 'system',),
                        DropdownMenuItem(child: Text('Dummy'), value: 'dummy',)
                      ],
                      onChanged: (value) {
                        setState(() {
                          sensorConfig.type = value!;
                          config = {};
                        });
                      }
                    )
                  ],
                )
            ),
            _buildRemoteConfigForm(context)
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteConfigForm(BuildContext context) {
    switch (sensorConfig.type) {
      case 'elm327':
        return Elm327SensorConfigForm(config: config, saveEvent: saveEvent);
      default:
        return Container();
    }
  }
}