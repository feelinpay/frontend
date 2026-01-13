import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';
import '../widgets/app_header.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Términos y Condiciones',
            showUserInfo: false,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Última actualización',
                    '11 de enero de 2026',
                    isDate: true,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    '1. Aceptación de los Términos',
                    'Al acceder y utilizar Feelin Pay, usted acepta estar sujeto a estos Términos y Condiciones de Servicio. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar la Aplicación.',
                  ),
                  _buildSection(
                    '2. Descripción del Servicio',
                    'Feelin Pay es una aplicación móvil diseñada para ayudar a propietarios de negocios a gestionar y rastrear pagos recibidos, administrar empleados y sus horarios, procesar notificaciones de pago de servicios como Yape, y generar reportes de pagos en Google Drive.',
                  ),
                  _buildSection(
                    '3. Registro y Cuenta de Usuario',
                    'Debe proporcionar información precisa y completa durante el registro. Debe mantener la seguridad de su cuenta y contraseña. La Aplicación utiliza Google Sign-In para autenticación.',
                  ),
                  _buildSection(
                    '4. Período de Prueba y Membresías',
                    'Los nuevos usuarios reciben un período de prueba de 3 días con acceso completo a todas las funciones. Después del período de prueba, se requiere una membresía activa que se factura mensualmente.',
                  ),
                  _buildSection(
                    '5. Uso Aceptable',
                    'Usted se compromete a utilizar la Aplicación solo para fines legales y comerciales legítimos. Está prohibido usar la Aplicación para actividades fraudulentas, intentar hackear o modificar la aplicación, o compartir su cuenta con terceros no autorizados.',
                  ),
                  _buildSection(
                    '6. Permisos y Servicio en Segundo Plano',
                    'La funcionalidad principal de Feelin Pay ("Core") depende de la capacidad de leer notificaciones en tiempo real.\n\n'
                        '6.1. Servicio "Listener": Usted autoriza a la Aplicación a ejecutarse en segundo plano y leer las notificaciones de su barra de estado de manera continua mientras el servicio esté activo.\n\n'
                        '6.2. Datos de Terceros: Usted reconoce que Feelin Pay lee datos de la aplicación "Yape" instalada en su dispositivo. Feelin Pay NO está afiliado, asociado, autorizado, respaldado ni conectado de ninguna manera oficial con Yape (Banco de Crédito del Perú), ni ninguna de sus subsidiarias o afiliadas.\n\n'
                        '6.3. Responsabilidad: El usuario es responsable de mantener la seguridad de su dispositivo. Feelin Pay extrae los datos "tal cual" aparecen en la notificación y no se hace responsable por errores en la lectura derivados de cambios en la aplicación de terceros.',
                  ),
                  _buildSection(
                    '7. Privacidad y Datos',
                    'Recopilamos solo los datos necesarios para proporcionar el servicio. Los reportes de pago se almacenan en carpetas de Google Drive. Usted mantiene la propiedad de sus datos y puede exportar o eliminar sus datos en cualquier momento.',
                  ),
                  _buildSection(
                    '8. Propiedad Intelectual',
                    'Feelin Pay y todos sus contenidos son propiedad de sus creadores. El logotipo, diseño y código fuente están protegidos por derechos de autor. Usted retiene todos los derechos sobre los datos que ingresa en la Aplicación.',
                  ),
                  _buildSection(
                    '9. Limitación de Responsabilidad',
                    'La Aplicación se proporciona "tal cual" sin garantías de ningún tipo. No garantizamos que la Aplicación esté libre de errores o interrupciones. Nuestra responsabilidad máxima se limita al monto pagado por su membresía.',
                  ),
                  _buildSection(
                    '10. Terminación del Servicio',
                    'Puede cancelar su cuenta en cualquier momento. Los datos se conservarán durante 30 días después de la cancelación. Podemos suspender o terminar su cuenta si viola estos Términos, usa la Aplicación para actividades fraudulentas, o no paga su membresía activa.',
                  ),
                  _buildSection(
                    '11. Modificaciones al Servicio',
                    'Nos reservamos el derecho de modificar o descontinuar la Aplicación. Notificaremos cambios significativos con 30 días de anticipación. Podemos actualizar estos Términos periódicamente.',
                  ),
                  _buildSection(
                    '12. Ley Aplicable',
                    'Estos Términos se rigen por las leyes de Perú. Cualquier disputa se resolverá en los tribunales de Lima, Perú.',
                  ),
                  _buildSection(
                    '13. Contacto',
                    'Para preguntas sobre estos Términos, contáctenos en feelinpay@gmail.com',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignSystem.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const ResponsiveText(
                      'Al usar Feelin Pay, usted reconoce que ha leído, entendido y acepta estar sujeto a estos Términos y Condiciones de Servicio.',
                      type: TextType.body,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            type: isDate ? TextType.caption : TextType.title,
            style: TextStyle(
              fontWeight: isDate ? FontWeight.normal : FontWeight.bold,
              color: isDate
                  ? DesignSystem.textSecondary
                  : DesignSystem.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            content,
            type: TextType.body,
            style: const TextStyle(
              height: 1.6,
              color: DesignSystem.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
