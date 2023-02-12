import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:event/event.dart';
import 'package:hass_car_connector/remote/mqtt.dart';
import 'package:hass_car_connector/ui/remote_config_form.dart';

class MqttRemoteConfigForm extends StatefulWidget {
  final Event<SaveEventArgs> saveEvent;
  final Map<String, dynamic>? config;

  const MqttRemoteConfigForm({super.key, required this.saveEvent, this.config});

  @override
  State<StatefulWidget> createState() {
    return MqttRemoteConfigFormState(config == null ? MqttRemoteConfig() : MqttRemoteConfig.fromJson(config!));
  }
}

class MqttRemoteConfigFormState extends State<MqttRemoteConfigForm> {
  final _formKey = GlobalKey<FormState>();
  MqttRemoteConfig config;

  MqttRemoteConfigFormState(this.config);

  @override
  void initState() {
    super.initState();
    widget.saveEvent.subscribe(onSave);
  }

  @override
  void dispose() {
    super.dispose();
    widget.saveEvent.unsubscribe(onSave);
  }

  onSave(SaveEventArgs? args) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (args?.configCallback != null) {
        args!.configCallback(config.toJson());
      }
    } else {
      throw Exception('validate failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    var fields = [
      DropdownButtonFormField(
        decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Scheme"
        ),
        onChanged: (value) {},
        validator: (value) {
          if (value == null) {
            return 'Please select scheme';
          }
        },
        value: config.scheme,
        onSaved: (value) {
          config.scheme = value;
        },
        items: ['ws', 'wss'].map((e) => DropdownMenuItem<String>(
          value: e,
          child: Text(e),
        )).toList(),
      ),
      TextFormField(
        decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Host"
        ),
        initialValue: config.host,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please input host';
          }
        },
        onSaved: (value) {
          config.host = value;
        },
      ),
      TextFormField(
        decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Port"
        ),
        initialValue: config.port?.toString(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please input port';
          }
        },
        onSaved: (value) {
          config.port = int.parse(value!);
        },
      ),
      TextFormField(
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: "Path",
        ),
        initialValue: config.path,
        validator: (value) {
          if (value != null && value.isNotEmpty && !value.startsWith('/')) {
            return 'Path must be empty or starts with /';
          }
        },
        onSaved: (value) {
          config.path = value;
        },
      ),
      TextFormField(
        decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Username"
        ),
        initialValue: config.username,
        onSaved: (value) {
          config.username = value;
        },
      ),
      TextFormField(
        decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: "Password",
        ),
        obscureText: true,
        enableIMEPersonalizedLearning: false,
        enableSuggestions: false,
        initialValue: config.password,
        onSaved: (value) {
          config.password = value;
        },
      ),
    ];
    return Form(
      key: _formKey,
      child: ListView.builder(itemBuilder: (context, index) => fields[index], itemCount: fields.length,),
    );
  }
}