import 'package:floor/floor.dart';
import 'package:hass_car_connector/entities/settings.dart';

@dao
abstract class SettingsRepository {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplaceSettings(Settings settings);

  @Query('SELECT * FROM Settings WHERE key = :key')
  Future<Settings?> findByKey(String key);

  @Query('SELECT * FROM Settings')
  Future<List<Settings>> findAll();
}