import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';
import '../models/user_model.dart';
import 'payment_notification_service.dart';

/// Servicio unificado en primer plano que maneja:
/// 1. Notificación persistente
/// 2. Escucha de notificaciones de Yape
/// 3. Procesamiento de pagos en segundo plano
@pragma('vm:entry-point')
class UnifiedBackgroundService {
  static Future<void> initialize(UserModel user) async {
    final service = FlutterBackgroundService();

    debugPrint('🔧 Inicializando servicio unificado en primer plano...');

    // 0. Crear canal de notificación (CRÍTICO: Hacerlo en UI Isolate antes de config)
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'feelin_pay_foreground',
      'Feelin Pay Service',
      description: 'Canal para el servicio de notificaciones de pago',
      importance:
          Importance.high, // HIGH para asegurar visibilidad en Huawei/Xiaomi
      playSound: false, // No hacer ruido constante, solo visual
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 1. Configurar servicio
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId:
            'feelin_pay_foreground', // Debe coincidir con el creado arriba
        initialNotificationTitle: 'Feelin Pay',
        initialNotificationContent: 'Escuchando notificaciones de pago',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true, // Habilitar inicio automático
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Guardar datos del usuario para el servicio
    await PaymentNotificationService.init(user);

    debugPrint('✅ Servicio unificado configurado y canal creado');
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    debugPrint('🚀 Iniciando servicio unificado...');
    await service.startService();
    debugPrint('✅ Servicio unificado iniciado');
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    debugPrint('⏹️ Deteniendo servicio unificado...');
    service.invoke('stopService');
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    debugPrint('🎬 Servicio unificado: onStart() llamado');

    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        debugPrint('⏹️ Recibida señal de detener servicio');
        service.stopSelf();
      });

      // Ya no creamos el canal aquí porque se crea en initialize()

      // Configurar como servicio en primer plano
      service.setAsForegroundService();
      debugPrint('✅ Servicio configurado como foreground');

      // TRUCO AVANZADO: Usar flutter_local_notifications para forzar el ICONO
      // Inicializamos el plugin dentro del isolate del servicio para asegurar que funcione
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Inicialización mínima necesaria para que funcionen las notificaciones en este isolate
      // Usamos @mipmap/ic_launcher que es el logo de la app
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Pequeña pausa para asegurar que el servicio nativo ya se registró como foreground
      // Esto ayuda a que la actualización de la notificación "pegue" correctamente y se vea de inmediato
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await flutterLocalNotificationsPlugin.show(
          888, // El mismo ID definido en configure()
          'Feelin Pay',
          'Escuchando notificaciones de pago',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'feelin_pay_foreground',
              'Feelin Pay Service',
              channelDescription:
                  'Canal para el servicio de notificaciones de pago',
              icon: '@mipmap/ic_launcher', // Usar logo de la app
              ongoing: true,
              autoCancel: false,
              importance: Importance.high,
              priority:
                  Priority.high, // Prioridad alta para visibilidad inmediata
              playSound: false,
              visibility: NotificationVisibility
                  .public, // Visible en pantalla de bloqueo
              showWhen: true,
            ),
          ),
        );
        debugPrint(
          '✅ Notificación actualizada inmediatamente con icono personalizado',
        );
      } catch (e) {
        debugPrint('⚠️ No se pudo actualizar icono de notificación: $e');
        // Fallback
        service.setForegroundNotificationInfo(
          title: "Feelin Pay",
          content: "Escuchando notificaciones de pago",
        );
      }

      // Iniciar listener de notificaciones de Yape
      try {
        debugPrint('🔌 Iniciando listener de notificaciones...');
        await _startNotificationListener();
        debugPrint('✅ Listener de notificaciones iniciado');
      } catch (e) {
        debugPrint('❌ Error iniciando listener: $e');
      }

      // Watchdog: Mantener servicio vivo y verificar estado
      Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (await service.isForegroundService()) {
          // Heartbeat silencioso
          // debugPrint('💓 Servicio activo - heartbeat');

          // No spammear actualizaciones de notificación si no es necesario
          // service.setForegroundNotificationInfo(...)
        } else {
          debugPrint('⚠️ Servicio ya no es foreground, cancelando timer');
          timer.cancel();
        }
      });
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🍎 iOS background task');
    return true;
  }

  /// Callback para procesar notificaciones recibidas
  @pragma('vm:entry-point')
  static Future<void> _onNotificationReceived(NotificationEvent evt) async {
    debugPrint(
      '🔔 Notificación recibida en servicio unificado: ${evt.packageName}',
    );
    // Delegar al manejador existente de PaymentNotificationService
    try {
      await PaymentNotificationService.handleExternalEvent(evt);
    } catch (e) {
      debugPrint('❌ Error delegando evento al manejador de pagos: $e');
    }
  }

  static Future<void> _startNotificationListener() async {
    try {
      // Inicializar el listener con el callback
      await NotificationsListener.initialize(
        callbackHandle: _onNotificationReceived,
      );

      // Iniciar el servicio del listener (sin foreground, ya lo maneja flutter_background_service)
      await NotificationsListener.startService(
        title: "Feelin Pay Listener",
        description: "Servicio de escucha",
        subTitle: "Activo",
        showWhen: true,
        foreground: false, // No crear otra notificación foreground
      );

      debugPrint('✅ NotificationsListener iniciado correctamente');
    } catch (e) {
      debugPrint('❌ Error en _startNotificationListener: $e');
      rethrow;
    }
  }
}
