import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/admin_drawer.dart';
import '../core/widgets/responsive_widgets.dart';
import '../services/unified_background_service.dart';
import '../services/sms_service.dart';
import '../services/api_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  // OPTIMIZATION: Removed AnimationController and Mixin for performance
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
          debugPrint("🚀 OwnerDashboard: Iniciando servicio unificado...");

          // Inicializar y arrancar servicio unificado
          await UnifiedBackgroundService.initialize(user);
          await UnifiedBackgroundService.start();

          debugPrint("✅ Servicio unificado iniciado correctamente");

          await SMSService.procesarSMSPendientes();
        }
      } catch (e) {
        // Silently fail or log if needed, but don't crash dashboard
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
      // Por ahora usamos datos mock
      // OPTIMIZATION: Removed artificial delay for immediate loading
      // await Future.delayed(const Duration(milliseconds: 500));

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
    }
  }

  // TEST FUNCTION for Google Sheets
  Future<void> _simularPagoTest() async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No usuario autenticado')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏳ Enviando pago de prueba...')),
    );

    try {
      final apiService = ApiService();
      // Using /yape endpoint directly to simulate a notification
      final response = await apiService.post(
        '/payments/yape',
        data: {
          'usuarioId': user.id,
          'nombrePagador': 'TEST USER - ${DateTime.now().second}',
          'monto': 100.0,
          'codigoSeguridad':
              'TEST_CODE', // Only needed for Yape but good to have
          'medioDePago': 'Yape',
          'testMode': true, // Optional flag if backend wants it
        },
      );

      if (response.isSuccess) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Éxito: Revisa tu Google Drive!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error Backend: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error Local: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final currentUser = authController.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DesignSystem.backgroundColor,
      drawer: AdminDrawer(user: currentUser, authController: authController),
      body: Column(
        children: [
          // Header estandarizado con AppHeader
          AppHeader(
            title: 'Dashboard',
            subtitle: 'Panel de control',
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
            _buildShortcutCard(
              title: 'Simular Pago Test',
              icon: Icons.bug_report,
              color: DesignSystem.primaryColor,
              onTap: _simularPagoTest,
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
