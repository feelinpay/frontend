import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/splash_screen.dart';
import 'views/login_screen.dart';
import 'views/system_permissions_screen.dart';
import 'views/android_permissions_screen.dart'; // Restored
import 'views/user_management_screen.dart';
import 'views/role_management_screen.dart'; // NEW
import 'views/super_admin_dashboard.dart';
import 'views/owner_dashboard.dart';
import 'views/employee_management_screen.dart';
import 'views/membership_management_screen.dart'; // NEW
import 'views/membership_reports_screen.dart'; // NEW
import 'views/terms_of_service_screen.dart';
import 'views/privacy_policy_screen.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/system_controller.dart';
import 'services/api_service.dart';
import 'core/design/design_system.dart';

// Crear instancias globales de los controladores
final AuthController _authController = AuthController();
final DashboardController _dashboardController = DashboardController();
final NotificationController _notificationController = NotificationController();
final SystemController _systemController = SystemController();

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        debugPrint("🚀 Starting Feelin Pay Initialization...");

        await Firebase.initializeApp();

        // Configurar UI básico
        DesignSystem.configureStatusBar();

        // BLINDAJE: Reemplazar Pantalla Roja de la Muerte con UI Amigable
        ErrorWidget.builder = (FlutterErrorDetails details) {
          bool isDebug = false;
          assert(() {
            isDebug = true;
            return true;
          }());

          // En desarrollo queremos ver el error real
          if (isDebug) return ErrorWidget(details.exception);

          // En producción mostramos pantalla de recuperación
          return Material(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.orange,
                    size: 60,
                  ), // Removed external asset dependency for safety
                  const SizedBox(height: 20),
                  const Text(
                    'Algo salió mal inesperadamente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No te preocupes, la app sigue viva.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      runApp(const MyApp()); // Hard Reset de la UI
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar Aplicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9), // Primary Color
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        };

        // Lanzar la app después de inicializaciones críticas
        runApp(const MyApp());

        // Inicializar servicios secundarios en segundo plano
        _initServices();

        debugPrint("✅ Startup Sequence Initiated.");
      } catch (e, stack) {
        debugPrint("❌ CRITICAL ERROR DURING STARTUP: $e");
        debugPrint(stack.toString());
        // Intentar lanzar la app incluso si algo falla
        runApp(const MyApp());
      }
    },
    (error, stack) {
      debugPrint("❌ UNCAUGHT ERROR: $error");
      debugPrint(stack.toString());
    },
  );
}

/// Inicialización asíncrona de servicios
Future<void> _initServices() async {
  try {
    debugPrint("📡 Initializing ApiService...");
    await ApiService().initialize();

    debugPrint("🔐 Initializing AuthController...");
    await _authController.initialize();

    debugPrint("🏁 Services Ready.");
  } catch (e) {
    debugPrint("⚠️ Error initializing services: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authController),
        ChangeNotifierProvider.value(value: _dashboardController),
        ChangeNotifierProvider.value(value: _notificationController),
        ChangeNotifierProvider.value(value: _systemController),
      ],
      child: MaterialApp(
        title: 'Feelin Pay',
        theme: DesignSystem.getTheme(),
        home: const SplashScreen(),
        routes: {
          '/permissions': (context) => const AndroidPermissionsScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) {
            final authController = Provider.of<AuthController>(
              context,
              listen: false,
            );
            final user = authController.currentUser;

            // Navegación directa basada en roles
            if (user == null) {
              return const LoginScreen();
            }

            if (user.rol == 'super_admin') {
              return const SuperAdminDashboard();
            }

            // Por defecto (propietario) va al dashboard de propietario
            return const OwnerDashboard();
          },
          '/system-permissions': (context) => const SystemPermissionsScreen(),
          '/user-management': (context) => const UserManagementScreen(),

          '/employee-management': (context) => const EmployeeManagementScreen(),
          '/permissions-management': (context) => const RoleManagementScreen(),
          '/membership-management': (context) =>
              const MembershipManagementScreen(),
          '/membership-reports': (context) => const MembershipReportsScreen(),
          '/terms-of-service': (context) => const TermsOfServiceScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
