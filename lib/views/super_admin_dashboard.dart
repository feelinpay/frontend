import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_header.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/admin_drawer.dart';
import '../core/widgets/responsive_widgets.dart';
import '../services/user_management_service.dart';
import '../services/unified_background_service.dart';
import '../services/payment_notification_service.dart'; // For simulateTestYape

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  // OPTIMIZATION: Removed AnimationController and Mixin for performance
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final UserManagementService _userService = UserManagementService();

  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    // CRITICAL: Start services asynchronously without blocking UI thread
    _startBackgroundServices();
  }

  void _startBackgroundServices() {
    // Capture context before async gap
    final currentContext = context;

    // Run in background without blocking initState
    Future.microtask(() async {
      try {
        final authController = Provider.of<AuthController>(
          // ignore: use_build_context_synchronously
          currentContext,
          listen: false,
        );
        final user = authController.currentUser;

        if (user != null) {
          debugPrint("🚀 SuperAdminDashboard: Iniciando servicio unificado...");

          // Inicializar y arrancar servicio unificado
          await UnifiedBackgroundService.initialize(user);
          await UnifiedBackgroundService.start();

          debugPrint("✅ Servicio unificado iniciado correctamente");
        }
      } catch (e) {
        debugPrint("❌ Error starting unified service: $e");
      }
    });
  }

  // OPTIMIZATION: Removed _initializeAnimations and dispose() as they're no longer needed

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
    final authController = context.watch<AuthController>();
    final currentUser = authController.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      // BOTÓN DE SIMULACIÓN DE YAPE (Solo Debug)
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧪 Simulando Pago Yape...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.orange,
                  ),
                );
                // Ejecutar test en el siguiente frame para no bloquear UI inmediata
                Future.delayed(Duration.zero, () {
                  PaymentNotificationService.simulateTestYape();
                });
              },
              label: const Text('Test Yape'),
              icon: const Icon(Icons.bug_report),
              backgroundColor: Colors.orange,
            )
          : null,
      backgroundColor: DesignSystem.backgroundColor,
      drawer: AdminDrawer(user: currentUser, authController: authController),
      body: Column(
        children: [
          // Header estandarizado con AppHeader
          AppHeader(
            title: 'Dashboard',
            subtitle: 'Panel de administración',
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
                : ResponsiveContainer(
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
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _statistics ?? {};

    final totalAdmins = stats['totalAdmins'] ?? 0;
    final totalPropietarios = stats['totalUsuarios'] ?? 0;
    final totalEmpleados = stats['totalEmpleados'] ?? 0;

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

        // Primera fila: Usuarios
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Super Admins',
                value: totalAdmins.toString(),
                icon: Icons.admin_panel_settings,
                color: const Color(0xFF8B5CF6),
                subtitle: 'Administradores',
              ),
            ),
            const SizedBox(width: DesignSystem.spacingM),
            Expanded(
              child: _buildStatCard(
                title: 'Propietarios',
                value: totalPropietarios.toString(),
                icon: Icons.business,
                color: const Color(0xFF3B82F6),
                subtitle: 'Dueños de negocio',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignSystem.spacingM),

        // Segunda fila: Empleados y Estado
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Empleados',
                value: totalEmpleados.toString(),
                icon: Icons.people,
                color: const Color(0xFF10B981),
                subtitle: 'Todos los empleados',
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
              title: 'Gestión de Usuarios',
              icon: Icons.people_alt,
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.pushNamed(context, '/user-management'),
            ),
            _buildShortcutCard(
              title: 'Mis Empleados',
              icon: Icons.people,
              color: const Color(0xFF10B981),
              onTap: () => Navigator.pushNamed(context, '/employee-management'),
            ),
            _buildShortcutCard(
              title: 'Gestión de Membresías',
              icon: Icons.card_membership,
              color: const Color(0xFF3B82F6),
              onTap: () =>
                  Navigator.pushNamed(context, '/membership-management'),
            ),
            _buildShortcutCard(
              title: 'Reportes de Membresías',
              icon: Icons.bar_chart,
              color: const Color(0xFFEC4899),
              onTap: () => Navigator.pushNamed(context, '/membership-reports'),
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
