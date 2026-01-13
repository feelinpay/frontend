import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/system_controller.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';
import '../services/payment_notification_service.dart';
import '../services/sms_service.dart';
import '../services/background_service.dart';
import '../widgets/app_header.dart';

class AndroidPermissionsScreen extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;

  const AndroidPermissionsScreen({super.key, this.onPermissionsGranted});

  @override
  State<AndroidPermissionsScreen> createState() =>
      _AndroidPermissionsScreenState();
}

class _AndroidPermissionsScreenState extends State<AndroidPermissionsScreen>
    with TickerProviderStateMixin {
  Map<Permission, PermissionStatus> _permissions = {};
  bool _notificationListenerGranted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAndNavigateIfGranted();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignSystem.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignSystem.curveEaseOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: DesignSystem.curveEaseOut,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};

    statuses[Permission.sms] = await Permission.sms.status;
    statuses[Permission.notification] = await Permission.notification.status;
    statuses[Permission.ignoreBatteryOptimizations] =
        await Permission.ignoreBatteryOptimizations.status;

    final listenerGranted = await PaymentNotificationService.hasPermission;

    if (mounted) {
      setState(() {
        _permissions = statuses;
        _notificationListenerGranted = listenerGranted;
      });
    }
  }

  bool get _allPermissionsGranted {
    final smsGranted = _permissions[Permission.sms]?.isGranted ?? false;
    final notificationGranted =
        _permissions[Permission.notification]?.isGranted ?? false;
    return smsGranted && notificationGranted && _notificationListenerGranted;
  }

  Future<void> _requestPermissions() async {
    await Permission.sms.request();
    await Permission.notification.request();

    if (!_notificationListenerGranted) {
      await PaymentNotificationService.openSettings();
    }

    await Permission.ignoreBatteryOptimizations.request();
    await _checkPermissions();

    if (_allPermissionsGranted && mounted) {
      _navigateToDashboard();
    }
  }

  Future<void> _checkAndNavigateIfGranted() async {
    await _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAppLifecycleListener();
    });
  }

  void _setupAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(() async {
        await _checkPermissions();
      }),
    );
  }

  void _navigateToDashboard() {
    // Iniciar servicios en segundo plano al entrar al dashboard
    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    if (user != null) {
      debugPrint("🚀 Iniciando servicios desde pantalla de permisos...");
      PaymentNotificationService.init(user).then((_) {
        PaymentNotificationService.startListening(showDialog: false);
      });
      SMSService.procesarSMSPendientes();
      BackgroundService.start();
    }

    if (widget.onPermissionsGranted != null) {
      widget.onPermissionsGranted!();
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
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
        title: 'Enviar SMS (Alertas)',
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
        title: 'Listener',
        permission: null,
        isGrantedOverride: _notificationListenerGranted,
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
        if (p.permission != null) {
          await p.permission!.request();
        } else if (p.title == 'Listener') {
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
