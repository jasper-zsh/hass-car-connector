import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logger/logger.dart';

class ServiceOutput extends LogOutput {
  ServiceInstance? serviceInstance;

  ServiceOutput(this.serviceInstance);

  @override
  void output(OutputEvent event) {
    serviceInstance?.invoke('loggerOutput', {
      'level': event.level.index,
      'lines': event.lines,
    });
  }
}

class UIStreamOutput extends LogOutput {
  late StreamController<List<String>> _controller;
  bool _shouldForward = false;
  ServiceInstance? serviceInstance;

  UIStreamOutput(this.serviceInstance) {
    _controller = StreamController<List<String>>.broadcast(
      onListen: () {
        _shouldForward = _controller.hasListener;
      },
      onCancel: () {
        _shouldForward = _controller.hasListener;
      },
    );
    if (serviceInstance == null) {
      FlutterBackgroundService().on('loggerOutput').listen((event) {
        output(OutputEvent(Level.values[event!['level']], (event['lines'] as List<dynamic>).cast()));
      });
    }
  }

  Stream<List<String>> get stream => _controller.stream;

  @override
  void output(OutputEvent event) {
    if (!_shouldForward) {
      return;
    }

    _controller.add(event.lines);
  }

  @override
  void destroy() {
    _controller.close();
  }
}