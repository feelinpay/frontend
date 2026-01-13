import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/admin_drawer.dart';
import '../core/widgets/responsive_widgets.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStatistics();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Por ahora usamos datos mock
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _statistics = {
          'totalEmpleados': 0,
          'empleadosActivos': 0,
          'empleadosInactivos': 0,
          'pagosDelMes': 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar estadísticas: $e';
        _isLoading = false;
      });
      // Error silenced
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final currentUser = authController.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DesignSystem.backgroundColor,
      drawer: AdminDrawer(user: currentUser, authController: authController),
      body: Column(
        children: [
          // Header estandarizado con AppHeader
          AppHeader(
            title: 'Feelin Pay',
            subtitle: 'Bienvenido, ${currentUser?.nombre ?? 'Propietario'}',
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            menuItems: [
              ThreeDotsMenuItem(
                icon: Icons.refresh,
                title: 'Actualizar',
                onTap: _loadStatistics,
              ),
            ],
          ),

          // Contenido principal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DesignSystem.primaryColor,
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: DesignSystem.errorColor,
                        ),
                        const SizedBox(height: DesignSystem.spacingM),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: DesignSystem.errorColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignSystem.spacingM),
                        ElevatedButton(
                          onPressed: _loadStatistics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ResponsiveContainer(
                        maxWidth: 1000,
                        padding: const EdgeInsets.all(DesignSystem.spacingM),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estadísticas principales
                              _buildStatsSection(),
                              const SizedBox(height: DesignSystem.spacingXL),

                              // Atajos de Gestión
                              _buildManagementShortcuts(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _statistics ?? {};

    final totalEmpleados = stats['totalEmpleados'] ?? 0;
    final empleadosActivos = stats['empleadosActivos'] ?? 0;
    final empleadosInactivos = stats['empleadosInactivos'] ?? 0;
    final pagosDelMes = stats['pagosDelMes'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Estadísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),

        // Primera fila: Empleados
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Empleados',
                value: totalEmpleados.toString(),
                icon: Icons.people,
                color: const Color(0xFF10B981),
                subtitle: 'Mis empleados',
              ),
            ),
            const SizedBox(width: DesignSystem.spacingM),
            Expanded(
              child: _buildStatCard(
                title: 'Empleados Activos',
                value: empleadosActivos.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF22C55E),
                subtitle: '$empleadosInactivos inactivos',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignSystem.spacingM),

        // Segunda fila: Pagos
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pagos del Mes',
                value: pagosDelMes.toString(),
                icon: Icons.payment,
                color: const Color(0xFF3B82F6),
                subtitle: 'Transacciones',
              ),
            ),
            const SizedBox(width: DesignSystem.spacingM),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(DesignSystem.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                  boxShadow: DesignSystem.shadowM,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 48,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ),
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
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: DesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementShortcuts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos Rápidos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),

        // Grilla de Atajos Dinámica
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: DesignSystem.isMobile(context)
              ? 2
              : DesignSystem.getResponsiveColumns(context),
          mainAxisSpacing: DesignSystem.spacingS,
          crossAxisSpacing: DesignSystem.spacingS,
          childAspectRatio: DesignSystem.isMobile(context) ? 2.2 : 3.0,
          children: [
            _buildShortcutCard(
              title: 'Mis Empleados',
              icon: Icons.people,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.pushNamed(context, '/employee-management'),
            ),
            _buildShortcutCard(
              title: 'Horarios y Jornadas',
              icon: Icons.schedule,
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.pushNamed(context, '/schedule-management'),
            ),
            _buildShortcutCard(
              title: 'Gestión de Permisos',
              icon: Icons.security,
              color: const Color(0xFFF59E0B),
              onTap: () =>
                  Navigator.pushNamed(context, '/permissions-management'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.spacingS,
          vertical: DesignSystem.spacingS,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DesignSystem.textPrimary,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
