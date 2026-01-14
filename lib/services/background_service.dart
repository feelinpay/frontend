import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/local_database.dart';
import '../services/session_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  // ignore: unused_field
  static Timer? _serviceTimer;

  // Iniciar el servicio
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    /// OPTIONAL, using custom notification channel id
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'feelin_pay_foreground', // id
      'Feelin Pay Service', // title
      description:
          'This channel is used for important background notifications.',
      importance: Importance.low, // Low importance to avoid sound
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed when app is in foreground or background in separated isolate
        onStart: onStart,

        // auto start service
        autoStart: true,
        isForegroundMode: true,

        notificationChannelId: 'feelin_pay_foreground',
        initialNotificationTitle: 'Feelin Pay',
        initialNotificationContent: 'El servicio está activo y escuchando.',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,

        // this will be executed when app is in foreground in separated isolate
        onForeground: onStart,

        // you have to enable background fetch capability on xcode project
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // For flutter prior to 3.0.0
    // We have to register the plugin manually

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Bring up database and other services needed in isolate
    // Note: Depends on how your dependencies are set up.
    // Ideally, we re-initialize essential singletons here.

    debugPrint('🔄 [Background] Service started');

    _serviceTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Update notification content if needed (optional)
          // service.setForegroundNotificationInfo(
          //   title: "Feelin Pay",
          //   content: "Activo: ${DateTime.now()}",
          // );
        }
      }

      // Execute background tasks
      await _executeBackgroundTasks();

      // Send heartbeat/data to UI
      service.invoke('update', {
        "current_date": DateTime.now().toIso8601String(),
      });
    });
  }

  static Future<void> _executeBackgroundTasks() async {
    // CRITICAL: Only run background tasks if user is logged in
    final isLoggedIn = await SessionService.isLoggedIn();
    if (!isLoggedIn) {
      // debugPrint('⏸️ [Background] No active session. Skipping tasks.');
      return;
    }

    debugPrint('🔄 [Background] Executing tasks...');
    try {
      // 1. Keep Session Alive
      await _keepSessionAlive();

      // 2. Check Permissions/Pending Notifications
      await processPendingNotifications();

      // 3. Process Pending SMS
      await processPendingSMS();

      debugPrint('✅ [Background] Tasks completed');
    } catch (e) {
      debugPrint('❌ [Background] Error executing tasks: $e');
    }
  }

  static Future<void> _keepSessionAlive() async {
    // Re-verify session validity
    try {
      final isLoggedIn = await SessionService.isLoggedIn();
      if (isLoggedIn) {
        await SessionService.keepSessionAlive();
      }
    } catch (e) {
      // Ignore network errors in background loop
    }
  }

  static Future<void> processPendingNotifications() async {
    try {
      // Re-initialize API service if needed (might be stateless in static context)
      // Assuming LocalDatabase works in isolate (it uses sqflite which should work if initialized)
      final notifications = await LocalDatabase.getNotificacionesPendientes();
      if (notifications.isNotEmpty) {
        for (var notification in notifications) {
          await LocalDatabase.procesarNotificacionYape(
            notification['mensajeOriginal'],
            notification['propietarioId'],
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing notifications: $e');
    }
  }

  static Future<void> processPendingSMS() async {
    try {
      await LocalDatabase.enviarSMSPendientes();
    } catch (e) {
      debugPrint('Error processing SMS: $e');
    }
  }
}
