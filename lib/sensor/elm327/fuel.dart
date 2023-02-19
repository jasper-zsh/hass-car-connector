import 'dart:math';

import 'package:hass_car_connector/sensor/elm327/value.dart';
import 'package:hass_car_connector/sensor/sensor.dart';

class FuelValue extends Value {
  int _lastTime = 0;
  double _lastFuelFlow = 0;
  double value = 0;
  double afr = 0;
  double mas = 0;

  @override
  String get status => "AFR: ${afr.toStringAsFixed(2)}   MAS: ${mas.toStringAsFixed(2)}   FuelFlow: ${_lastFuelFlow.toStringAsFixed(3)}   FuelConsumption: ${value.toStringAsFixed(3)}";

  @override
  void clear() {
    _lastTime = 0;
    _lastFuelFlow = 0;
    value = 0;
  }

  List<String> afrPIDs = [
    '0124', '0125', '0126', '0127', '0128', '0129', '012A', '012B',
    '0134', '0135', '0136', '0137', '0138', '0139', '013A', '013B',
  ];

  @override
  List<String> get anyPIDs => List.from(afrPIDs, growable: true)
      ..add('0110') // air flow
      // ..add('015E')  // fuel flow
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
    var fuelFlow = result['015E'];  // L/h
    if (fuelFlow == null) {
      var afr = avgAFR(result);
      if (afr == null) {
        return;
      }
      this.afr = afr;
      var mas = result['0110'];
      if (mas == null) {
        return;
      }
      this.mas = mas;
      fuelFlow = mas / afr; // g/s
      fuelFlow /= 0.725;  // ml/s
      fuelFlow = fuelFlow * 3600 / 1000; // L/h
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

}