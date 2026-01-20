import 'dart:io';
import 'package:flutter/services.dart'; // Para MethodChannel
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoStartService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _prefKey = 'auto_start_configured';

  /// Guarda el estado de configuración manual
  static Future<void> saveAutoStartConfigured(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  /// Recupera el estado de configuración manual
  static Future<bool> isAutoStartConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static const MethodChannel _channel = MethodChannel(
    'com.feelin.pay/native_utils',
  );

  /// Intenta abrir la configuración de inicio automático según el fabricante
  static Future<void> openAutoStartSettings() async {
    if (!Platform.isAndroid) return;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      debugPrint('📱 Detectado fabricante: $manufacturer');

      List<_IntentCandidate> candidates = [];

      // Mapeo de intents conocidos para Auto-Start
      if (manufacturer.contains('xiaomi') ||
          manufacturer.contains('redmi') ||
          manufacturer.contains('poco')) {
        candidates = [
          _IntentCandidate(
            'com.miui.securitycenter',
            'com.miui.permcenter.autostart.AutoStartManagementActivity',
          ),
          // Fallback simple
          _IntentCandidate(
            'com.miui.securitycenter',
            'com.miui.permcenter.autostart.AutoStartManagementActivity',
          ),
        ];
      } else if (manufacturer.contains('oppo') ||
          manufacturer.contains('realme') ||
          manufacturer.contains('oneplus')) {
        candidates = [
          _IntentCandidate(
            'com.coloros.safecenter',
            'com.coloros.safecenter.startupapp.StartupAppListActivity',
          ),
          _IntentCandidate(
            'com.coloros.safecenter',
            'com.coloros.safecenter.permission.startup.StartupAppListActivity',
          ),
          _IntentCandidate(
            'com.oppo.safe',
            'com.oppo.safe.permission.startup.StartupAppListActivity',
          ),
        ];
      } else if (manufacturer.contains('vivo')) {
        candidates = [
          _IntentCandidate(
            'com.vivo.permissionmanager',
            'com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
          ),
          _IntentCandidate(
            'com.iqoo.secure',
            'com.iqoo.secure.ui.phoneoptimze.BgStartUpManager',
          ),
        ];
      } else if (manufacturer.contains('huawei') ||
          manufacturer.contains('honor')) {
        candidates = [
          // Honor MagicOS
          _IntentCandidate(
            'com.hihonor.systemmanager',
            'com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
          ),
          // EMUI / HarmonyOS Moderno
          _IntentCandidate(
            'com.huawei.systemmanager',
            'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
          ),
          // EMUI Legacy
          _IntentCandidate(
            'com.huawei.systemmanager',
            'com.huawei.systemmanager.optimize.process.ProtectActivity',
          ),
          _IntentCandidate(
            'com.huawei.systemmanager',
            'com.huawei.systemmanager.optimize.bootstart.BootStartActivity',
          ),
        ];
      } else if (manufacturer.contains('samsung')) {
        candidates = [
          _IntentCandidate(
            'com.samsung.android.lool',
            'com.samsung.android.sm.battery.ui.BatteryActivity',
          ),
          _IntentCandidate(
            'com.samsung.android.lool',
            'com.samsung.android.sm.ui.battery.BatteryActivity',
          ),
        ];
      } else if (manufacturer.contains('meizu')) {
        candidates = [
          _IntentCandidate(
            'com.meizu.safe',
            'com.meizu.safe.permission.SmartBGActivity',
          ),
          _IntentCandidate(
            'com.meizu.safe',
            'com.meizu.safe.permission.PermissionMainActivity',
          ),
        ];
      } else if (manufacturer.contains('asus')) {
        candidates = [
          _IntentCandidate(
            'com.asus.mobilemanager',
            'com.asus.mobilemanager.entry.FunctionActivity',
          ),
        ];
      }

      bool launched = false;
      for (final candidate in candidates) {
        try {
          final success = await _channel.invokeMethod<bool>('launchIntent', {
            'action': 'android.intent.action.MAIN',
            'package': candidate.package,
            'component': candidate.component,
            'flags': 268435456, // FLAG_ACTIVITY_NEW_TASK
          });

          if (success == true) {
            launched = true;
            debugPrint(
              '✅ Intent lanzado exitosamente: ${candidate.package}/${candidate.component}',
            );
            break;
          }
        } catch (e) {
          debugPrint('⚠️ Falló candidato ${candidate.package}: $e');
        }
      }

      if (!launched) {
        debugPrint(
          '⚠️ Ningún intent específico funcionó, abriendo configuración general',
        );
        await _openAppSettings();
      }
    } catch (e) {
      debugPrint('❌ Error abriendo configuración de auto-inicio: $e');
      await _openAppSettings();
    }
  }

  static Future<void> _openAppSettings() async {
    try {
      await _channel.invokeMethod('launchIntent', {
        'action': 'android.settings.APPLICATION_DETAILS_SETTINGS',
        'data': 'package:com.example.feelin_pay', // Corregido ID
      });
    } catch (e) {
      debugPrint('Error abriendo app settings: $e');
    }
  }

  /// Verifica si el fabricante es uno de los que requiere configuración manual de auto-inicio
  static Future<bool> isManufacturerSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final supportedList = [
        'xiaomi',
        'redmi',
        'poco',
        'oppo',
        'realme',
        'oneplus',
        'vivo',
        'huawei',
        'honor',
        'samsung',
        'meizu',
        'asus',
      ];
      return supportedList.any((m) => manufacturer.contains(m));
    } catch (e) {
      debugPrint('⚠️ Error detectando soporte de auto-inicio: $e');
      return false;
    }
  }

  /// Devuelve instrucciones específicas según la marca para el diálogo UI
  static Future<String> getAutoStartGuidance() async {
    if (!Platform.isAndroid) {
      return 'Activa el inicio automático en la configuración.';
    }

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      if (manufacturer.contains('xiaomi') ||
          manufacturer.contains('redmi') ||
          manufacturer.contains('poco')) {
        return '1. Busca "Feelin Pay" en la lista.\n2. ACTIVA el interruptor "Inicio automático".';
      } else if (manufacturer.contains('huawei') ||
          manufacturer.contains('honor')) {
        return '1. Busca "Feelin Pay".\n2. DESACTIVA el interruptor "Gestionar automáticamente".\n3. Asegúrate de que los 3 interruptores manuales (Inicio auto, secundario, 2do plano) estén ACTIVOS.';
      } else if (manufacturer.contains('samsung')) {
        return '1. Busca "Feelin Pay".\n2. Asegúrate de que NO esté en la lista de "Aplicaciones inactivas" o activa "Batería no restringida".';
      } else if (manufacturer.contains('oppo') ||
          manufacturer.contains('realme') ||
          manufacturer.contains('oneplus') ||
          manufacturer.contains('vivo')) {
        return '1. Busca "Feelin Pay".\n2. ACTIVA el permiso de "Inicio automático" o "Inicio en segundo plano".';
      } else {
        return 'Busca la configuración de batería o inicio y permite que Feelin Pay se ejecute en segundo plano.';
      }
    } catch (e) {
      return 'Habilita el inicio automático para Feelin Pay.';
    }
  }
}

class _IntentCandidate {
  final String package;
  final String component;
  _IntentCandidate(this.package, this.component);
}
