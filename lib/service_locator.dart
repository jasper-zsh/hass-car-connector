import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/migrations/v1_v2.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/services/sensor.dart';
import 'package:hass_car_connector/services/settings.dart';
import 'package:hass_car_connector/utils/logger.dart';
import 'package:logger/logger.dart';

GetIt locator = GetIt.asNewInstance();

Future<void> setupLocator(ServiceInstance? serviceInstance) async {
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
  locator.registerSingleton<UIStreamOutput>(UIStreamOutput(serviceInstance));
  locator.registerSingleton<Logger>(Logger(
      output: MultiOutput([
        ServiceOutput(serviceInstance),
        locator<UIStreamOutput>(),
        ConsoleOutput()
      ]),
    printer: PrettyPrinter(
      colors: false,
      lineLength: 80
    )
  ));
  await locator.allReady();
}

Future<AppDatabase> dbFactory() async {
  final builder = $FloorAppDatabase.databaseBuilder('hass_car.db');
  builder.addMigrations([
    v1tov2,
  ]);
  return await builder.build();
}