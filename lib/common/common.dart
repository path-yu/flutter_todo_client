import 'package:flutter/material.dart';
import 'package:todo_client/main.dart';

Future<bool?> showBaseAlertDialog(
    {required Widget contentWidget,
    required String title,
    bool? showCancel = true,
    required Function? onConfirm,
    Function? onClose}) {
  onConfirm ??= () {};
  onClose ??= () {};
  return showDialog(
      context: navigatorKey.currentState!.context,
      builder: (context) {
        List<Widget> actions = [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
              onClose!();
            },
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm!();
              onClose!();
            },
          )
        ];
        if (!showCancel!) {
          actions.removeAt(0);
        }
        return AlertDialog(
          content: contentWidget,
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          actions: actions,
        );
      });
}

const enableReminderKey = 'enableReminderKey';
const reminderTimeKey = 'enableReminderTimeKey';
const reminderTimeTypeIndexKey = 'reminderTimeTypeIndexKey';
