import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// CALLBACK DE SEGUNDO PLANO (DEBE ESTAR FUERA DE LA CLASE)
@pragma('vm:entry-point')
void onNotificationBackground(NotificationEvent evt) {
  // ignore: avoid_print
  print(
    "🔵 [Bg-Isolate] Notificación entrante: ${evt.packageName} | ${evt.title}",
  );

  // Procesar directamente
  PaymentNotificationService.handleExternalEvent(evt);
}

@pragma('vm:entry-point')
class PaymentNotificationService {
  static final Telephony _telephony = Telephony.instance;
  static ApiService? _apiService;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isListening = false;
  static UserModel? _currentUser;

  /// Inicializa el servicio y los plugins necesarios
  static Future<void> init(UserModel currentUser) async {
    _currentUser = currentUser;

    // Guardar datos para el isolate de background
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_user_id', currentUser.id);
    final token = ApiService().authToken;
    if (token != null) {
      await prefs.setString('bg_auth_token', token);
    }
    debugPrint('💾 Datos de sesión guardados para procesos de fondo.');

    // NOTA: Los permisos se solicitan en la UI (AndroidPermissionsScreen)
    // No los solicitamos aquí para evitar conflictos o doble redirección.

    // 2. Inicializar notificaciones locales
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(initializationSettings);
    } catch (e) {
      debugPrint('⚠️ Error inicializando notificaciones locales: $e');
    }

