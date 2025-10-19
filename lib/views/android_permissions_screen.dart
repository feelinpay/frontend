import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';

class AndroidPermissionsScreen extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;

  const AndroidPermissionsScreen({Key? key, this.onPermissionsGranted})
    : super(key: key);

  @override
  State<AndroidPermissionsScreen> createState() =>
      _AndroidPermissionsScreenState();
}

class _AndroidPermissionsScreenState extends State<AndroidPermissionsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  Map<Permission, PermissionStatus> _permissions = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
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
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    setState(() => _isLoading = true);

    final permissions = [Permission.sms, Permission.notification];

    final statuses = await permissions.request();

    setState(() {
      _permissions = statuses;
      _isLoading = false;
    });
  }

  // Verificar si todos los permisos están concedidos
  bool get _allPermissionsGranted {
    final smsGranted = _permissions[Permission.sms]?.isGranted ?? false;
    final notificationGranted =
        _permissions[Permission.notification]?.isGranted ?? false;
    // El permiso de segundo plano se considera concedido si los otros están concedidos
    return smsGranted && notificationGranted;
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // Solicitar permisos uno por uno
    await Permission.sms.request();
    await Permission.notification.request();

    // Verificar estado final
    await _checkPermissions();

    // Si todos los permisos están concedidos, navegar automáticamente
    if (_allPermissionsGranted) {
      if (widget.onPermissionsGranted != null) {
        widget.onPermissionsGranted!();
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _openNotificationSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: ResponsiveContainer(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          SizedBox(
                            height: DesignSystem.getResponsivePadding(context),
                          ),
                          _buildPermissionsList(context),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DesignSystem.getResponsivePadding(context)),
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: DesignSystem.iconSizeL,
                ),
              ),
              SizedBox(width: DesignSystem.spacingM),
              Expanded(
                child: ResponsiveText(
                  'Permisos Necesarios',
                  type: TextType.display,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.spacingM),
          ResponsiveText(
            _allPermissionsGranted
                ? '¡Excelente! Todos los permisos necesarios han sido concedidos. La aplicación está lista para funcionar.'
                : 'Feelin Pay necesita 2 permisos: SMS para notificar empleados y Notificaciones para detectar pagos de Yape automáticamente.',
            type: TextType.body,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList(BuildContext context) {
    final permissions = [
      _PermissionData(
        icon: Icons.sms,
        title: 'SMS',
        description: 'Para notificar a empleados cuando recibas pagos de Yape',
        permission: Permission.sms,
        isRequired: true,
      ),
      _PermissionData(
        icon: Icons.notifications,
        title: 'Lectura de Notificaciones',
        description: 'Para leer notificaciones de pagos de Yape (Perú)',
        permission: Permission.notification,
        isRequired: true,
      ),
    ];

    return Column(
      children: permissions
          .map(
            (permission) => Padding(
              padding: const EdgeInsets.only(bottom: DesignSystem.spacingM),
              child: _buildPermissionCard(context, permission),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    _PermissionData permissionData,
  ) {
    PermissionStatus status;
    if (permissionData.permission != null) {
      status =
          _permissions[permissionData.permission!] ?? PermissionStatus.denied;
    } else {
      // Para el permiso de "Segundo Plano", considerarlo concedido si los otros están concedidos
      status = _allPermissionsGranted
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.spacingM),
                decoration: BoxDecoration(
                  color: permissionData.isRequired
                      ? DesignSystem.primaryColor.withOpacity(0.1)
                      : DesignSystem.textTertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                ),
                child: Icon(
                  permissionData.icon,
                  color: permissionData.isRequired
                      ? DesignSystem.primaryColor
                      : DesignSystem.textTertiary,
                  size: DesignSystem.iconSizeM,
                ),
              ),
              SizedBox(width: DesignSystem.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ResponsiveText(
                            permissionData.title,
                            type: TextType.title,
                          ),
                        ),
                        if (permissionData.isRequired) ...[
                          const SizedBox(width: DesignSystem.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignSystem.spacingS,
                              vertical: DesignSystem.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: DesignSystem.errorColor,
                              borderRadius: BorderRadius.circular(
                                DesignSystem.radiusS,
                              ),
                            ),
                            child: const ResponsiveText(
                              'REQUERIDO',
                              type: TextType.caption,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: DesignSystem.spacingS),
                    ResponsiveText(
                      permissionData.description,
                      type: TextType.body,
                      style: const TextStyle(color: DesignSystem.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: DesignSystem.spacingM),
              _buildStatusIndicator(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(PermissionStatus status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case PermissionStatus.granted:
        statusColor = DesignSystem.successColor;
        statusIcon = Icons.check_circle;
        break;
      case PermissionStatus.denied:
        statusColor = DesignSystem.warningColor;
        statusIcon = Icons.cancel;
        break;
      case PermissionStatus.permanentlyDenied:
        statusColor = DesignSystem.errorColor;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = DesignSystem.textTertiary;
        statusIcon = Icons.pending;
    }

    return Column(
      children: [
        Icon(statusIcon, color: statusColor, size: DesignSystem.iconSizeS),
        SizedBox(height: DesignSystem.spacingXS),
        ResponsiveText(
          _getStatusText(status),
          type: TextType.caption,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Concedido';
      case PermissionStatus.denied:
        return 'Denegado';
      case PermissionStatus.permanentlyDenied:
        return 'Denegado permanentemente';
      default:
        return 'Pendiente';
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.getResponsivePadding(context)),
      child: Column(
        children: [
          if (_allPermissionsGranted) ...[
            // Botón de continuar cuando todos los permisos están concedidos
            ResponsiveButton(
              text: 'Continuar al Login',
              onPressed: () {
                if (widget.onPermissionsGranted != null) {
                  widget.onPermissionsGranted!();
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: Icons.check_circle,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
            SizedBox(height: DesignSystem.spacingM),
            ResponsiveButton(
              text: 'Verificar Permisos',
              onPressed: _isLoading ? null : _checkPermissions,
              isLoading: _isLoading,
              icon: Icons.refresh,
              type: ButtonType.secondary,
              size: ButtonSize.medium,
            ),
          ] else ...[
            // Botones cuando faltan permisos
            ResponsiveButton(
              text: 'Solicitar Permisos',
              onPressed: _isLoading ? null : _requestPermissions,
              isLoading: _isLoading,
              icon: Icons.security,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
            SizedBox(height: DesignSystem.spacingM),
            ResponsiveButton(
              text: 'Configurar en Ajustes',
              onPressed: _openNotificationSettings,
              icon: Icons.settings,
              type: ButtonType.secondary,
              size: ButtonSize.large,
            ),
            SizedBox(height: DesignSystem.spacingM),
            // Mensaje de advertencia en lugar del botón de continuar
            Container(
              padding: const EdgeInsets.all(DesignSystem.spacingM),
              decoration: BoxDecoration(
                color: DesignSystem.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                border: Border.all(
                  color: DesignSystem.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: DesignSystem.warningColor,
                    size: DesignSystem.iconSizeM,
                  ),
                  SizedBox(width: DesignSystem.spacingM),
                  Expanded(
                    child: ResponsiveText(
                      'La aplicación necesita estos 2 permisos para notificar empleados y detectar pagos de Yape automáticamente',
                      type: TextType.body,
                      style: TextStyle(
                        color: DesignSystem.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionData {
  final IconData icon;
  final String title;
  final String description;
  final Permission? permission;
  final bool isRequired;
  _PermissionData({
    required this.icon,
    required this.title,
    required this.description,
    this.permission,
    required this.isRequired,
  });
}
