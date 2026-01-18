import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class AutoStartService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Intenta abrir la configuración de inicio automático según el fabricante
  static Future<void> openAutoStartSettings() async {
    if (!Platform.isAndroid) return;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      debugPrint('📱 Detectado fabricante: $manufacturer');

      String? package;
      String? component;

      // Mapeo de intents conocidos para Auto-Start
      if (manufacturer.contains('xiaomi') ||
          manufacturer.contains('redmi') ||
          manufacturer.contains('poco')) {
        package = 'com.miui.securitycenter';
        component = 'com.miui.permcenter.autostart.AutoStartManagementActivity';
      } else if (manufacturer.contains('oppo')) {
        package = 'com.coloros.safecenter';
        component =
            'com.coloros.safecenter.permission.startup.StartupAppListActivity';
      } else if (manufacturer.contains('vivo')) {
        package = 'com.vivo.permissionmanager';
        component =
            'com.vivo.permissionmanager.activity.BgStartUpManagerActivity';
      } else if (manufacturer.contains('huawei') ||
          manufacturer.contains('honor')) {
        package = 'com.huawei.systemmanager';
        component = 'com.huawei.systemmanager.optimize.process.ProtectActivity';
      } else if (manufacturer.contains('samsung')) {
        package = 'com.samsung.android.lool';
        component = 'com.samsung.android.sm.ui.battery.BatteryActivity';
      } else if (manufacturer.contains('asus')) {
        package = 'com.asus.mobilemanager';
        component = 'com.asus.mobilemanager.entry.FunctionActivity';
      }
      // Fallback a configuración de aplicación si no se conoce el fabricante específico
      else {
        await _openAppSettings();
        return;
      }

      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: package,
          componentName: component,
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } catch (e) {
        debugPrint(
          '⚠️ Falló intent específico, abriendo configuración general: $e',
        );
        await _openAppSettings();
      }
    } catch (e) {
      debugPrint('❌ Error abriendo configuración de auto-inicio: $e');
      await _openAppSettings();
    }
  }

  static Future<void> _openAppSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data:
          'package:com.feelin.pay.feelin_pay', // Asegúrate de que este sea el package id correcto
    );
    await intent.launch();
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
        'vivo',
        'huawei',
        // 'honor', // REMOVED: Honor no tiene configuración confiable de auto-start
        'samsung',
        'asus',
      ];
      return supportedList.any((m) => manufacturer.contains(m));
    } catch (e) {
      debugPrint('⚠️ Error detectando soporte de auto-inicio: $e');
      return false;
    }
  }
}
