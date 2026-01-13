import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleGoogleSignIn() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    final success = await authController.loginWithGoogle();

    if (success) {
      if (mounted) {
        // Navegar primero a permisos para asegurar configuración
        Navigator.pushReplacementNamed(context, '/permissions');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ?? 'Error al iniciar sesión',
            ),
            backgroundColor: DesignSystem.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // Color de fondo más elegante
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: ResponsiveContainer(
        maxWidth: 450, // Limitar ancho en Tablet/Desktop
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card Principal
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64748B).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo Image instead of Icon (Consistente con Splash)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 60,
                        height: 60,
                        child: Image(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título
                    const ResponsiveText(
                      'Feelin Pay',
                      textAlign: TextAlign.center,
                      type: TextType.display,
                      style: TextStyle(
                        color: DesignSystem.primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const ResponsiveText(
                      'Protege tus cobros de Yape y gestiona tu negocio de forma segura y automática',
                      textAlign: TextAlign.center,
                      type: TextType.body,
                      style: TextStyle(
                        color: Color(0xFF64748B), // Slate 500
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón Google (Usando ResponsiveButton)
                    ResponsiveButton(
                      text: 'Continuar con Google',
                      onPressed: _handleGoogleSignIn,
                      isLoading: authController.isLoading,
                      icon: Icons.login_rounded, // fallback icon
                      type: ButtonType.secondary,
                    ),

                    const SizedBox(height: 24),

                    // Footer del card
                    const ResponsiveText(
                      'Al continuar, aceptas nuestros',
                      type: TextType.caption,
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/terms-of-service');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Términos',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const Text(
                          ' y ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/privacy-policy');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Política de Privacidad',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Versión app
              const ResponsiveText(
                'Versión 1.0.0',
                type: TextType.caption,
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
