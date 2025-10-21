import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../services/user_management_service.dart';
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

  final UserManagementService _userService = UserManagementService();
  
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

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _userService.getStatistics();
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _statistics = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar estadísticas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final currentUser = authController.currentUser;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header con gradiente
            Container(
              padding: const EdgeInsets.all(DesignSystem.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.primaryColor,
                    DesignSystem.primaryLight,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DesignSystem.radiusXL),
                  bottomRight: Radius.circular(DesignSystem.radiusXL),
                ),
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
                          borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                        ),
                        child: const Icon(
                          Icons.dashboard_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: DesignSystem.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Colors.white70],
                              ).createShader(bounds),
                              child: const Text(
                                'Dashboard Administrativo',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              'Bienvenido, ${currentUser?.nombre ?? 'Administrador'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ThreeDotsMenuWidget(
                        items: [
                          ThreeDotsMenuItem(
                            icon: Icons.refresh,
                            title: 'Actualizar',
                            onTap: _loadStatistics,
                          ),
                          ThreeDotsMenuItem(
                            icon: Icons.download,
                            title: 'Exportar Datos',
                            onTap: () {
                              // TODO: Implementar exportación
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: DesignSystem.errorColor,
                              ),
                              const SizedBox(height: DesignSystem.spacingM),
                              Text(
                                _error!,
                                style: TextStyle(
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
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(DesignSystem.spacingM),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Estadísticas principales
                                  _buildStatsSection(),
                                  const SizedBox(height: DesignSystem.spacingXL),
                                  
                                  // Gráficos y análisis
                                  _buildAnalyticsSection(),
                                  const SizedBox(height: DesignSystem.spacingXL),
                                  
                                  // Actividad reciente
                                  _buildRecentActivitySection(),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _statistics ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas Generales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: DesignSystem.spacingM,
          mainAxisSpacing: DesignSystem.spacingM,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total Usuarios',
              value: '${stats['totalUsers'] ?? 0}',
              icon: Icons.people,
              color: DesignSystem.primaryColor,
              trend: stats['usersTrend'] ?? 0,
            ),
            _buildStatCard(
              title: 'Propietarios',
              value: '${stats['totalOwners'] ?? 0}',
              icon: Icons.business,
              color: DesignSystem.primaryLight,
              trend: stats['ownersTrend'] ?? 0,
            ),
            _buildStatCard(
              title: 'Empleados',
              value: '${stats['totalEmployees'] ?? 0}',
              icon: Icons.work,
              color: DesignSystem.secondaryColor,
              trend: stats['employeesTrend'] ?? 0,
            ),
            _buildStatCard(
              title: 'Pagos Hoy',
              value: '${stats['paymentsToday'] ?? 0}',
              icon: Icons.payment,
              color: DesignSystem.accentColor,
              trend: stats['paymentsTrend'] ?? 0,
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
    required double trend,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (trend != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trend > 0 ? DesignSystem.successColor.withOpacity(0.1) : DesignSystem.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend > 0 ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: trend > 0 ? DesignSystem.successColor : DesignSystem.errorColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: trend > 0 ? DesignSystem.successColor : DesignSystem.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: DesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis de Actividad',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        
        Container(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            boxShadow: DesignSystem.shadowM,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: DesignSystem.textTertiary,
              ),
              const SizedBox(height: DesignSystem.spacingM),
              Text(
                'Gráficos de análisis',
                style: TextStyle(
                  color: DesignSystem.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: DesignSystem.spacingS),
              Text(
                'Los gráficos detallados estarán disponibles en la próxima versión',
                style: TextStyle(
                  color: DesignSystem.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        
        Container(
          padding: const EdgeInsets.all(DesignSystem.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            boxShadow: DesignSystem.shadowM,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.history,
                size: 64,
                color: DesignSystem.textTertiary,
              ),
              const SizedBox(height: DesignSystem.spacingM),
              Text(
                'Registro de actividades',
                style: TextStyle(
                  color: DesignSystem.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: DesignSystem.spacingS),
              Text(
                'El registro de actividades estará disponible próximamente',
                style: TextStyle(
                  color: DesignSystem.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}