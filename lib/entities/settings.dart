
import 'package:floor/floor.dart';

const carIdentifier = 'car_identifier';

@entity
class Settings {
  @primaryKey
  String key;
  String data;

  Settings(this.key, this.data);
}