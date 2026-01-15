import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../controllers/system_controller.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';
import '../services/payment_notification_service.dart';
import '../widgets/app_header.dart';

class AndroidPermissionsScreen extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;

  const AndroidPermissionsScreen({super.key, this.onPermissionsGranted});

  @override
  State<AndroidPermissionsScreen> createState() =>
      _AndroidPermissionsScreenState();
}

class _AndroidPermissionsScreenState extends State<AndroidPermissionsScreen> {
  // OPTIMIZATION: Removed TickerProviderStateMixin and Animations
  Map<Permission, PermissionStatus> _permissions = {};
  bool _notificationListenerGranted = false;
  bool _isChecking = true; // Empieza en true para evitar flicker inicial
  bool _isNavigating = false; // Guard para evitar navegación doble

  @override
  void initState() {
    super.initState();
    // Solo verificar, NO navegar automáticamente (Respetar deseo del usuario)
    _checkPermissions();
    _setupAppLifecycleListener();
  }

  Future<void> _checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};

    statuses[Permission.sms] = await Permission.sms.status;
    statuses[Permission.notification] = await Permission.notification.status;

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    statuses[Permission.ignoreBatteryOptimizations] = batteryStatus;

    debugPrint('🔋 Estado Batería: $batteryStatus');
    debugPrint(
      '📱 Listener Granted: ${await PaymentNotificationService.hasPermission}',
    );

    final listenerGranted = await PaymentNotificationService.hasPermission;

    if (mounted) {
      setState(() {
        _permissions = statuses;
        _notificationListenerGranted = listenerGranted;
        _isChecking = false;
      });
    }
  }

  bool get _allPermissionsGranted {
    final smsGranted = _permissions[Permission.sms]?.isGranted ?? false;
    final notificationGranted =
        _permissions[Permission.notification]?.isGranted ?? false;
    final batteryGranted =
        _permissions[Permission.ignoreBatteryOptimizations]?.isGranted ?? false;

    return smsGranted &&
        notificationGranted &&
        _notificationListenerGranted &&
        batteryGranted;
  }

  Future<void> _requestPermissions() async {
    // 1. Solicitar permisos básicos
    await [Permission.sms, Permission.notification].request();
    await _checkPermissions();

    // 2. Verificar Listener (Si falta, ir a settings)
    if (!_notificationListenerGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa "Feelin Pay" y regresa a la app'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      await PaymentNotificationService.openSettings();
      // No retornamos aquí para permitir que vea/pida la 4ta opción después si pulsa de nuevo
    }

    // 3. Batería (La famosa 4ta opción)
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    await _checkPermissions();
  }

  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(() async {
        if (mounted) {
          await _checkPermissions();
        }
      }),
    );
  }

  Future<void> _navigateToDashboard() async {
    if (_isNavigating) return;

    if (!_allPermissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor otorga todos los permisos primero'),
        ),
      );
      return;
    }

    _isNavigating = true;

    if (widget.onPermissionsGranted != null) {
      widget.onPermissionsGranted!();
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: DesignSystem.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: DesignSystem.primaryColor,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final systemController = Provider.of<SystemController>(context);

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Configuración inicial',
            subtitle: 'Gestiona los permisos necesarios',
            showUserInfo: true,
          ),
          Expanded(
            child: ResponsiveContainer(
              maxWidth: 600, // Un poco más ancho que el login para el grid
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spacingM,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: DesignSystem.spacingM),
                    _buildModernHeader(context, systemController),
                    const SizedBox(height: DesignSystem.spacingM),
                    _buildPermissionsGrid(context),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildModernHeader(
    BuildContext context,
    SystemController systemController,
  ) {
    final hasInternet = systemController.hasInternetConnection;
    final hasBackend = systemController.isBackendReachable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DesignSystem.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ResponsiveText(
                'Feelin Pay',
                type: TextType.title,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              _buildStatusBadge(hasInternet, hasBackend),
            ],
          ),
          const SizedBox(height: 12),
          ResponsiveText(
            _allPermissionsGranted
                ? '¡Configuración completa! Ya puedes gestionar tus pagos.'
                : 'Esta es la Gestión de Feelin Pay. Activa los permisos para comenzar.',
            type: TextType.body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool hasInternet, bool hasBackend) {
    bool ok = hasInternet && hasBackend;
    String label = !hasInternet
        ? 'SIN RED'
        : (!hasBackend ? 'SIN SERVIDOR' : 'CONECTADO');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (ok ? DesignSystem.successColor : DesignSystem.errorColor)
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsGrid(BuildContext context) {
    final permissions = [
      _PermissionData(
        icon: Icons.sms_outlined,
        title: 'Enviar SMS',
        permission: Permission.sms,
        isRequired: true,
      ),
      _PermissionData(
        icon: Icons.notifications_none_outlined,
        title: 'Notificaciones',
        permission: Permission.notification,
        isRequired: true,
      ),
      _PermissionData(
        icon: Icons.flash_on_outlined,
        title: 'Acceso a Notificaciones',
        permission: null,
        isGrantedOverride: _notificationListenerGranted,
        isRequired: true,
      ),
      _PermissionData(
        icon: Icons.battery_alert,
        title: 'Segundo Plano',
        permission: Permission.ignoreBatteryOptimizations,
        isRequired: true,
      ),
    ];

    return Column(
      children: permissions
          .map((p) => _buildPermissionItem(context, p))
          .toList(),
    );
  }

  Widget _buildPermissionItem(BuildContext context, _PermissionData p) {
    bool isGranted = false;
    if (p.permission != null) {
      isGranted = _permissions[p.permission!]?.isGranted ?? false;
    } else if (p.isGrantedOverride != null) {
      isGranted = p.isGrantedOverride!;
    }

    return InkWell(
      onTap: () async {
        if (p.permission == Permission.ignoreBatteryOptimizations) {
          // Si es batería, SIEMPRE intentar abrir settings para que el usuario verifique
          debugPrint(
            '⚙️ Abriendo configuración de batería para verificación manual',
          );
          await p.permission!.request();
        } else if (p.permission != null) {
          await p.permission!.request();
        } else if (p.permission == null && p.title.contains('Notificaciones')) {
          await PaymentNotificationService.openSettings();
        }
        _checkPermissions();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGranted
                ? DesignSystem.successColor.withValues(alpha: 0.3)
                : DesignSystem.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (isGranted
                            ? DesignSystem.successColor
                            : DesignSystem.primaryColor)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                p.icon,
                color: isGranted
                    ? DesignSystem.successColor
                    : DesignSystem.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                p.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              isGranted ? Icons.check_circle : Icons.pending_outlined,
              color: isGranted
                  ? DesignSystem.successColor
                  : DesignSystem.warningColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveButton(
                text: _allPermissionsGranted ? 'Continuar' : 'Activar Permisos',
                onPressed: () {
                  if (_allPermissionsGranted) {
                    _navigateToDashboard();
                  } else {
                    _requestPermissions();
                  }
                },
                icon: _allPermissionsGranted
                    ? Icons.arrow_forward
                    : Icons.security,
                type: ButtonType.primary,
                size: ButtonSize.medium,
              ),
              if (!_allPermissionsGranted) ...[
                const SizedBox(height: DesignSystem.spacingS),
                ResponsiveButton(
                  text: 'Configurar más tarde',
                  onPressed: _navigateToDashboard,
                  type: ButtonType.text,
                  size: ButtonSize.small,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionData {
  final IconData icon;
  final String title;
  final Permission? permission;
  final bool? isGrantedOverride;
  final bool isRequired;

  _PermissionData({
    required this.icon,
    required this.title,
    this.permission,
    this.isGrantedOverride,
    required this.isRequired,
  });
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppLifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
