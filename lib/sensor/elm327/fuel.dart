import 'dart:math';

import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class FuelValue extends Value {
  int _lastTime = 0;
  double _lastFuelFlow = 0;
  double value = 0;
  double afr = 0;
  double maf = 0;
  double map = 0, rpm = 0, iat = 0;
  double displacement = 0;
  FuelValue(Map<String, dynamic> config) {
    displacement = config['displacement'] ?? 0;
  }

  @override
  String get status => "AFR: ${afr.toStringAsFixed(2)}   MAF: ${maf.toStringAsFixed(2)}\nMAP: ${map.toStringAsFixed(0)}   RPM: ${rpm.toStringAsFixed(2)}   IAT: ${iat.toStringAsFixed(0)}\nFuelFlow: ${_lastFuelFlow.toStringAsFixed(3)}\nFuelConsumption: ${value.toStringAsFixed(3)}";

  @override
  void clear() {
    _lastTime = 0;
    _lastFuelFlow = 0;
    value = 0;
  }

  @override
  List<String> get anyPIDs => List.from(afrPIDs, growable: true)
      // ..add('015E')  // fuel flow
      ..addAll(mapPIDs)
  ;

  @override
  List<SensorData> get data {
    var data = List<SensorData>.empty(growable: true);
    if (value > 0) {
      data.add(SensorData('trip_fuel_consume_calc', value.toStringAsFixed(3)));
    }
    if (_lastFuelFlow > 0) {
      data.add(SensorData('fuel_flow_calc', _lastFuelFlow.toStringAsFixed(3)));
    }
    return data;
  }

  @override
  List<DiscoveryData> get discovery => [
    DiscoveryData(
        type: 'sensor',
        objectId: 'trip_fuel_consume_calc',
        friendlyName: 'Trip Fuel Consume',
        config: {
          'unit_of_measurement': 'L',
          'device_class': 'volume',
          'state_class': 'total_increasing',
        }
    ),
    DiscoveryData(
        type: 'sensor',
        objectId: 'fuel_flow_calc',
        friendlyName: 'Fuel Flow',
        config: {
          'unit_of_measurement': 'L/h',
        }
    )
  ];

  @override
  void update(Map<String, double> result) {
    double? fuelFlow;
    for (var calculator in fuelFlowCalculators) {
      fuelFlow = calculator(result);
      if (fuelFlow != null) {
        break;
      }
    }
    if (fuelFlow == null) {
      return;
    }
    var time = DateTime.now().millisecondsSinceEpoch;
    if (_lastTime == 0) {
      _lastTime = time;
      _lastFuelFlow = fuelFlow;
      return;
    }
    var dTime = time - _lastTime;
    _lastTime = time;
    var minFuelFlow = min(_lastFuelFlow, fuelFlow);
    var dFuelFlow = (fuelFlow - _lastFuelFlow).abs();
    _lastFuelFlow = fuelFlow;
    if (value.isNaN || value.isInfinite) {
      value = 0;
    }
    value += (minFuelFlow * dTime + dFuelFlow * dTime / 2) / 1000 / 3600;
  }

  List<FuelFlowCalculator> get fuelFlowCalculators => <FuelFlowCalculator>[
    (result) => result['5E'],
    (result) {
      var hasAFR = false;
      for (var pid in afrPIDs) {
        if (result.containsKey(pid)) {
          hasAFR = true;
          break;
        }
      }
      if (hasAFR && result.containsKey('10')) {
        var afr = avgAFR(result);
        if (afr == null) {
          return null;
        }
        this.afr = afr;
        if (afr == 0) {
          return null;
        }
        var maf = result['10'];
        if (maf == null) {
          return null;
        }
        this.maf = maf;
        if (maf == 0) {
          return null;
        }
        var fuelFlow = maf / afr; // g/s
        fuelFlow /= 0.725;  // ml/s
        fuelFlow = fuelFlow * 3600 / 1000; // L/h
        return fuelFlow;
      }
      return null;
    },
    (result) {
      var hasMAP = true;
      for (var pid in mapPIDs) {
        if (!result.containsKey(pid)) {
          hasMAP = false;
          break;
        }
      }
      if (!hasMAP) {
        return null;
      }
      rpm = result['0C']!;
      map = result['0B']!;
      iat = result['0F']!;
      return 0.00774808801 * displacement * rpm * map / (iat + 273.15);
    }
  ];

}

typedef FuelFlowCalculator = double? Function(Map<String, double> result);


List<String> afrPIDs = [
  '24', '25', '26', '27', '28', '29', '2A', '2B',
  '34', '35', '36', '37', '38', '39', '3A', '3B',
  '10',
];

List<String> mapPIDs = ['0B', '0C', '0F'];

double? avgAFR(Map<String, double> result) {
  double lambdaSum = 0;
  int lambdaCount = 0;
  for (var pid in afrPIDs) {
    if (result.containsKey(pid)) {
      var r = result[pid]!;
      if (r == 0) {
        continue;
      }
      lambdaSum += r;
      lambdaCount += 1;
    }
  }
  if (lambdaCount == 0) {
    return null;
  }
  double avgLambda = lambdaSum / lambdaCount;
  return avgLambda * 14.6;
}