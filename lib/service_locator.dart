import 'package:get_it/get_it.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/services/remote.dart';

GetIt locator = GetIt.asNewInstance();

Future<void> setupLocator() async {
  locator.registerSingletonAsync<AppDatabase>(dbFactory);
  locator.registerSingletonWithDependencies<RemoteService>(() {
    return RemoteService(
      remoteConfigRepository: locator<AppDatabase>().remoteConfigRepository
    );
  }, dependsOn: [AppDatabase]);
  await locator.allReady();
}

Future<AppDatabase> dbFactory() async {
  final builder = $FloorAppDatabase.databaseBuilder('hass_car.db');
  return await builder.build();
}