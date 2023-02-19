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
  late StreamSubscription<OutputEvent> subscription;
  late ScrollController _scrollController;

  List<OutputEvent> logs = List.empty(growable: true);
  var autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    subscription = locator<UIStreamOutput>().listen(onLogs);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    subscription.cancel();
  }

  void onLogs(OutputEvent log) {
    setState(() {
      logs.add(log);
      if (logs.length > 1000) {
        logs.removeAt(0);
      }
      if (autoScroll) {
        Timer(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(logs[index].level.name),
            Text(logs[index].lines.join('\n'))
          ],
        );
      },
    );
  }
}