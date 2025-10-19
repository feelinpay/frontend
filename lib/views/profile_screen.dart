import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../widgets/phone_field_widget.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;
    final isSuperAdmin = authController.isSuperAdmin;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            child: Column(
              children: [
                _buildHeader(user, isSuperAdmin),
                const SizedBox(height: DesignSystem.spacingL),
                _buildProfileInfo(user),
                const SizedBox(height: DesignSystem.spacingL),
                _buildQuickActions(isSuperAdmin),
                const SizedBox(height: DesignSystem.spacingL),
                _buildAccountSettings(user),
                const SizedBox(height: DesignSystem.spacingL),
                if (isSuperAdmin) _buildAdminSettings(),
                const SizedBox(height: DesignSystem.spacingL),
                _buildLogoutSection(context),
                const SizedBox(height: DesignSystem.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user, bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spacingM,
        DesignSystem.spacingL,
        DesignSystem.spacingM,
        DesignSystem.spacingM,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignSystem.primaryColor.withOpacity(0.05),
            DesignSystem.primaryLight.withOpacity(0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignSystem.primaryColor, DesignSystem.primaryLight],
              ),
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: DesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [DesignSystem.primaryColor, DesignSystem.primaryLight],
                  ).createShader(bounds),
                  child: const Text(
                    'Mi Perfil',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isSuperAdmin ? 'Super Administrador' : 'Propietario de Negocio'} • ${user?.email ?? ''}',
                  style: const TextStyle(
                    fontSize: DesignSystem.fontSizeS,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(user) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                        color: DesignSystem.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                      ),
                      child: Text(
                        user?.rol == 'super_admin' ? 'Super Administrador' : 'Propietario',
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
            isVerified: user?.emailVerificado == true,
          ),
          const SizedBox(height: DesignSystem.spacingS),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: user?.telefono ?? 'No registrado',
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
        Icon(
          icon,
          size: 18,
          color: DesignSystem.textSecondary,
        ),
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
            color: Colors.black.withOpacity(0.05),
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
              Expanded(
                child: _buildActionCard(
                  icon: Icons.security_outlined,
                  title: 'Seguridad',
                  subtitle: 'Cambiar contraseña',
                  onTap: _changePassword,
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
            color: DesignSystem.textTertiary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: DesignSystem.primaryColor,
              size: 24,
            ),
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

  Widget _buildAccountSettings(user) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración de Cuenta',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeL,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingM),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            subtitle: 'Modificar nombre y teléfono',
            onTap: _editProfile,
          ),
          _buildSettingsItem(
            icon: Icons.email_outlined,
            title: 'Correo Electrónico',
            subtitle: user?.email ?? '',
            onTap: _changeEmail,
            trailing: user?.emailVerificado == true
                ? const Icon(Icons.verified, color: DesignSystem.primaryColor, size: 20)
                : const Icon(Icons.warning_amber, color: DesignSystem.warningColor, size: 20),
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Seguridad',
            subtitle: 'Cambiar contraseña y 2FA',
            onTap: _showSecuritySettings,
          ),
        ],
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
            color: Colors.black.withOpacity(0.05),
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
                color: DesignSystem.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignSystem.radiusS),
              ),
              child: Icon(
                icon,
                color: DesignSystem.primaryColor,
                size: 20,
              ),
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
            trailing ?? const Icon(
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _logout(context),
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
                  color: DesignSystem.errorColor.withOpacity(0.1),
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
  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(
        user: Provider.of<AuthController>(context, listen: false).currentUser,
        onSave: (updatedUser) {
          // Aquí se actualizaría el usuario en el backend
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado exitosamente')),
          );
        },
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo configuración de notificaciones...')),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambiando contraseña...')),
    );
  }

  void _changeEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambiando correo electrónico...')),
    );
  }

  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo configuración de seguridad...')),
    );
  }


  void _showAdminPanel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo panel de administración...')),
    );
  }

  void _showReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mostrando reportes...')),
    );
  }

  void _manageUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestionando usuarios...')),
    );
  }

  void _manageBusinesses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestionando negocios...')),
    );
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

  void _logout(BuildContext context) async {
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

    if (confirmed == true) {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: DesignSystem.primaryColor,
          ),
        ),
      );

      try {
        // Ejecutar logout
        await authController.logout();
        
        // Cerrar el diálogo de carga
        if (mounted) {
          Navigator.pop(context);
          
          // Navegar al login
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        // Cerrar el diálogo de carga
        if (mounted) {
          Navigator.pop(context);
          
          // Mostrar error
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

class _EditProfileDialog extends StatefulWidget {
  final dynamic user;
  final Function(dynamic) onSave;

  const _EditProfileDialog({
    required this.user,
    required this.onSave,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.nombre ?? '');
    _phoneController = TextEditingController(text: widget.user?.telefono ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      title: const Text('Editar Perfil'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Tu nombre completo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: DesignSystem.spacingM,
                  horizontal: DesignSystem.spacingM,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: DesignSystem.spacingM),
            PhoneFieldWidget(
              controller: _phoneController,
              labelText: 'Teléfono',
              hintText: 'Tu número de teléfono',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El teléfono es requerido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: DesignSystem.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Crear un usuario actualizado (simulado)
              final updatedUser = {
                'nombre': _nameController.text,
                'telefono': _phoneController.text,
                'email': widget.user?.email,
                'rol': widget.user?.rol,
              };
              widget.onSave(updatedUser);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryColor,
            foregroundColor: DesignSystem.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}