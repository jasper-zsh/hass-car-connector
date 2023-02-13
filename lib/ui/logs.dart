import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hass_car_connector/service_locator.dart';
import 'package:hass_car_connector/utils/logger.dart';
import 'package:logger/logger.dart';

class LogsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LogsPageState();
  }
}

class LogsPageState extends State<LogsPage> {
  late StreamSubscription<List<String>> subscription;
  late ScrollController _scrollController;

  List<List<String>> logs = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    subscription = locator<UIStreamOutput>().stream.listen(onLogs);
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  void onLogs(List<String> log) {
    setState(() {
      logs.add(log);
      if (logs.length > 1000) {
        logs.removeAt(0);
      }
      if (_scrollController.position.atEdge) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return Text(logs[index].join('\n'));
      },
    );
  }
}