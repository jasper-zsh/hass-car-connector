import 'dart:convert';
import 'dart:developer';

import 'package:event/event.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/remote/mqtt.dart';
import 'package:hass_car_connector/remote/remote.dart';
import 'package:hass_car_connector/repositories/remote_config.dart';
import 'package:hass_car_connector/service_locator.dart';

typedef RemoteFactory = Remote Function(Map<String, dynamic> configMap);

var remoteFactorys = <String, RemoteFactory>{
  'mqtt': MqttRemote.new
};

var remoteUpdated = Event();

class RemoteService {
  RemoteConfigRepository remoteConfigRepository;

  RemoteService({required this.remoteConfigRepository});

  Future<List<Remote>> buildAllEnabledRemotes() async {
    var configs = await locator<AppDatabase>().remoteConfigRepository.findEnabled();
    var remotes = List<Remote>.empty(growable: true);
    for (var config in configs) {
      var factory = remoteFactorys[config.type];
      if (factory == null) {
        log("Remote type ${config.type} not registered");
        continue;
      }
      var remote = factory(jsonDecode(config.config));
      remotes.add(remote);
    }
    return remotes;
  }

  Future<void> saveRemoteConfig(RemoteConfig remoteConfig) async {
    if (remoteConfig.id == null) {
      remoteConfig.id = await remoteConfigRepository.insertRemoteConfig(remoteConfig);
    } else {
      await remoteConfigRepository.updateRemoteConfig(remoteConfig);
    }
    remoteUpdated.broadcast();
  }
}