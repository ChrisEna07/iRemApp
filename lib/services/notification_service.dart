import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'snooze_5') {
          final DateTime now = DateTime.now();
          await scheduleNotification(
            response.id! + 1000, 
            "RECORDASTE: " + (response.payload ?? "Tarea"),
            "Pospuesto 5 minutos",
            now.add(const Duration(minutes: 5)),
            "America/Caracas"
          );
        }
      },
    );

    _createChannels();
    _scheduleHourlyReminder();
  }

  static Future<void> _createChannels() async {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(const AndroidNotificationChannel('standard_channel', 'Sonido Estándar', importance: Importance.high));
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(const AndroidNotificationChannel('alarm_channel', 'Sonido Alarma', importance: Importance.max, playSound: true));
  }

  static Future<void> _scheduleHourlyReminder() async {
    await flutterLocalNotificationsPlugin.periodicallyShow(888, '¿Algo que anotar?', 'Recuerda registrar tus actividades.', RepeatInterval.hourly, const NotificationDetails(android: AndroidNotificationDetails('standard_channel', 'Recordatorios')), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }

  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate, String timezone, {String sound = "standard", int anticipationDays = 0}) async {
    
    final location = tz.getLocation(timezone);
    
    // Ajustar por días de anticipación
    DateTime finalDate = scheduledDate.subtract(Duration(days: anticipationDays));
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(finalDate, location);

    // IMPORTANTE: Cancelar cualquier notificación previa con este ID para asegurar la actualización
    await flutterLocalNotificationsPlugin.cancel(id);

    if (scheduledTZDate.isBefore(tz.TZDateTime.now(location))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          sound == "alarm" ? 'alarm_channel' : 'standard_channel',
          'Recordatorios',
          importance: sound == "alarm" ? Importance.max : Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 1000]),
          actions: [const AndroidNotificationAction('snooze_5', 'POSPONER 5 MIN', showsUserInterface: true)],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: title,
    );
  }
}