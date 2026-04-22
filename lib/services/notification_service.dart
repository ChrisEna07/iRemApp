import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Abrir iRememberApp');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'snooze_5') {
          final DateTime now = DateTime.now();
          await scheduleNotification(
            response.id! + 1000, 
            "⏰ POSPUESTO: " + (response.payload ?? "Tarea"),
            "Tu recordatorio se ha movido 5 minutos.",
            now.add(const Duration(minutes: 5)),
            "America/Caracas"
          );
        }
      },
    );

    await _createChannels();
  }

  static Future<void> requestAllPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    }
  }

  static Future<void> _createChannels() async {
    const AndroidNotificationChannel standardChannel = AndroidNotificationChannel(
      'standard_v6', // v6 para asegurar que los nuevos textos de canal se apliquen
      'Notificaciones iRemember',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'alarm_v6', 
      'Alertas Críticas iRemember',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(standardChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);
  }

  static Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_v6',
      'Test iRemember',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
    );
    const linuxDetails = LinuxNotificationDetails(urgency: LinuxNotificationUrgency.critical);
    const details = NotificationDetails(android: androidDetails, linux: linuxDetails);
    await flutterLocalNotificationsPlugin.show(
      999, 
      "🔔 iRemember: ¡Todo en orden!", 
      "Las notificaciones push están activas y sonando correctamente.", 
      details
    );
  }

  static Future<void> showImmediatePush(String title, DateTime scheduledTime) async {
    String formattedTime = DateFormat('hh:mm a').format(scheduledTime);
    
    const androidDetails = AndroidNotificationDetails(
      'standard_v6',
      'Confirmación iRemember',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Agendado',
    );
    const linuxDetails = LinuxNotificationDetails(urgency: LinuxNotificationUrgency.normal);
    const details = NotificationDetails(android: androidDetails, linux: linuxDetails);
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, 
      "✅ Agendado con Éxito", 
      "He guardado '$title' para las $formattedTime. ¡Te avisaré!", 
      details
    );
  }

  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate, String timezone, {String sound = "standard", int anticipationDays = 0}) async {
    
    final location = tz.getLocation(timezone);
    DateTime finalDate = scheduledDate.subtract(Duration(days: anticipationDays));
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(finalDate, location);

    await flutterLocalNotificationsPlugin.cancel(id);

    if (scheduledTZDate.isBefore(tz.TZDateTime.now(location))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          sound == "alarm" ? 'alarm_v6' : 'standard_v6',
          'Avisos Push iRemember',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 2000]),
          actions: [const AndroidNotificationAction('snooze_5', 'POSPONER 5 MIN', showsUserInterface: true)],
          visibility: NotificationVisibility.public,
        ),
        linux: const LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.critical,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: title,
    );
  }
}