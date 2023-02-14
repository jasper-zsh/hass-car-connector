import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/entities/sensor_config.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/services/sensor.dart';
import 'package:hass_car_connector/ui/sensor_config_form.dart';
import 'package:hass_car_connector/ui/sensor_status.dart';

class SensorConfigListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SensorConfigListPageState();
  }

}

class SensorConfigListPageState extends State<SensorConfigListPage> {
  Future<List<SensorConfig>>? listFuture;
  Event<SaveEventArgs> saveEvent = Event();

  @override
  void initState() {
    super.initState();
    listFuture = locator<AppDatabase>().sensorConfigRepository.findAll();
    sensorUpdated.subscribe(_reload);
  }

  @override
  void dispose() {
    sensorUpdated.unsubscribe(_reload);
    super.dispose();
  }

  void _reload(EventArgs? args) {
    setState(() {
      listFuture = locator<AppDatabase>().sensorConfigRepository.findAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: listFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Text("Loading..."),
          );
        }
        return ListView.separated(
          separatorBuilder: (context, index) {
            return Divider();
          },
          itemCount: snapshot.requireData.length,
          itemBuilder: (context, index) {
            return _buildItem(context, snapshot.requireData[index]);
          },
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, SensorConfig sensorConfig) {
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sensorConfig.name ?? '')
          ],
        )),
        ButtonBar(
          children: [
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SensorStatusPage(sensorConfig);
              }));
            }, child: Text('状态')),
            sensorConfig.enabled ? ElevatedButton(
              onPressed: () async {
                await locator<AppDatabase>().sensorConfigRepository.setEnabledById(sensorConfig.id!, false);
                sensorUpdated.broadcast();
              },
              child: Text('禁用'),
            ) : ElevatedButton(
              onPressed: () async {
                await locator<AppDatabase>().sensorConfigRepository.setEnabledById(sensorConfig.id!, true);
                sensorUpdated.broadcast();
              },
              child: Text('启用'),
            ),
            ElevatedButton(
                onPressed: () async {
                  await locator<AppDatabase>().sensorConfigRepository.deleteSensorConfig(sensorConfig);
                  sensorUpdated.broadcast();
                },
                child: Text('删除')
            ),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SensorConfigForm(
                  sensorConfig: sensorConfig,
                );
              }));
            }, child: Text('编辑'))
          ],
        )
      ],
    );
  }
}