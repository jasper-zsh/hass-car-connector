import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/repositories/remote_config.dart';

part 'database.g.dart';

@Database(version: 1, entities: [RemoteConfig])
abstract class AppDatabase extends FloorDatabase {
  RemoteConfigRepository get remoteConfigRepository;
}