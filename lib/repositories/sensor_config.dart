import 'package:floor/floor.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';

@dao
abstract class SensorConfigRepository {
  @Query('SELECT * FROM SensorConfig')
  Future<List<SensorConfig>> findAll();

  @Query('SELECT * FROM SensorConfig WHERE enabled = 1')
  Future<List<SensorConfig>> findEnabled();

  @insert
  Future<int> insertSensorConfig(SensorConfig sensorConfig);

  @update
  Future<void> updateSensorConfig(SensorConfig sensorConfig);

  @delete
  Future<void> deleteSensorConfig(SensorConfig sensorConfig);

  @Query('UPDATE SensorConfig SET enabled = :enabled WHERE id = :id')
  Future<void> setEnabledById(int id, bool enabled);
}