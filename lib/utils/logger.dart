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
  late StreamController<OutputEvent> _controller;
  List<OutputEvent> buffer = List.empty(growable: true);
  bool _shouldForward = false;
  ServiceInstance? serviceInstance;

  UIStreamOutput(this.serviceInstance) {
    _controller = StreamController<OutputEvent>.broadcast(
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

  StreamSubscription<OutputEvent> listen(void Function(OutputEvent logs) onLogs) {
    var sub = _controller.stream.listen(onLogs);
    for (var event in buffer) {
      _controller.add(event);
    }
    return sub;
  }

  @override
  void output(OutputEvent event) {
    buffer.add(event);
    if (buffer.length > 100) {
      buffer.removeAt(0);
    }
    if (!_shouldForward) {
      return;
    }

    _controller.add(event);
  }

  @override
  void destroy() {
    _controller.close();
  }
}