import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/settings.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/ui/popup.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  Map<String, String> settings = {};
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    locator<AppDatabase>().settingsRepository.findAll().then((value) {
      setState(() {
        for (var s in value) {
          settings[s.key] = s.data;
        }
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> updateSetting(String key, String data) async {
    await locator<AppDatabase>().settingsRepository.insertOrReplaceSettings(Settings(key, data));
    setState(() {
      settings[key] = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    var items = [
      Row(
        children: [
          Container(width: 100, child: Text('车辆标识')),
          Expanded(child: Text(settings[carIdentifier] ?? '未设置'))
        ],
      ),
      TextButton(onPressed: () async {
        await Geolocator.requestPermission();
      }, child: Text('请求权限'))
    ];
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          showPrompt(
            context: context,
            controller: _promptController,
            title: '设置 车辆标识',
            initial: settings[carIdentifier] ?? '',
            callback: (value) async {
              updateSetting(carIdentifier, value);
            }
          );
        },
        child: Padding(padding: EdgeInsets.all(8), child: items[index],),
      ),
    );
  }
}