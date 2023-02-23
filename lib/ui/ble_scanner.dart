import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

typedef DeviceCallback = void Function(BluetoothDevice device);

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
  final blue = FlutterBluePlus.instance;

  Map<String, BluetoothDevice> devices = {};
  StreamSubscription<List<ScanResult>>? scanSubscription;

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
    setState(() {
      devices = {};
    });
    blue.startScan(timeout: const Duration(seconds: 5));
    scanSubscription = blue.scanResults.listen((event) {
      for (var r in event) {
        setState(() {
          devices[r.device.id.id] = r.device;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    scanSubscription?.cancel();
    blue.stopScan();
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

  Widget _buildItem(BuildContext context, BluetoothDevice device) {
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
                Text(device.name.isNotEmpty ? device.name : '_NONAME_'),
                Text(device.id.id),
              ],
            ))
          ],
        ),
      ),
    );
  }
}