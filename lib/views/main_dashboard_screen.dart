import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import 'employee_management_screen.dart';
import 'profile_screen.dart';
import 'enhanced_user_management_screen.dart';
import 'business_management_screen.dart';
import 'super_admin_dashboard.dart';

class MainDashboardScreen extends StatefulWidget {
  final UserModel? user;
  
  const MainDashboardScreen({super.key, this.user});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Establecer índice inicial según el rol
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = widget.user ?? authController.currentUser;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    
    if (isSuperAdmin) {
      _currentIndex = 1; // Dashboard para Super Admin
    } else {
      _currentIndex = 1; // Empleados para Propietario (índice 1 en su lista)
    }
    
    _pageController = PageController(initialPage: _currentIndex);
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
    _pageController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    // Usar el usuario pasado como parámetro o el del AuthController
    final currentUser = widget.user ?? authController.currentUser;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    
    // Debug: Verificar el rol del usuario
    print('🔍 [MAIN DASHBOARD] Usuario actual: ${currentUser?.nombre}');
    print('🔍 [MAIN DASHBOARD] Rol del usuario: ${currentUser?.rol}');
    print('🔍 [MAIN DASHBOARD] ¿Es Super Admin?: $isSuperAdmin');

    return WillPopScope(
      onWillPop: () async {
        // Evitar que se pueda retroceder con la flecha del sistema
        return false;
      },
      child: Scaffold(
        backgroundColor: DesignSystem.backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _getPages(isSuperAdmin),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
          user: currentUser,
        ),
      ),
    );
  }

  List<Widget> _getPages(bool isSuperAdmin) {
    if (isSuperAdmin) {
      // Para Super Administradores: Dashboard administrativo + gestión completa
      return [
        const ProfileScreen(),
        const SuperAdminDashboard(),
        const EmployeeManagementScreen(),
        const UserManagementScreen(),
        const BusinessManagementScreen(),
      ];
    } else {
      // Para Propietarios: Solo Perfil y Empleados
      return [
        const ProfileScreen(),
        const EmployeeManagementScreen(),
      ];
    }
  }
}
