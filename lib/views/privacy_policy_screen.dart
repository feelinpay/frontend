import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';
import '../widgets/app_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Política de Privacidad',
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
                    '1. Introducción',
                    'En Feelin Pay, respetamos su privacidad y nos comprometemos a proteger sus datos personales. Esta Política de Privacidad explica cómo recopilamos, usamos, almacenamos y protegemos su información.',
                  ),
                  _buildSection(
                    '2. Información que Recopilamos',
                    'Recopilamos: nombre completo, correo electrónico, foto de perfil de Google, ID de Google, número de teléfono (opcional), datos de empleados, información de pagos, horarios y configuraciones de negocio, datos de dispositivo, y datos de notificaciones SMS relacionadas con pagos.',
                  ),
                  _buildSection(
                    '3. Cómo Usamos Su Información',
                    'Usamos su información para autenticación y gestión de cuenta, procesamiento de pagos, gestión de empleados, generación de reportes en Google Drive, notificaciones sobre pagos recibidos, y mejora del servicio.',
                  ),
                  _buildSection(
                    '4. Compartir Información',
                    'NUNCA vendemos, alquilamos o compartimos su información personal con terceros para fines de marketing. Compartimos información solo con Google Services (Sign-In y Drive API) y proveedores de servicios necesarios para el funcionamiento de la app.',
                  ),
                  _buildSection(
                    '5. Almacenamiento y Seguridad',
                    'Sus datos se almacenan en nuestra base de datos y en Google Drive (reportes). Implementamos encriptación de datos en tránsito y en reposo, autenticación segura con tokens JWT, acceso restringido, y monitoreo de seguridad.',
                  ),
                  _buildSection(
                    '6. Sus Derechos',
                    'Usted tiene derecho a acceder, corregir, exportar y eliminar sus datos personales. Puede revocar permisos de la aplicación en cualquier momento y controlar el acceso a Google Drive.',
                  ),
                  _buildSection(
                    '7. Permisos de la Aplicación y Servicio en Segundo Plano',
                    'Para la automatización de pagos, Feelin Pay requiere permisos sensibles que usted debe autorizar explícitamente:\n\n'
                        '• Listener de Notificaciones: La aplicación ejecuta un servicio en segundo plano (incluso cuando está cerrada) que "escucha" las notificaciones entrantes de su dispositivo.\n\n'
                        '• Alcance de Datos: Nuestro algoritmo filtra y procesa ÚNICAMENTE las notificaciones provenientes de la aplicación "Yape". Ignoramos cualquier otra notificación (WhatsApp, SMS personales, etc.).\n\n'
                        '• Datos Extraídos: De las notificaciones de pago, solo extraemos: Monto de la transacción, Nombre del remitente, Fecha y hora. NO accedemos a credenciales bancarias ni saldos.\n\n'
                        '• Google Drive: Solo accedemos a crear y editar archivos en la carpeta específica creada por Feelin Pay para sus reportes.',
                  ),
                  _buildSection(
                    '8. Privacidad de Menores',
                    'Feelin Pay no está dirigido a menores de 18 años. No recopilamos intencionalmente información de menores.',
                  ),
                  _buildSection(
                    '9. Cumplimiento Legal',
                    'Esta Política cumple con la Ley de Protección de Datos Personales de Perú (Ley N° 29733) y el GDPR cuando aplique.',
                  ),
                  _buildSection(
                    '10. Seguridad de Datos',
                    'Implementamos encriptación TLS/SSL para transmisión, encriptación AES para datos en reposo, auditorías de seguridad regulares, y capacitación de personal en protección de datos.',
                  ),
                  _buildSection(
                    '11. Preguntas Frecuentes',
                    '¿Pueden ver mis SMS personales? No, solo accedemos a mensajes de servicios de pago específicos. ¿Qué pasa con mis datos si cancelo? Se conservan 30 días y luego se eliminan. ¿Cómo protegen mi información de pago? No almacenamos información bancaria.',
                  ),
                  _buildSection(
                    '12. Contacto',
                    'Para preguntas sobre privacidad: feelinpay@gmail.com',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignSystem.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignSystem.successColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const ResponsiveText(
                      'Al usar Feelin Pay, usted reconoce que ha leído y comprendido esta Política de Privacidad y acepta el procesamiento de sus datos según lo descrito.',
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
                  : DesignSystem.successColor,
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
