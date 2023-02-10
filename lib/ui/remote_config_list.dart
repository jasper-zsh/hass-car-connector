import 'package:flutter/material.dart';
import 'package:hass_car_connector/database.dart';
import 'package:hass_car_connector/entities/remote_config.dart';
import 'package:hass_car_connector/service_locator.dart';

class RemoteConfigListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RemoteConfigListPageState();
  }

}

class RemoteConfigListPageState extends State<RemoteConfigListPage> {
  Future<List<RemoteConfig>>? listFuture;

  @override
  void initState() {
    super.initState();
    listFuture = locator<AppDatabase>().remoteConfigRepository.findAll();
  }

  void reload() {
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
        Row(
          children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: remoteConfig.enabled ? ElevatedButton(
              onPressed: () async {
                await locator<AppDatabase>().remoteConfigRepository.setEnabledById(remoteConfig.id!, false);
                reload();
              },
              child: Text('禁用'),
            ) : ElevatedButton(
              onPressed: () async {
                await locator<AppDatabase>().remoteConfigRepository.setEnabledById(remoteConfig.id!, true);
                reload();
              },
              child: Text('启用'),
            ),),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ElevatedButton(
                onPressed: () async {
                  await locator<AppDatabase>().remoteConfigRepository.deleteRemoteConfig(remoteConfig);
                  reload();
                },
                child: Text('删除')
            ),)
          ],
        )
      ],
    );
  }
}