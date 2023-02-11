import 'dart:async';

import 'package:floor/floor.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/repositories/sensor_config.dart';
import 'package:hass_car_connector/repositories/settings.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/entities/settings.dart';
import 'package:hass_car_connector/repositories/remote_config.dart';

part 'database.g.dart';

@Database(version: 2, entities: [RemoteConfig, Settings, SensorConfig])
abstract class AppDatabase extends FloorDatabase {
  RemoteConfigRepository get remoteConfigRepository;
  SettingsRepository get settingsRepository;
  SensorConfigRepository get sensorConfigRepository;
}