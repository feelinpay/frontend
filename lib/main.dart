import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'views/splash_screen.dart';
import 'views/login_screen_improved.dart';
import 'views/main_dashboard_screen.dart';
import 'views/password_recovery_screen.dart' as PasswordRecovery;
import 'views/login_otp_verification_screen.dart' as LoginOTP;
import 'views/system_permissions_screen.dart';
import 'views/user_management_screen.dart';
import 'views/android_permissions_screen.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/system_controller.dart';
import 'services/payment_notification_service.dart';
import 'services/sms_service.dart';
import 'services/background_service.dart';
import 'database/local_database.dart';
import 'core/design/design_system.dart';

// Crear instancias globales de los controladores
final AuthController _authController = AuthController();
final DashboardController _dashboardController = DashboardController();
final NotificationController _notificationController = NotificationController();
final SystemController _systemController = SystemController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar status bar
  DesignSystem.configureStatusBar();

  // Inicializar base de datos
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar base de datos local
  await LocalDatabase.database;

  // Iniciar servicios
  await PaymentNotificationService.startListening();
  await SMSService.procesarSMSPendientes();
  await BackgroundService.start();

  runApp(const MyApp());
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
            final authController = Provider.of<AuthController>(context, listen: false);
            return MainDashboardScreen(user: authController.currentUser);
          },
          '/otp-verification': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
            return LoginOTP.LoginOTPVerificationScreen(
              email: args?['email'] ?? '',
              type: args?['type'] ?? 'login',
            );
          },
          '/otp-verification-improved': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
            return LoginOTP.LoginOTPVerificationScreen(
              email: args?['email'] ?? '',
              type: args?['type'] ?? 'login',
            );
          },
          '/password-recovery': (context) =>
              const PasswordRecovery.PasswordRecoveryScreen(),
          '/password-recovery-improved': (context) =>
              const PasswordRecovery.PasswordRecoveryScreen(),
          '/system-permissions': (context) => const SystemPermissionsScreen(),
          '/user-management': (context) => const UserManagementScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