    // 3. Inicializar el Listener (Registro de callback)
    try {
      debugPrint('🔌 Registrando callback nativo del listener...');
      await NotificationsListener.initialize(
        callbackHandle: onNotificationBackground,
      );
    } catch (e) {
      debugPrint('⚠️ Error en inicialización del listener: $e');
    }
  }

  /// Inicializa solo el listener para verificar permisos (sin usuario)
  static Future<void> initializeListenerOnly() async {
    try {
      await NotificationsListener.initialize(
        callbackHandle: onNotificationBackground,
      );
    } catch (e) {
      debugPrint('⚠️ Error inicializando listener básico: $e');
    }
  }

  static Future<bool> get hasPermission async {
    try {
      return await NotificationsListener.hasPermission ?? false;
    } catch (e) {
      debugPrint('❌ Error verificando permisos: $e');
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await NotificationsListener.openPermissionSettings();
    } catch (e) {
      debugPrint('❌ Error abriendo configuración: $e');
    }
  }

  static Future<void> stopListening() async {
    try {
      await NotificationsListener.stopService();
      _isListening = false;
      debugPrint('⏹️ Servicio detenido');
    } catch (e) {
      debugPrint('❌ Error deteniendo servicio: $e');
    }
  }

  static bool get isListening => _isListening;

  static Future<void> startListening({
    bool showDialog = false,
    bool isForeground = true,
  }) async {
    debugPrint(
      '🔔 [START] startListening called, showDialog=$showDialog, isForeground=$isForeground',
    );

    if (_isListening) {
      debugPrint('ℹ️ El sistema ya está escuchando.');
      return;
    }

    try {
      debugPrint('🚀 Iniciando secuencia de monitoreo...');

      // 1. Verificar permisos
      final hasPerm = await hasPermission;
      debugPrint('🔐 Verificación de permisos: $hasPerm');

      if (!hasPerm) {
        debugPrint('⚠️ Sin permisos de Listener.');
        if (showDialog) await openSettings();
        return;
      }

      // 2. Iniciar el servicio NATIVO
      // Si isForeground es true, muestra su propia notificación persistente.
      // Si es false, corre "silenciosamente" (útil si ya hay otro servicio foreground como UnifiedBackgroundService).
      debugPrint(
        '🚀 Llamando a startService (foreground=$isForeground)...',
      );
      await NotificationsListener.startService(
        title: "Feelin Pay",
        description: "Escuchando notificaciones de pago",
        subTitle: "Servicio activo",
        showWhen: true,
        foreground: isForeground,
      );
      debugPrint('✅ startService completado exitosamente');

      // Start native persistent notification service
      try {
        const platform = MethodChannel('com.example.feelin_pay/notification');
        await platform.invokeMethod('startPersistentNotification');
        debugPrint('✅ Native persistent notification started');
      } catch (e) {
        debugPrint('⚠️ Failed to start native notification: $e');
      }

      // 3.5 Re-vincular manejador por si acaso
      await NotificationsListener.initialize(
        callbackHandle: onNotificationBackground,
      );

      // Esperar a que Android estabilice el servicio y el puerto
      await Future.delayed(const Duration(seconds: 2));

      // 4. Conectar puerto de comunicación
      debugPrint('📡 Conectando puerto de datos...');
      int retries = 0;
      while (NotificationsListener.receivePort == null && retries < 15) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      if (NotificationsListener.receivePort == null) {
        debugPrint('❌ Error: Puerto de comunicación no disponible.');
        return;
      }

      // 5. Suscribirse al flujo
      debugPrint('✅ Puerto conectado. Escuchando...');
      NotificationsListener.receivePort!.listen((evt) {
        debugPrint('📨 EVENTO RECIBIDO EN PUERTO: ${evt.packageName}');
        _onNotificationReceived(evt);
      }, onError: (e) => debugPrint('❌ Error en el flujo de datos: $e'));

      _isListening = true;
      debugPrint(
        '🎉 [SUCCESS] Servicio de notificaciones iniciado correctamente',
      );
    } catch (e) {
      debugPrint('❌ [ERROR] Error activando el monitoreo: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> _onNotificationReceived(NotificationEvent? evt) async {
    try {
      if (evt == null) return;
      handleExternalEvent(evt);
    } catch (e) {
      debugPrint('❌ Error en el manejador de entrada: $e');
    }
  }

  /// Punto de entrada unificado para UI y Isolate de Background
  static Future<void> handleExternalEvent(NotificationEvent evt) async {
    try {
      final isBackground = Isolate.current.debugName != 'main';

      // LOG CRÍTICO PARA DEBUG: Ver qué llega realmente (USAR print para background)
      // ignore: avoid_print
      final logger = isBackground ? (Object? o) => print(o) : debugPrint;

      logger('----------------------------------------');
      logger('🔥 EVENTO DETECTADO:');
      logger('   Paquete: ${evt.packageName}');
      logger('   Título: ${evt.title}');
      logger('   Texto: ${evt.text}');
      logger('----------------------------------------');

      // FILTRO: Ignorar notificaciones de grupo de Android (sin contenido)
      if (evt.title == null ||
          evt.title!.isEmpty ||
          evt.text == null ||
          evt.text!.isEmpty) {
        logger('ℹ️ Notificación de grupo o sin contenido. Ignorando.');
        return;
      }

      // Procesar solo si es Yape (Soportamos varias versiones del paquete)
      final yapePackages = [
        'com.bcp.innovacxion.yapeapp',
        'com.bcp.innovabcp.yape',
      ];

      // El usuario reporta que Yape usa título "Confirmación de Pago"
      final isYapePackage = yapePackages.contains(evt.packageName);
      final isYapeTitle = evt.title?.contains('Pago') ?? false;

      if (isYapePackage || isYapeTitle) {
        final uniqueId = (evt.uniqueId != null)
            ? '${evt.uniqueId}-${DateTime.now().millisecondsSinceEpoch}'
            : 'YAPE-${DateTime.now().millisecondsSinceEpoch}';

        await processNotification(
          packageName: evt.packageName,
          title: evt.title ?? '',
          body: evt.text ?? '',
          uniqueId: uniqueId,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error crítico en handleExternalEvent: $e');
    }
  }

  /// Lógica central de procesamiento
  static Future<void> processNotification({
    required String? packageName,
    required String title,
    required String body,
    required String uniqueId,
  }) async {
    try {
      final isBackground = Isolate.current.debugName != 'main';
      // ignore: avoid_print
      final logger = isBackground ? (Object? o) => print(o) : debugPrint;

      logger('⚡ PROCESANDO PAGO DE YAPE...');

      final service = _apiService;
      final user = _currentUser;

      // 1. RECONSTRUCCIÓN DE DEPENDENCIAS (Solo si estamos en isolate de fondo)
      if (service == null || user == null) {
        logger('🛠️ Reinstalando dependencias en isolate de fondo...');
        final newService = ApiService();
        await newService.initialize();
        _apiService = newService;

        final prefs = await SharedPreferences.getInstance();
        final savedUserId = prefs.getString('bg_user_id');
        final savedToken = prefs.getString('bg_auth_token');

        if (savedUserId != null) {
          final newUser = UserModel(
            id: savedUserId,
            rolId: 'bg_listener',
            rol: 'super_admin',
            nombre: 'Servicio de Fondo',
            email: 'service@feelin-pay.com',
            activo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _currentUser = newUser;

          if (savedToken != null) {
            await newService.setAuthToken(savedToken);
          }
          logger('✅ Datos de sesión restaurados en isolate.');
        }
      }

      if (_currentUser == null || _apiService == null) {
        logger(
          '❌ Error: Usuario o Servicio no disponible para procesar el pago.',
        );
        return;
      }

      // 2. PARSEO DE NOTIFICACIÓN
      final paymentData = _parseYapeNotification(title, body, uniqueId);

      if (paymentData != null) {
        final codePart = (paymentData['codigoSeguridad'] as String).isNotEmpty
            ? " | Código: ${paymentData['codigoSeguridad']}"
            : "";
        logger(
          '✅ Datos extraídos: ${paymentData['nombrePagador']} - S/ ${paymentData['monto']} (${paymentData['medioDePago']})$codePart',
        );
        await _processPaymentBridge(paymentData);
      } else {
        logger('❌ No se pudieron extraer datos del cuerpo de la notificación.');
        logger('   Cuerpo recibido: "$body"');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error crítico en processNotification: $e');
    }
  }

  /// Método de parseo (Sincrónico para evitar overhead de isolate extra)
  static Map<String, dynamic>? _parseYapeNotification(
    String title,
    String body,
    String uniqueId,
  ) {
    // 1. EXTRAER MONTO (Común a ambos)
    final RegExp montoRegex = RegExp(r'S/\s*([\d,]+\.?\d*)');
    final montoMatch = montoRegex.firstMatch(body);
    if (montoMatch == null) return null;

    final montoStr = montoMatch.group(1)?.replaceAll(',', '') ?? '0';
    final monto = double.tryParse(montoStr) ?? 0.0;
    if (monto <= 0) return null;

    // 2. EXTRAER CÓDIGO DE SEGURIDAD (Si existe)
    // Buscamos: "El cód. de seguridad es: 837" o "código: 123456"
    final RegExp codeRegex = RegExp(
      r'có[d.]\.? de seguridad es:\s*(\d+)',
      caseSensitive: false,
    );
    final codeMatch = codeRegex.firstMatch(body);
    final realCode = codeMatch?.group(1);

    // 3. EXTRAER NOMBRE DEL PAGADOR
    // El nombre suele estar antes de "te envió un pago" o "te envió S/"
    // Puede venir con el prefijo "Yape! " o sin él (caso Yape-Yape con código)
    final RegExp nameRegex = RegExp(
      r'(?:Yape!\s+)?(.+?)\s+te\s+envió',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(body);
    final nombrePagador = nameMatch?.group(1)?.trim() ?? 'Remitente';

    final medioDePago = realCode != null ? 'yape' : 'plin';

    return {
      'nombrePagador': nombrePagador,
      'monto': monto,
      'codigoSeguridad': realCode ?? '', // Solo enviamos si existe (Yape-Yape)
      'uniqueId':
          uniqueId, // Mantenemos el ID de evento para trazabilidad interna
      'medioDePago': medioDePago,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> _processPaymentBridge(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final isBackground = Isolate.current.debugName != 'main';
      // ignore: avoid_print
      final logger = isBackground ? (Object? o) => print(o) : debugPrint;

      if (_currentUser == null) {
        logger('❌ Error: No hay usuario autenticado para registrar el pago.');
        return;
      }

      logger('🌉 Enviando pago al servidor para procesar SMS...');

      // Obtener token de Google desde SharedPreferences (cacheado en login)
      String? googleAccessToken;
      try {
        final prefs = await SharedPreferences.getInstance();
        googleAccessToken = prefs.getString('bg_google_token');
        if (googleAccessToken != null) {
          logger(
            '🔑 Token de Google recuperado para uso en Drive del usuario.',
          );
        } else {
          logger(
            '⚠️ Sin token de Google. Se usará Service Account (puede tener cuota limitada).',
          );
        }
      } catch (e) {
        logger('⚠️ Error recuperando token de Google: $e');
      }

      final response = await _apiService!.post<Map<String, dynamic>>(
        '/payments/yape',
        data: {
          'usuarioId': _currentUser!.id,
          'nombrePagador': paymentData['nombrePagador'],
          'monto': paymentData['monto'],
          'codigoSeguridad': paymentData['codigoSeguridad'],
          'medioDePago': paymentData['medioDePago'], // 'yape' o 'plin'
          'notifUniqueId': paymentData['uniqueId'],
          'googleAccessToken':
              googleAccessToken, // NUEVO: Token para usar Drive del usuario
        },
      );

      if (response.isSuccess && response.data != null) {
        logger('✅ Pago registrado con éxito.');

        final smsTargets = response.data!['smsTargets'] as List<dynamic>?;

        if (smsTargets != null && smsTargets.isNotEmpty) {
          final defaultMessage =
              "Feelin Pay: Pago recibido de ${paymentData['nombrePagador']} por S/ ${paymentData['monto']}.";

          logger(
            '📱 Preparando envío de SMS a ${smsTargets.length} destinos...',
          );

          for (var target in smsTargets) {
            String? phone;
            String? targetMsg;

            if (target is String) {
              phone = target;
              targetMsg = defaultMessage;
            } else if (target is Map) {
              phone = target['telefono']?.toString();
              targetMsg = target['mensaje']?.toString() ?? defaultMessage;
            }

            if (phone != null && phone.isNotEmpty) {
              logger('   -> Iniciando envío a $phone...');
              await _sendSMSBatch([phone], targetMsg ?? defaultMessage);
              logger('   ✅ Envío finalizado para $phone.');
              // Pausa de 2 segundos para asegurar entrega secuencial del operador (evita bloqueos de red)
              await Future.delayed(const Duration(seconds: 2));
            }
          }
        } else {
          logger('ℹ️ No hay empleados configurados para recibir SMS.');
        }
      } else {
        logger('⚠️ El servidor rechazó el registro: ${response.message}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error crítico en el puente de procesamiento: $e');
    }
  }

  static Future<void> _sendSMSBatch(List<String> phones, String message) async {
    final isBackground = Isolate.current.debugName != 'main';
    // ignore: avoid_print
    final logger = isBackground ? (Object? o) => print(o) : debugPrint;

    for (String phone in phones) {
      try {
        logger('   -> Enviando a $phone...');
        await _telephony.sendSms(to: phone, message: message);
        logger('   ✅ SMS enviado.');
      } catch (e) {
        logger('   ❌ Error enviando SMS a $phone: $e');
      }
    }
  }

  /// Método de simulación para pruebas internas
  static Future<void> simulateTestYape() async {
    debugPrint('🧪 SIMULANDO NOTIFICACIÓN PLIN (SIN CÓDIGO)...');
    await _onNotificationReceived(
      NotificationEvent(
        packageName: 'com.bcp.innovacxion.yapeapp',
        title: 'Confirmación de Pago',
        text: 'Yape! DAVID TEST te envió un pago por S/ 1.50',
        createAt: DateTime.now(),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    debugPrint('🧪 SIMULANDO NOTIFICACIÓN YAPE-YAPE (CON CÓDIGO)...');
    await _onNotificationReceived(
      NotificationEvent(
        packageName: 'com.bcp.innovacxion.yapeapp',
        title: 'Confirmación de Pago',
        text:
            'David Test* te envió un pago por S/ 2.00. El cód. de seguridad es: 999',
        createAt: DateTime.now(),
      ),
    );
  }
}
