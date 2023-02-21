import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

typedef DeviceCallback = void Function(DiscoveredDevice device);

class BleScanner extends StatefulWidget {
  DeviceCallback? onDeviceSelected;

  BleScanner({
    this.onDeviceSelected
  });

  @override
  State<StatefulWidget> createState() {
    return BleScannerState();
  }
}

class BleScannerState extends State<BleScanner> {
  final ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? deviceSubscription;
  Map<String, DiscoveredDevice> devices = {};

  @override
  void initState() {
    super.initState();
    scan();
  }

  void scan() async {
    if (!await Permission.bluetoothScan.request().isGranted) {
      return;
    }
    if (!await Permission.bluetoothConnect.request().isGranted) {
      return;
    }
    if (!await Permission.location.request().isGranted) {
      return;
    }
    await deviceSubscription?.cancel();
    setState(() {
      devices = {};
    });
    deviceSubscription = ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((event) {
      setState(() {
        devices[event.id] = event;
      });
    }, onError: (e) {
      log('Scan failed: $e');
    });
  }

  @override
  void dispose() {
    super.dispose();
    deviceSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Scanner'),
      ),
      body: ListView.separated(
        itemCount: devices.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) => _buildItem(context, devices.values.elementAt(index)),
      ),
    );
  }

  Widget _buildItem(BuildContext context, DiscoveredDevice device) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.onDeviceSelected != null) {
          widget.onDeviceSelected!(device);
        }
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name),
                Text(device.id)
              ],
            ))
          ],
        ),
      ),
    );
  }
}