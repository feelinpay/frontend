import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/design/design_system.dart';
import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';
import '../controllers/auth_controller.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/admin_drawer.dart';
import '../core/widgets/responsive_widgets.dart';
import '../services/unified_background_service.dart';
import '../services/sms_service.dart';

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

          // 1. Verificar permiso de Notifications Listener
          bool hasPermission = false;
          try {
            hasPermission =
                (await NotificationsListener.hasPermission) ?? false;
          } catch (e) {
            debugPrint("⚠️ Error verificando permisos de listener: $e");
          }

          if (!mounted) return;

          if (!hasPermission) {
            debugPrint("⚠️ Permiso de notificaciones perdido/no otorgado.");
            // Mostrar diálogo de advertencia
            // ignore: use_build_context_synchronously
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Permiso Requerido'),
                content: const Text(
                  'El permiso de "Acceso a Notificaciones" se ha desactivado.\n\n'
                  'Sin este permiso, la app NO puede detectar los pagos de Yape/Plin.\n\n'
                  'Por favor, actívalo nuevamente.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                          context); // Cerrar diálogo, pero riesgo de no funcionar
                    },
                    child: const Text('Más tarde'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      NotificationsListener.openPermissionSettings();
                    },
                    child: const Text('Activar Ahora'),
                  ),
                ],
              ),
            );
          } else {
            // 2. Inicializar y arrancar servicio unificado solo si hay permiso (o intentar igual)
            await UnifiedBackgroundService.initialize(user);
            await UnifiedBackgroundService.start();

            debugPrint("✅ Servicio unificado iniciado correctamente");
            await SMSService.procesarSMSPendientes();
          }
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

      // NOTE: We are mocking data here, so 403 is unlikely unless we call a real endpoint.
      // But if we add real calls later, this logic is ready.
      // For now, if we had a real call:
      // var response = await _ownerService.getStats(); ...

      // Since OwnerDashboard currently mocks data (lines 81-86), it won't trigger 403 yet.
      // However, to respect the user's request for robustness, I will leave the structure ready
      // or check if there's any other real call.
      // The current code (lines 76-95) is purely local set state with mock data.

      // Wait! The user said "Sucedío con todas las vistas".
      // If OwnerDashboard uses mock data, how did it get "No tienes permisos"?
      // Ah, maybe they clicked a BUTTON that triggers a real call?
      // "Configuración del Sistema", "Gestión de Permisos", etc.

      // If the dashboard MAIN view is failing, it implies `_loadStatistics` is doing something real.
      // Looking at the CODE I viewed earlier for OwnerDashboard:
      // It sets `_statistics` to a Map literal. It does NOT call an API.

      // So... if the user saw "No tienes permisos" on Owner Dashboard, it was likely from the DRAWER
      // or a specific button, OR I missed a real API call in `_startBackgroundServices`?

      // `_startBackgroundServices` calls `UnifiedBackgroundService.initialize(user)`.
      // If THAT fails with 403, it prints to console, but doesn't show a red screen.

      // The RED SCREEN comes from `_error != null`.
      // In `OwnerDashboard`, `_error` is only set in `catch (e)` of `_loadStatistics`.
      // But `_loadStatistics` only does `setState`. It has no `await api`.

      // ... Unless `_loadStatistics` WAS modified in a previous turn that I didn't see fully?
      // Let me re-read OwnerDashboard CAREFULLY.

      setState(() {
        _statistics = {
          'totalEmpleados': 0,
          'empleadosActivos': 0,
          'empleadosInactivos': 0,
        };
        _isLoading = false;
      });

      // It is MOCK data. It cannot fail with 403.
      // So the user must be referring to SuperAdminDashboard OR they are clicking a menu item.

      // "Sucedío con todas las vistas el tema de 'No tienes permisos para realizar esta acción'"
      // Maybe "Todas las vistas" means "Any view I go to via the drawer"?

      // In any case, I will apply the logic to SuperAdminDashboard (done) and
      // I should check `SystemController` or `RoleManagementScreen` if they visit those.

      // But for now, I will stick to what I know: SuperAdminDashboard DOES call API.
      // I will NOT modify OwnerDashboard blindly if it has no API call.

      // I will explain this to the user.
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
              title: 'Mi carpeta de Google Drive',
              icon: Icons.add_to_drive,
              color: const Color(0xFF4285F4), // Google Blue
              onTap: () async {
                final authController = Provider.of<AuthController>(
                  context,
                  listen: false,
                );
                final user = authController.currentUser;
                final urlStr = user?.googleDriveFolderUrl;

                if (urlStr != null && urlStr.isNotEmpty) {
                  final url = Uri.parse(urlStr);
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo abrir el enlace: $e'),
                          backgroundColor: DesignSystem.errorColor,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No tienes una carpeta asignada aún.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
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
