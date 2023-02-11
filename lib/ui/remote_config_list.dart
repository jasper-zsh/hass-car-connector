import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/services/remote.dart';
import 'package:hass_car_connector/ui/form/mqtt_remote.dart';
import 'package:hass_car_connector/ui/remote_config_form.dart';

class RemoteConfigListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RemoteConfigListPageState();
  }

}

class RemoteConfigListPageState extends State<RemoteConfigListPage> {
  Future<List<RemoteConfig>>? listFuture;
  Event<SaveEventArgs> saveEvent = Event();

  @override
  void initState() {
    super.initState();
    listFuture = locator<AppDatabase>().remoteConfigRepository.findAll();
    remoteUpdated.subscribe(_reload);
  }

  @override
  void dispose() {
    remoteUpdated.unsubscribe(_reload);
    super.dispose();
  }

  void _reload(EventArgs? args) {
    setState(() {
      listFuture = locator<AppDatabase>().remoteConfigRepository.findAll();
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

  Widget _buildItem(BuildContext context, RemoteConfig remoteConfig) {
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(remoteConfig.name)
          ],
        )),
        ButtonBar(
          children: [
            remoteConfig.enabled ? ElevatedButton(
              onPressed: () async {
                await locator<AppDatabase>().remoteConfigRepository.setEnabledById(remoteConfig.id!, false);
                remoteUpdated.broadcast();
              },
              child: Text('禁用'),
            ) : ElevatedButton(
              onPressed: () async {
                await locator<AppDatabase>().remoteConfigRepository.setEnabledById(remoteConfig.id!, true);
                remoteUpdated.broadcast();
              },
              child: Text('启用'),
            ),
            ElevatedButton(
                onPressed: () async {
                  await locator<AppDatabase>().remoteConfigRepository.deleteRemoteConfig(remoteConfig);
                  remoteUpdated.broadcast();
                },
                child: Text('删除')
            ),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return RemoteConfigForm(
                  remoteConfig: remoteConfig,
                );
              }));
            }, child: Text('编辑'))
          ],
        )
      ],
    );
  }
}