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

  @Query('SELECT * FROM RemoteConfig WHERE enabled = 1')
  Future<List<RemoteConfig>> findEnabled();

  @Query('UPDATE RemoteConfig SET enabled = :enabled WHERE id = :id')
  Future<void> setEnabledById(int id, bool enabled);

  @delete
  Future<void> deleteRemoteConfig(RemoteConfig remoteConfig);
}