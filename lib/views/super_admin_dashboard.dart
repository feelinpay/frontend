import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDashboardContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.dashboard_outlined,
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
                    'Dashboard Administrativo',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vista general del sistema • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: DesignSystem.fontSizeS,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ThreeDotsMenuWidget(
            items: [
              ThreeDotsMenuItem(
                title: 'Exportar reportes',
                icon: Icons.file_download_outlined,
                onTap: () => _exportReports(),
              ),
              ThreeDotsMenuItem(
                title: 'Configuración del sistema',
                icon: Icons.settings_outlined,
                onTap: () => _systemSettings(),
              ),
              ThreeDotsMenuItem(
                title: 'Auditoría',
                icon: Icons.security_outlined,
                onTap: () => _auditLogs(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(),
          const SizedBox(height: DesignSystem.spacingXL),
          _buildRecentActivity(),
          const SizedBox(height: DesignSystem.spacingXL),
          _buildSystemHealth(),
          const SizedBox(height: DesignSystem.spacingXL),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas Generales',
          style: TextStyle(
            fontSize: DesignSystem.fontSizeL,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: DesignSystem.spacingM,
          crossAxisSpacing: DesignSystem.spacingM,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total de Usuarios',
              value: '1,247',
              icon: Icons.people_outline,
              color: DesignSystem.primaryColor,
              trend: '+12%',
              trendUp: true,
            ),
            _buildStatCard(
              title: 'Propietarios Activos',
              value: '89',
              icon: Icons.business_outlined,
              color: DesignSystem.primaryColor,
              trend: '+5%',
              trendUp: true,
            ),
            _buildStatCard(
              title: 'Empleados Registrados',
              value: '2,156',
              icon: Icons.person_outline,
              color: DesignSystem.primaryLight,
              trend: '+18%',
              trendUp: true,
            ),
            _buildStatCard(
              title: 'Pagos Procesados',
              value: '45,892',
              icon: Icons.payment_outlined,
              color: DesignSystem.warningColor,
              trend: '+23%',
              trendUp: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowS,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignSystem.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trendUp ? DesignSystem.primaryColor : DesignSystem.errorColor,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignSystem.fontSizeXS,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacingM),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeS,
              color: DesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: DesignSystem.fontSizeL,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        Container(
          decoration: BoxDecoration(
            color: DesignSystem.surfaceColor,
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            boxShadow: DesignSystem.shadowS,
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.person_add,
                title: 'Nuevo usuario registrado',
                subtitle: 'Juan Pérez - Restaurante El Buen Sabor',
                time: 'Hace 5 minutos',
                color: DesignSystem.primaryColor,
              ),
              _buildDivider(),
              _buildActivityItem(
                icon: Icons.payment,
                title: 'Pago procesado',
                subtitle: 'S/ 150.00 - Farmacia San José',
                time: 'Hace 12 minutos',
                color: DesignSystem.primaryColor,
              ),
              _buildDivider(),
              _buildActivityItem(
                icon: Icons.business,
                title: 'Nuevo negocio activado',
                subtitle: 'Tienda de Electrónicos - Ana Rodríguez',
                time: 'Hace 25 minutos',
                color: DesignSystem.primaryLight,
              ),
              _buildDivider(),
              _buildActivityItem(
                icon: Icons.warning,
                title: 'Sistema de notificaciones',
                subtitle: 'Reinicio automático completado',
                time: 'Hace 1 hora',
                color: DesignSystem.warningColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusS),
            ),
            child: Icon(
              icon,
              color: color,
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
          Text(
            time,
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeXS,
              color: DesignSystem.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      height: 1,
      color: DesignSystem.textTertiary.withOpacity(0.2),
    );
  }

  Widget _buildSystemHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del Sistema',
          style: TextStyle(
            fontSize: DesignSystem.fontSizeL,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        Container(
          padding: const EdgeInsets.all(DesignSystem.spacingM),
          decoration: BoxDecoration(
            color: DesignSystem.surfaceColor,
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            boxShadow: DesignSystem.shadowS,
          ),
          child: Column(
            children: [
              _buildHealthIndicator(
                title: 'Servidor Principal',
                status: 'Operativo',
                color: DesignSystem.primaryColor,
                percentage: 98,
              ),
              const SizedBox(height: DesignSystem.spacingM),
              _buildHealthIndicator(
                title: 'Base de Datos',
                status: 'Estable',
                color: DesignSystem.primaryColor,
                percentage: 95,
              ),
              const SizedBox(height: DesignSystem.spacingM),
              _buildHealthIndicator(
                title: 'Notificaciones SMS',
                status: 'Activo',
                color: DesignSystem.primaryColor,
                percentage: 92,
              ),
              const SizedBox(height: DesignSystem.spacingM),
              _buildHealthIndicator(
                title: 'API Externa',
                status: 'Limitado',
                color: DesignSystem.warningColor,
                percentage: 78,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator({
    required String title,
    required String status,
    required Color color,
    required int percentage,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: DesignSystem.fontSizeM,
                  color: DesignSystem.textPrimary,
                ),
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeS,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: DesignSystem.spacingS),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: DesignSystem.fontSizeS,
                color: DesignSystem.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignSystem.spacingS),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: DesignSystem.textTertiary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
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
              child: _buildActionButton(
                title: 'Gestionar Usuarios',
                icon: Icons.people_outline,
                color: DesignSystem.primaryColor,
                onTap: () => _manageUsers(),
              ),
            ),
            const SizedBox(width: DesignSystem.spacingM),
            Expanded(
              child: _buildActionButton(
                title: 'Ver Negocios',
                icon: Icons.business_outlined,
                color: DesignSystem.primaryLight,
                onTap: () => _manageBusinesses(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignSystem.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: DesignSystem.spacingS),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignSystem.fontSizeS,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _exportReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando reportes...')),
    );
  }

  void _systemSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo configuración del sistema...')),
    );
  }

  void _auditLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo logs de auditoría...')),
    );
  }

  void _manageUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando a gestión de usuarios...')),
    );
  }

  void _manageBusinesses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando a gestión de negocios...')),
    );
  }
}
