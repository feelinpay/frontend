import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';
import 'login_screen_improved.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _puedeUsarBotonPrueba = false;
  bool _botonPruebaIlimitado = false;
  String _razonBotonPrueba = '';
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _isInitialized = true;
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userInfo = await FeelinPayService.getProfile();

      if (userInfo.containsKey('error') || userInfo['data'] == null) {
        await FeelinPayService.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      setState(() {
        _userInfo = userInfo['data'];
      });

      await _verificarBotonPrueba();
      _animationController?.forward();
    } catch (e) {
      await FeelinPayService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verificarBotonPrueba() async {
    try {
      final result = await FeelinPayService.verificarBotonPrueba(
        _userInfo?['id'] ?? '',
      );
      setState(() {
        _puedeUsarBotonPrueba = result['puedeUsar'] ?? false;
        _botonPruebaIlimitado = result['ilimitado'] ?? false;
        _razonBotonPrueba = result['razon'] ?? '';
      });
    } catch (e) {
      // Error verificando botón de prueba
    }
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
            child: const Text('Probar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await FeelinPayService.procesarPagoPrueba(
        propietarioId: _userInfo!['id'],
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (result['success'] && mounted) {
        final ahora = DateTime.now();
        final datosPago = {
          'pagador': 'Cliente de Prueba',
          'monto': 25.0,
          'fecha': '${ahora.day}/${ahora.month}/${ahora.year}',
          'hora': '${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}',
        };

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Pago Procesado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text('Pago de prueba procesado exitosamente'),
                const SizedBox(height: 8),
                Text('Pagador: ${datosPago['pagador']}'),
                Text('Monto: \$${datosPago['monto']}'),
                Text('Fecha: ${datosPago['fecha']}'),
                Text('Hora: ${datosPago['hora']}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error procesando pago'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando dashboard...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_userInfo == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error cargando información del usuario',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    final nombreUsuario = _userInfo!['nombre'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Feelin Pay',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          // Indicador de conectividad mejorado
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Conectado',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Botón de logout mejorado
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    content: const Text(
                      '¿Estás seguro de que quieres cerrar sesión?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FeelinPayService.logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 900;
          final isLargeDesktop = constraints.maxWidth > 1200;

          return _isInitialized && _fadeAnimation != null
              ? FadeTransition(
                  opacity: _fadeAnimation!,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLargeDesktop ? 1200 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner de bienvenida moderno
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withOpacity(0.3),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '¡Bienvenido!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          nombreUsuario,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Sistema Anti-Fraude Yape',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Título de sección
                            const Text(
                              'Módulos Principales',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Módulos principales con diseño moderno
                            GridView.count(
                              crossAxisCount: isLargeDesktop
                                  ? 4
                                  : (isDesktop ? 3 : (isTablet ? 2 : 1)),
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: isLargeDesktop
                                  ? 1.0
                                  : (isDesktop ? 1.1 : 1.2),
                              children: [
                                // Gestión de Permisos
                                _buildModernCard(
                                  title: 'Gestión de Permisos',
                                  description:
                                      'Verificar y gestionar permisos del sistema',
                                  icon: Icons.security_rounded,
                                  color: const Color(0xFF3B82F6),
                                  onTap: () => _navigateToPermissions(context),
                                  buttonText: 'Verificar Permisos',
                                  buttonIcon: Icons.check_circle_rounded,
                                ),

                                // Gestión de Usuarios
                                _buildModernCard(
                                  title: 'Gestión de Usuarios',
                                  description:
                                      'Administrar usuarios del sistema',
                                  icon: Icons.people_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  onTap: () =>
                                      _navigateToUserManagement(context),
                                  buttonText: 'Gestionar Usuarios',
                                  buttonIcon: Icons.people_rounded,
                                ),

                                // Sistema de Notificaciones
                                _buildModernCard(
                                  title: 'Notificaciones',
                                  description:
                                      'Gestionar alertas y notificaciones',
                                  icon: Icons.notifications_rounded,
                                  color: const Color(0xFF10B981),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/notifications',
                                  ),
                                  buttonText: 'Ver Notificaciones',
                                  buttonIcon: Icons.notifications_rounded,
                                ),

                                // Configuración del Sistema
                                _buildModernCard(
                                  title: 'Configuración',
                                  description:
                                      'Ajustes y configuración del sistema',
                                  icon: Icons.settings_rounded,
                                  color: const Color(0xFFF59E0B),
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/settings'),
                                  buttonText: 'Configurar',
                                  buttonIcon: Icons.settings_rounded,
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Botón de prueba (si está disponible)
                            if (_puedeUsarBotonPrueba) ...[
                              const Text(
                                'Sistema de Pruebas',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildTestCard(),
                              const SizedBox(height: 40),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner de bienvenida moderno
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '¡Bienvenido!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    nombreUsuario,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sistema Anti-Fraude Yape',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Título de sección
                      const Text(
                        'Módulos Principales',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Módulos principales con diseño moderno
                      GridView.count(
                        crossAxisCount: isLargeDesktop
                            ? 4
                            : (isDesktop ? 3 : (isTablet ? 2 : 1)),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isLargeDesktop
                            ? 1.0
                            : (isDesktop ? 1.1 : 1.2),
                        children: [
                          // Gestión de Permisos
                          _buildModernCard(
                            title: 'Gestión de Permisos',
                            description:
                                'Verificar y gestionar permisos del sistema',
                            icon: Icons.security_rounded,
                            color: const Color(0xFF3B82F6),
                            onTap: () =>
                                Navigator.pushNamed(context, '/permissions'),
                            buttonText: 'Verificar Permisos',
                            buttonIcon: Icons.check_circle_rounded,
                          ),

                          // Gestión de Usuarios
                          _buildModernCard(
                            title: 'Gestión de Usuarios',
                            description: 'Administrar usuarios del sistema',
                            icon: Icons.people_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => _navigateToUserManagement(context),
                            buttonText: 'Gestionar Usuarios',
                            buttonIcon: Icons.people_rounded,
                          ),

                          // Sistema de Notificaciones
                          _buildModernCard(
                            title: 'Notificaciones',
                            description: 'Gestionar alertas y notificaciones',
                            icon: Icons.notifications_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () =>
                                Navigator.pushNamed(context, '/notifications'),
                            buttonText: 'Ver Notificaciones',
                            buttonIcon: Icons.notifications_rounded,
                          ),

                          // Configuración del Sistema
                          _buildModernCard(
                            title: 'Configuración',
                            description: 'Ajustes y configuración del sistema',
                            icon: Icons.settings_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () =>
                                Navigator.pushNamed(context, '/settings'),
                            buttonText: 'Configurar',
                            buttonIcon: Icons.settings_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Botón de prueba (si está disponible)
                      if (_puedeUsarBotonPrueba) ...[
                        const Text(
                          'Sistema de Pruebas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTestCard(),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String buttonText,
    required IconData buttonIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onTap,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(buttonIcon, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Color(0xFFF59E0B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Sistema de Pruebas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _botonPruebaIlimitado
                  ? 'Puedes usar el sistema de pruebas sin límites'
                  : 'Solo puedes usar el sistema de pruebas una vez',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (_razonBotonPrueba.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _razonBotonPrueba,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _procesarPagoPrueba,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Probar Sistema',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  // Navegar a gestión de permisos
  void _navigateToPermissions(BuildContext context) {
    // Navegar a la pantalla de permisos del sistema
    Navigator.pushNamed(context, '/system-permissions');
  }

  // Navegar a gestión de usuarios
  void _navigateToUserManagement(BuildContext context) {
    // Navegar a la pantalla de gestión de usuarios
    Navigator.pushNamed(context, '/user-management');
  }

  // Método para mostrar diálogo de "Próximamente"
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.construction, color: Colors.orange),
              SizedBox(width: 8),
              Text('Próximamente'),
            ],
          ),
          content: Text(
            'La funcionalidad "$feature" estará disponible en una próxima actualización.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}
