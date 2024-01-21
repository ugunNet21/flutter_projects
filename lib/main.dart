import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: HomeScreen(),
    );
  }
}

Future<FlutterLocalNotificationsPlugin> initializeNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  return flutterLocalNotificationsPlugin;
}

class HomeScreen extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final GetStorage box = GetStorage();
  final RxBool isScheduled = true.obs;

  HomeScreen({super.key});
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }


  @override
  Widget build(BuildContext context) {
    initializeLocalNotifications();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notification Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Switch(
                  value: isScheduled.value,
                  onChanged: (value) {
                    isScheduled.value = value;
                    if (value) {
                      scheduleNotification();
                    } else {
                      cancelNotification();
                    }
                  },
                )),
            ElevatedButton(
              onPressed: () => showNotification(),
              child: const Text('Show Notification Now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> scheduleNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    if (isScheduled.value) {
      final DateTime now = DateTime.now();
      final DateTime scheduledDate =
          DateTime(now.year, now.month, now.day, 11, 0, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate.add(const Duration(days: 1));
      }

      final int uniqueId = Random().nextInt(100000);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        uniqueId,
        'Scheduled Notification',
        'This is a scheduled notification',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_channel',
            'Scheduled Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      box.write('scheduledDate', scheduledDate.toIso8601String());
    }
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    box.remove('scheduledDate');
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scheduled_channel',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Immediate Notification',
      'This is an immediate notification',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}