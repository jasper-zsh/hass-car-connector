import 'package:floor/floor.dart';

final v1tov2 = Migration(1, 2, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `SensorConfig` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `type` TEXT NOT NULL, `name` TEXT, `config` TEXT NOT NULL, `enabled` INTEGER NOT NULL)');
});