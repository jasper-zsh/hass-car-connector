import 'package:floor/floor.dart';
import 'package:hass_car_connector/entities/remote_config.dart';

@dao
abstract class RemoteConfigRepository {
  @insert
  Future<int> insertRemoteConfig(RemoteConfig remoteConfig);

  @update
  Future<void> updateRemoteConfig(RemoteConfig remoteConfig);

  @Query('SELECT * FROM RemoteConfig')
  Future<List<RemoteConfig>> findAll();

  @Query('SELECT * FROM RemoteConfig WHERE enabled = true')
  Future<List<RemoteConfig>> findEnabled();
}