import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class PaymentNotificationService {
  static final Telephony _telephony = Telephony.instance;
  static final ApiService _apiService = ApiService();
  static bool _isListening = false;
  static UserModel? _currentUser;

  /// Inicializa el servicio y solicita permisos
  static Future<void> init(UserModel currentUser) async {
    _currentUser = currentUser;
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    // Permiso para SMS (Solo Enviar)
    final smsStatus = await Permission.sms.request();
    if (!smsStatus.isGranted) {
      debugPrint('⚠️ Permiso SEND_SMS denegado');
    }

    // Permiso para Notificaciones (Android Settings)
    // El plugin flutter_notification_listener abre la configuración si no está habilitado
    // Lo verificamos al iniciar la escucha
  }

  /// Iniciar escucha de notificaciones de Yape
  static Future<void> startListening({bool showDialog = false}) async {
    debugPrint('🚀 startListening() CALLED');
    debugPrint('   _isListening: $_isListening');
    debugPrint('   _currentUser: ${_currentUser?.id}');

    if (_isListening) {
      debugPrint('⚠️ Ya está escuchando, saliendo...');
      return;
    }

    try {
      // Verificar si tenemos acceso a notificaciones
      debugPrint('🔍 Verificando permisos...');
      final bool hasPerm = await hasPermission;
      if (!hasPerm) {
        if (showDialog) {
          debugPrint('⚠️ Solicitando acceso a notificaciones...');
          await openSettings();
        }
        return;
      }

      // Iniciar el servicio en background (Requisito de Android para escuchar en segundo plano)
      await NotificationsListener.startService(
        title: "Feelin Pay",
        description: "Escuchando notificaciones de pago",
        subTitle: "Servicio activo",
        showWhen: true,
        foreground: true,
      );

      // Start native persistent notification service
      try {
        const platform = MethodChannel('com.example.feelin_pay/notification');
        await platform.invokeMethod('startPersistentNotification');
        debugPrint('✅ Native persistent notification started');
      } catch (e) {
        debugPrint('⚠️ Failed to start native notification: $e');
      }

      _isListening = true;
      debugPrint('✅ Servicio de Escucha Activo');
      debugPrint('   Usuario: ${_currentUser?.nombre} (${_currentUser?.id})');

      // Suscribirse al stream de eventos
      debugPrint('📡 Registrando listener de notificaciones...');

      // CRITICAL: Verify receivePort is not null
      if (NotificationsListener.receivePort == null) {
        debugPrint('❌ ERROR: receivePort is NULL! Cannot register listener.');
        _isListening = false;
        return;
      }

      debugPrint('✅ receivePort disponible, registrando callback...');
      NotificationsListener.receivePort!.listen(
        (evt) {
          debugPrint('📨 EVENTO RECIBIDO DEL PUERTO');
          _onNotificationReceived(evt);
        },
        onError: (error) {
          debugPrint('❌ ERROR EN LISTENER: $error');
        },
        onDone: () {
          debugPrint('⚠️ LISTENER CERRADO');
        },
      );
      debugPrint('✅ Listener registrado correctamente');
    } catch (e) {
      debugPrint('❌ Error iniciando Bridge Mode: $e');
      _isListening = false;
    }
  }

  /// Verificar si tiene permisos de notificación (Listener)
  static Future<bool> get hasPermission async {
    try {
      return await NotificationsListener.hasPermission ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Abrir configuración de notificaciones
  static Future<void> openSettings() async {
    try {
      await NotificationsListener.openPermissionSettings();
    } catch (e) {
      debugPrint('Error abriendo settings: $e');
    }
  }

  /// Detener servicio
  static Future<void> stopListening() async {
    try {
      await NotificationsListener.stopService();
      _isListening = false;
      debugPrint('⏹️ Bridge Mode Detenido');
    } catch (e) {
      debugPrint('❌ Error deteniendo servicio: $e');
    }
  }

  /// Callback cuando llega una notificación
  static Future<void> _onNotificationReceived(NotificationEvent? evt) async {
    debugPrint('🔥 NOTIFICATION CALLBACK TRIGGERED!');
    debugPrint('   Package: ${evt?.packageName}');
    debugPrint('   Current User: ${_currentUser?.id}');

    if (evt == null || _currentUser == null) {
      debugPrint(
        '❌ CALLBACK ABORTED: evt=${evt != null}, user=${_currentUser != null}',
      );
      return;
    }

    // 🛑 PRIVACY FILTER: Strictly limit processing to Yape package
    // OPTIMIZED: Strict filtering.
    final packageName = evt.packageName;
    if (packageName != 'com.bcp.innovacxion.yapeapp') {
      debugPrint('⏭️ SKIPPED: Not Yape package ($packageName)');
      return;
    }

    final title = evt.title ?? '';
    final body = evt.text ?? '';
    final uniqueId = evt.uniqueId ?? evt.createAt.toString();

    // DEBUG: Log Yape notifications for troubleshooting
    debugPrint('🔔 YAPE NOTIFICATION RECEIVED:');
    debugPrint('   Title: $title');
    debugPrint('   Body: $body');

    // Parsear en ISOLATE para no bloquear UI
    final parseResult = await compute(
      _parseNotificationInIsolate,
      _ParseData(title, body, uniqueId),
    );

    if (parseResult != null) {
      debugPrint('✅ PAYMENT PARSED:');
      debugPrint('   Pagador: ${parseResult['nombrePagador']}');
      debugPrint('   Monto: S/ ${parseResult['monto']}');
      debugPrint('   Código: ${parseResult['codigoSeguridad']}');
      await _processPaymentBridge(parseResult);
    } else {
      debugPrint('❌ PAYMENT PARSING FAILED - notification ignored');
    }
  }

  // Helper class for compute
  static Map<String, dynamic>? _parseNotificationInIsolate(_ParseData data) {
    return _parsePaymentNotification(data.title, data.body, data.uniqueId);
  }

  // Cache para evitar duplicados (Android a veces envía el evento múltiple veces)
  static final Set<String> _processedIds = {};

  static Map<String, dynamic>? _parsePaymentNotification(
    String title,
    String body,
    String uniqueId, // ID único de la notificación del sistema
  ) {
    // 1. Evitar Loop de Notificaciones del Sistema (Loop infinito si nos leemos a nosotros mismos)
    // El listener ya filtra por package name (Yape), así que esto es redundante pero seguro.

    try {
      // Regex para Yape: busca "te envió S/ X.XX"
      // Formato según screenshot: "Delsy Vas* te envió un pago por S/ 1. El cód. de seguridad es: 837"

      // 1. Extraer Monto
      final RegExp regexMonto = RegExp(r'S/\s?(\d+(?:\.\d{1,2})?)');
      final matchMonto = regexMonto.firstMatch(body);

      // 2. Extraer Código (Buscamos "cód. de seguridad es: XXX")
      // Aceptamos variaciones leves en "cód." por si acaso
      final RegExp regexCode = RegExp(r'cód\.? de seguridad es:\s*(\d+)');
      final matchCode = regexCode.firstMatch(body);

      if (matchMonto != null) {
        final montoStr = matchMonto.group(1);

        // 3. Extraer Nombre (Todo antes de " te envió")
        final nombreEndIndex = body.indexOf(' te envió');
        final nombre = nombreEndIndex > 0
            ? body.substring(0, nombreEndIndex).trim()
            : 'Desconocido';

        // Determinar Código Final y Medio de Pago
        String codigo = '';
        String medioDePago = '';

        if (matchCode != null) {
          // YAPE → YAPE (tiene código de seguridad explícito)
          codigo = matchCode.group(1)!;
          medioDePago = 'Yape';
        } else {
          // PLIN → YAPE o auto-transferencia (no tiene código explícito)
          // Fallback mejorado: buscar cualquier secuencia de 3-6 dígitos
          final RegExp regexFallback = RegExp(r'\b\d{3,6}\b');
          final allMatches = regexFallback.allMatches(body).toList();

          if (allMatches.isNotEmpty) {
            // Tomar el último match (usualmente el código está al final)
            codigo = allMatches.last.group(0)!;
            medioDePago =
                'Plin'; // Asumimos Plin si hay dígitos pero no formato Yape
          } else {
            // Si no hay código, generar uno basado en timestamp + nombre
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final nameHash = nombre.hashCode.abs();
            codigo =
                'PLIN-${(timestamp % 100000).toString().padLeft(5, '0')}-${(nameHash % 1000).toString().padLeft(3, '0')}';
            medioDePago = 'Plin';
            debugPrint('⚠️ Pago Plin→Yape detectado, código generado: $codigo');
          }
        }

        // --- VALIDACIÓN DE DUPLICADOS (REGLA USUARIO) ---
        // "El mismo nombre no puede repetir el código de seguridad el mismo día"
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month}-${now.day}";
        final dedupeKey = "$todayStr|$nombre|$codigo";

        if (_processedIds.contains(dedupeKey)) {
          debugPrint('🚫 Pago duplicado hoy detectado: $nombre - $codigo');
          return null;
        }
        _processedIds.add(dedupeKey);
        // Limpieza simple: si crece mucho, reiniciamos (un día no debería tener millones de tx locales)
        if (_processedIds.length > 500) _processedIds.clear();

        return {
          'nombrePagador': nombre,
          'monto': double.tryParse(montoStr ?? '0') ?? 0.0,
          'codigoSeguridad': codigo,
          'medioDePago': medioDePago, // 'Yape' o 'Plin'
          'originalText': '$title $body',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Error parseando notificación: $e');
    }
    return null;
  }

  static Future<void> _processPaymentBridge(
    Map<String, dynamic> paymentData,
  ) async {
    if (_currentUser == null) return;

    try {
      debugPrint('📤 SENDING TO BACKEND:');
      debugPrint('   Endpoint: /payments/yape');
      debugPrint('   Usuario ID: ${_currentUser!.id}');
      debugPrint('   Pagador: ${paymentData['nombrePagador']}');
      debugPrint('   Monto: ${paymentData['monto']}');
      debugPrint('   Código: ${paymentData['codigoSeguridad']}');

      // 1. Enviar al Backend (Log en Sheets + Notificación Dashboard)
      // Enviamos el pago INMEDIATAMENTE para que el backend decida destinatarios
      final response = await _apiService.post<Map<String, dynamic>>(
        '/payments/yape', // Endpoint correcto según paymentRoutes.ts
        data: {
          'usuarioId': _currentUser!.id,
          'nombrePagador': paymentData['nombrePagador'],
          'monto': paymentData['monto'],
          'codigoSeguridad': paymentData['codigoSeguridad'],
          'medioDePago': paymentData['medioDePago'], // 'Yape' o 'Plin'
        },
      );

      debugPrint('📥 BACKEND RESPONSE:');
      debugPrint('   Success: ${response.isSuccess}');
      debugPrint('   Message: ${response.message}');

      // 2. Revisar si hay que enviar SMS (Respuesta del backend)
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('   SMS Targets: ${data['smsTargets']}');

        if (data['smsTargets'] != null) {
          final List<dynamic> targets = data['smsTargets'];

          if (targets.isNotEmpty) {
            // REQUERIMIENTO: "SMS tal cual llega la notificación como una copia"
            // Usamos el texto original capturado
            final message =
                paymentData['originalText'] ??
                "Pago recibido: ${paymentData['monto']}";

            await _sendSMSBatch(targets.cast<String>(), message);
          }
        }
      } else {
        debugPrint('❌ BACKEND ERROR: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error procesando pago en backend: $e');
    }
  }

  static Future<void> _sendSMSBatch(List<String> phones, String message) async {
    for (final phone in phones) {
      try {
        debugPrint('📨 Enviando SMS a $phone...');
        // Enviar en background
        await _telephony.sendSms(to: phone, message: message);
      } catch (e) {
        debugPrint('❌ Error enviando SMS a $phone: $e');
      }
    }
  }
}

class _ParseData {
  final String title;
  final String body;
  final String uniqueId;

  _ParseData(this.title, this.body, this.uniqueId);
}
