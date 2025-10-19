import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Lista de permisos esenciales
  static const List<Permission> _essentialPermissions = [
    Permission.sms,
    Permission.notification,
  ];

  // Verificar si todos los permisos están concedidos
  static Future<bool> areAllPermissionsGranted() async {
    for (final permission in _essentialPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  // Solicitar todos los permisos esenciales
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await _essentialPermissions.request();
  }

  // Verificar estado de un permiso específico
  static Future<PermissionStatus> checkPermission(Permission permission) async {
    return await permission.status;
  }

  // Solicitar un permiso específico
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  // Abrir configuración de la app
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Verificar si es la primera vez que se abren los permisos
  static Future<bool> isFirstTimePermissions() async {
    // Aquí podrías usar SharedPreferences para guardar si ya se mostraron los permisos
    // Por ahora retornamos true para siempre mostrar la pantalla
    return true;
  }

  // Marcar que ya se mostraron los permisos
  static Future<void> markPermissionsShown() async {
    // Aquí podrías usar SharedPreferences para marcar que ya se mostraron
    // Por ahora no hacemos nada
  }

  // Obtener descripción de un permiso
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.sms:
        return 'Para enviar y recibir códigos de verificación';
      case Permission.notification:
        return 'Para recibir alertas de pagos de Yape';
      default:
        return 'Permiso necesario para el funcionamiento de la app';
    }
  }

  // Obtener icono de un permiso
  static IconData getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.sms:
        return Icons.sms;
      case Permission.notification:
        return Icons.notifications;
      default:
        return Icons.security;
    }
  }

  // Obtener título de un permiso
  static String getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.sms:
        return 'SMS';
      case Permission.notification:
        return 'Notificaciones';
      default:
        return 'Permiso';
    }
  }
}