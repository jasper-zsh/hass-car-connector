import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/repositories/settings.dart';
import 'package:hass_car_connector/service_locator.dart';

class SettingsService {
  SettingsRepository settingsRepository;

  SettingsService(this.settingsRepository);

  Future<String> readSetting(String key) async {
    var s = await settingsRepository.findByKey(key);
    if (s == null) {
      return '';
    }
    return s.data;
  }
}