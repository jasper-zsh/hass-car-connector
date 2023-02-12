import 'package:get_it/get_it.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/migrations/v1_v2.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/services/sensor.dart';
import 'package:hass_car_connector/services/settings.dart';

GetIt locator = GetIt.asNewInstance();

Future<void> setupLocator() async {
  locator.registerSingletonAsync<AppDatabase>(dbFactory);
  locator.registerSingletonWithDependencies<RemoteService>(() {
    return RemoteService(
      remoteConfigRepository: locator<AppDatabase>().remoteConfigRepository
    );
  }, dependsOn: [AppDatabase]);
  locator.registerSingletonWithDependencies<SensorService>(() => SensorService(
      sensorConfigRepository: locator<AppDatabase>().sensorConfigRepository
  ), dependsOn: [AppDatabase]);
  locator.registerSingletonWithDependencies(() {
    return SettingsService(locator<AppDatabase>().settingsRepository);
  }, dependsOn: [AppDatabase]);
  await locator.allReady();
}

Future<AppDatabase> dbFactory() async {
  final builder = $FloorAppDatabase.databaseBuilder('hass_car.db');
  builder.addMigrations([
    v1tov2,
  ]);
  return await builder.build();
}