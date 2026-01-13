import 'package:flutter/foundation.dart';
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
    if (_isListening) return;

    try {
      // Verificar si tenemos acceso a notificaciones
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
        description: "Servicio de cobros activo",
      );

      _isListening = true;
      debugPrint('✅ Servicio de Escucha Activo');

      // Suscribirse al stream de eventos
      NotificationsListener.receivePort?.listen(
        (evt) => _onNotificationReceived(evt),
      );
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
    if (evt == null || _currentUser == null) return;

    // Filtro por paquete (Yape)
    // com.bcp.innovacxion.yapeapp (Yape)
    final packageName = evt.packageName;
    if (packageName != 'com.bcp.innovacxion.yapeapp' &&
        packageName?.contains('yape') != true) {
      return;
    }

    final title = evt.title ?? '';
    final body =
        evt.text ?? ''; // El contenido del mensaje ("Te enviaron S/...")

    debugPrint('🔔 Notificación Yape Detectada: $title - $body');

    // Parsear datos (Regex simple para extraer monto y nombre)
    // Formato típico Yape: "Juan Perez te envió S/ 20.00"
    final parseResult = _parsePaymentNotification(
      title,
      body,
      evt.uniqueId ?? evt.createAt.toString(),
    );

    if (parseResult != null) {
      await _processPaymentBridge(parseResult);
    }
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

        // Determinar Código Final
        String codigo = '';
        if (matchCode != null) {
          codigo = matchCode.group(1)!;
        } else {
          // Fallback: buscar 3-6 dígitos al final si no machea el texto exacto
          final RegExp regexFallback = RegExp(r'\b\d{3,6}\b');
          final matchFallback = regexFallback.allMatches(body).lastOrNull;
          if (matchFallback != null) {
            codigo = matchFallback.group(0)!;
          } else {
            // Generado solo si falla todo (muy raro en confirmación válida)
            codigo =
                'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
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
      // 1. Enviar al Backend (Log en Sheets + Notificación Dashboard)
      // Enviamos el pago INMEDIATAMENTE para que el backend decida destinatarios
      final response = await _apiService.post<Map<String, dynamic>>(
        '/payments/yape-webhook', // Endpoint existente o nuevo para webhook interno
        data: {
          'usuarioId': _currentUser!.id,
          'nombrePagador': paymentData['nombrePagador'],
          'monto': paymentData['monto'],
          'codigoSeguridad': paymentData['codigoSeguridad'],
        },
      );

      // 2. Revisar si hay que enviar SMS (Respuesta del backend)
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
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
