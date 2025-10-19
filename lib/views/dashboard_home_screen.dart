import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _puedeUsarBotonPrueba = false;
  bool _botonPruebaIlimitado = false;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Simular carga de datos del usuario - aquí se conectaría con el backend
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _userInfo = {
        'id': '1',
        'nombre': 'Usuario Demo',
        'email': 'usuario@demo.com',
        'rol': 'propietario',
      };
      _puedeUsarBotonPrueba = true;
      _botonPruebaIlimitado = true;
      _isLoading = false;
    });

    _animationController?.forward();
  }


  Future<void> _procesarPagoPrueba() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Probar Sistema'),
        content: Text(
          _botonPruebaIlimitado
              ? '¿Deseas procesar un pago de prueba?'
              : '¿Deseas procesar un pago de prueba? (Solo puedes usarlo una vez)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryColor,
            ),
            child: const Text('Procesar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago de prueba procesado correctamente'),
          backgroundColor: DesignSystem.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isSuperAdmin = authController.isSuperAdmin;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: DesignSystem.primaryColor,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(DesignSystem.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: DesignSystem.spacingL),
                      _buildStatsCards(),
                      const SizedBox(height: DesignSystem.spacingL),
                      _buildQuickActions(isSuperAdmin),
                      const SizedBox(height: DesignSystem.spacingL),
                      _buildTestSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingL),
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingS),
          Text(
            _userInfo?['nombre'] ?? 'Usuario',
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeL,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingS),
          Text(
            _userInfo?['email'] ?? '',
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeS,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Pagos Hoy',
            value: '12',
            icon: Icons.payment,
            color: DesignSystem.primaryColor,
          ),
        ),
        const SizedBox(width: DesignSystem.spacingM),
        Expanded(
          child: _buildStatCard(
            title: 'Empleados',
            value: '8',
            icon: Icons.people,
            color: DesignSystem.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowS,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignSystem.iconSizeL,
          ),
          const SizedBox(height: DesignSystem.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingXS),
          Text(
            title,
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeS,
              color: DesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isSuperAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: DesignSystem.fontSizeL,
            fontWeight: FontWeight.w600,
            color: DesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: DesignSystem.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Gestionar Empleados',
                icon: Icons.people_outline,
                color: DesignSystem.primaryColor,
                onTap: () => _navigateToEmployeeManagement(),
              ),
            ),
            const SizedBox(width: DesignSystem.spacingM),
            Expanded(
              child: _buildActionButton(
                title: 'Ver Notificaciones',
                icon: Icons.notifications_outlined,
                color: DesignSystem.warningColor,
                onTap: () => _navigateToNotifications(),
              ),
            ),
          ],
        ),
        if (isSuperAdmin) ...[
          const SizedBox(height: DesignSystem.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: 'Gestionar Usuarios',
                  icon: Icons.admin_panel_settings_outlined,
                  color: DesignSystem.errorColor,
                  onTap: () => _navigateToUserManagement(),
                ),
              ),
              const SizedBox(width: DesignSystem.spacingM),
              Expanded(
                child: _buildActionButton(
                  title: 'Ver Negocios',
                  icon: Icons.business_outlined,
                  color: DesignSystem.primaryLight,
                  onTap: () => _navigateToBusinessManagement(),
                ),
              ),
            ],
          ),
        ],
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
          color: DesignSystem.surfaceColor,
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          boxShadow: DesignSystem.shadowS,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: DesignSystem.iconSizeL,
            ),
            const SizedBox(height: DesignSystem.spacingS),
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignSystem.fontSizeS,
                fontWeight: FontWeight.w500,
                color: DesignSystem.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    if (!_puedeUsarBotonPrueba) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        border: Border.all(color: DesignSystem.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: DesignSystem.warningColor,
                size: DesignSystem.iconSizeM,
              ),
              const SizedBox(width: DesignSystem.spacingS),
              const Text(
                'Modo de Prueba',
                style: TextStyle(
                  fontSize: DesignSystem.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: DesignSystem.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacingS),
          const Text(
            'Prueba el sistema procesando un pago de prueba',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeS,
              color: DesignSystem.textSecondary,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _procesarPagoPrueba,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.warningColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Procesar Pago de Prueba'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEmployeeManagement() {
    // Navegar a la pantalla de gestión de empleados usando el callback
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(2); // Índice 2 = Empleados
    }
  }

  void _navigateToNotifications() {
    // Navegar a la pantalla de notificaciones (si existiera)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad en desarrollo')),
    );
  }

  void _navigateToUserManagement() {
    // Navegar a la pantalla de gestión de usuarios para Super Admin
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(3); // Índice 3 = Usuarios
    }
  }

  void _navigateToBusinessManagement() {
    // Navegar a la pantalla de gestión de negocios para Super Admin
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(4); // Índice 4 = Negocios
    }
  }
}
