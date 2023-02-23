import 'package:flutter/material.dart';

typedef void StringCallback(String value);

_emptyCallback(String value) {}

Future<void> showPrompt({
  required BuildContext context,
  required TextEditingController controller,
  required String title,
  String initial = '',
  StringCallback callback = _emptyCallback
}) async {
  controller.text = initial;
  await showDialog(context: context, builder: (context) => AlertDialog(
    title: Text(title),
    content: TextField(
      controller: controller,
      decoration: const InputDecoration(
        border: UnderlineInputBorder()
      ),
    ),
    actions: [
      TextButton(onPressed: () {
        callback(controller.text);
        Navigator.pop(context);
      }, child: const Text('确定'))
    ],
  ));
  controller.clear();
}

Future<void> showAlert({
  required BuildContext context,
  required String title,
  required String content
}) async {
  await showDialog(context: context, builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(onPressed: () {
        Navigator.pop(context);
      }, child: const Text('确定'))
    ],
  ));
}