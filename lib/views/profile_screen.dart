import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../widgets/snackbar_helper.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/payment_notification_service.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // OPTIMIZATION: Removed AnimationController and TickerProviderStateMixin

  @override
  void initState() {
    super.initState();
  }

  // OPTIMIZATION: Removed _initializeAnimations and dispose()

  bool _isBridgeModeActive = false;

  Widget _buildBridgeModeSection() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _isBridgeModeActive
              ? DesignSystem.primaryColor
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phonelink_ring_outlined,
                color: _isBridgeModeActive
                    ? DesignSystem.primaryColor
                    : DesignSystem.textSecondary,
                size: 24,
              ),
              const SizedBox(width: DesignSystem.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feelin Pay - Recepción Yape',
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeM,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isBridgeModeActive
                          ? 'Feelin Pay está sincronizando cobros...'
                          : 'Usa Feelin Pay en el celular que recibe los Yapes.',
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeS,
                        color: _isBridgeModeActive
                            ? DesignSystem.primaryColor
                            : DesignSystem.textSecondary,
                        fontWeight: _isBridgeModeActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBridgeModeActive,
                activeTrackColor: DesignSystem.primaryColor,
                activeThumbColor: Colors.white,
                onChanged: (val) async {
                  setState(() => _isBridgeModeActive = val);
                  final authController = Provider.of<AuthController>(
                    context,
                    listen: false,
                  );

                  if (val) {
                    // Inicializar con usuario actual para el servicio
                    if (authController.currentUser != null) {
                      await PaymentNotificationService.init(
                        authController.currentUser!,
                      );
                      await PaymentNotificationService.startListening();
                    }
                    if (!mounted) return;

                    SnackBarHelper.showSuccess(
                      context,
                      'Feelin Pay: Receptor ACTIVADO. No cierres la app.',
                    );
                  } else {
                    await PaymentNotificationService.stopListening();
                    if (!mounted) return;

                    SnackBarHelper.showInfo(
                      context,
                      'Feelin Pay: Recepción desactivada.',
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;
    final isSuperAdmin = authController.isSuperAdmin;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: Column(
        children: [
          const AppHeader(title: 'Mi Perfil', showUserInfo: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignSystem.spacingM),
              child: Column(
                children: [
                  _buildProfileInfo(user),
                  const SizedBox(height: DesignSystem.spacingL),
                  _buildQuickActions(isSuperAdmin),
                  const SizedBox(height: DesignSystem.spacingL),
                  if (!isSuperAdmin) _buildBridgeModeSection(),
                  const SizedBox(height: DesignSystem.spacingL),
                  if (isSuperAdmin) _buildAdminSettings(),
                  const SizedBox(height: DesignSystem.spacingL),
                  _buildLogoutSection(context),
                  const SizedBox(height: DesignSystem.spacingXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nombre ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: DesignSystem.fontSizeXL,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignSystem.radiusS,
                        ),
                      ),
                      child: Text(
                        user?.rol == 'super_admin'
                            ? 'Super Administrador'
                            : 'Propietario',
                        style: const TextStyle(
                          fontSize: DesignSystem.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: DesignSystem.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacingM),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: user?.email ?? '',
            isVerified: true, // Google siepmre verifica
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isVerified = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DesignSystem.textSecondary),
        const SizedBox(width: DesignSystem.spacingS),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: DesignSystem.fontSizeM,
            fontWeight: FontWeight.w500,
            color: DesignSystem.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeM,
              color: DesignSystem.textPrimary,
            ),
          ),
        ),
        if (isVerified)
          const Icon(
            Icons.verified,
            color: DesignSystem.primaryColor,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildQuickActions(bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeL,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Configurar alertas',
                  onTap: _showNotificationSettings,
                ),
              ),
              const SizedBox(width: DesignSystem.spacingM),
              // Eliminado Seguridad
              Expanded(
                child: _buildActionCard(
                  icon: Icons.help_outline,
                  title: 'Ayuda',
                  subtitle: 'Centro de soporte',
                  onTap: () => SnackBarHelper.showInfo(context, 'Próximamente'),
                ),
              ),
            ],
          ),
          if (isSuperAdmin) ...[
            const SizedBox(height: DesignSystem.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Panel Admin',
                    subtitle: 'Gestión del sistema',
                    onTap: _showAdminPanel,
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.analytics_outlined,
                    title: 'Reportes',
                    subtitle: 'Ver estadísticas',
                    onTap: _showReports,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusM),
      child: Container(
        padding: const EdgeInsets.all(DesignSystem.spacingM),
        decoration: BoxDecoration(
          color: DesignSystem.backgroundColor,
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          border: Border.all(
            color: DesignSystem.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: DesignSystem.primaryColor, size: 24),
            const SizedBox(height: DesignSystem.spacingS),
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignSystem.fontSizeS,
                fontWeight: FontWeight.w600,
                color: DesignSystem.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: DesignSystem.fontSizeXS,
                color: DesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSettings() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: DesignSystem.primaryColor,
                size: 20,
              ),
              const SizedBox(width: DesignSystem.spacingS),
              const Text(
                'Configuración Administrativa',
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeL,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacingM),
          _buildSettingsItem(
            icon: Icons.people_outline,
            title: 'Gestión de Usuarios',
            subtitle: 'Administrar usuarios y roles',
            onTap: _manageUsers,
          ),
          _buildSettingsItem(
            icon: Icons.business_outlined,
            title: 'Gestión de Negocios',
            subtitle: 'Administrar negocios y empleados',
            onTap: _manageBusinesses,
          ),
          _buildSettingsItem(
            icon: Icons.analytics_outlined,
            title: 'Reportes del Sistema',
            subtitle: 'Ver estadísticas y métricas',
            onTap: _showSystemReports,
          ),
          _buildSettingsItem(
            icon: Icons.settings_system_daydream_outlined,
            title: 'Configuración del Sistema',
            subtitle: 'Ajustes globales de la aplicación',
            onTap: _showSystemSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DesignSystem.spacingM,
          horizontal: DesignSystem.spacingS,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignSystem.spacingS),
              decoration: BoxDecoration(
                color: DesignSystem.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignSystem.radiusS),
              ),
              child: Icon(icon, color: DesignSystem.primaryColor, size: 20),
            ),
            const SizedBox(width: DesignSystem.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: DesignSystem.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: DesignSystem.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: DesignSystem.fontSizeS,
                      color: DesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  color: DesignSystem.textTertiary,
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _logout(),
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: DesignSystem.spacingM,
            horizontal: DesignSystem.spacingS,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.spacingS),
                decoration: BoxDecoration(
                  color: DesignSystem.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                ),
                child: const Icon(
                  Icons.logout_outlined,
                  color: DesignSystem.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignSystem.spacingM),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: DesignSystem.errorColor,
                      ),
                    ),
                    Text(
                      'Salir de la aplicación',
                      style: TextStyle(
                        fontSize: DesignSystem.fontSizeS,
                        color: DesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: DesignSystem.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos de acción
  void _showNotificationSettings() {
    SnackBarHelper.showInfo(
      context,
      'Abriendo configuración de notificaciones...',
    );
  }

  void _showAdminPanel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo panel de administración...')),
    );
  }

  void _showReports() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mostrando reportes...')));
  }

  void _manageUsers() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gestionando usuarios...')));
  }

  void _manageBusinesses() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gestionando negocios...')));
  }

  void _showSystemReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mostrando reportes del sistema...')),
    );
  }

  void _showSystemSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo configuración del sistema...')),
    );
  }

  void _logout() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: DesignSystem.errorColor,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: DesignSystem.primaryColor),
        ),
      );

      try {
        await authController.logout();

        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: DesignSystem.errorColor,
            ),
          );
        }
      }
    }
  }
}
