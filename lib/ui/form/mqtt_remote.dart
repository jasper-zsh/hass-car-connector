import 'package:flutter/material.dart';

class MqttRemoteConfigForm extends StatefulWidget {
  const MqttRemoteConfigForm({super.key});

  @override
  State<StatefulWidget> createState() {
    return MqttRemoteConfigFormState();
  }
}

class MqttRemoteConfigFormState extends State<MqttRemoteConfigForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField(
            decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Scheme"
            ),
            onChanged: (value) {},
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
          ),
          TextFormField(
            decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Port"
            ),
          ),
          TextFormField(
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: "Path",
            ),
          ),
          TextFormField(
            decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Username"
            ),
          ),
          TextFormField(
            decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Password"
            ),
          ),
          TextFormField(
            decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Identifier"
            ),
          )
        ],
      ),
    );
  }
}