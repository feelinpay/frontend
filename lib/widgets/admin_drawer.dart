import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/design/design_system.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';

class AdminDrawer extends StatelessWidget {
  final UserModel? user;
  final AuthController authController;

  const AdminDrawer({
    super.key,
    required this.user,
    required this.authController,
  });

  List<dynamic> _getSortedPermissions() {
    if (user == null) return [];

    final List<String> orderedModules = [
      'dashboard',
      'usuarios',
      'empleados',
      'membresias',
      'roles',
      'permisos',
      'sistema',
    ];

    final List<String> excludedModules = ['horarios', 'pagos'];

    final validPermissions = user!.permissions.where((p) {
      final mod = p.modulo.toLowerCase();
      return p.ruta != null &&
          p.ruta!.isNotEmpty &&
          !excludedModules.contains(mod);
    }).toList();

    validPermissions.sort((a, b) {
      final indexA = orderedModules.indexOf(a.modulo.toLowerCase());
      final indexB = orderedModules.indexOf(b.modulo.toLowerCase());
      final posA = indexA == -1 ? 99 : indexA;
      final posB = indexB == -1 ? 99 : indexB;
      return posA.compareTo(posB);
    });

    return validPermissions;
  }

  @override
  Widget build(BuildContext context) {
    final sortedPermissions = _getSortedPermissions();

    return Drawer(
      child: Column(
        children: [
          // HEADER (Fixed)
          UserAccountsDrawerHeader(
            currentAccountPictureSize: const Size.square(
              54,
            ), // Reduced from default 72
            decoration: const BoxDecoration(
              color:
                  DesignSystem.primaryColor, // Solid color instead of gradient
            ),
            accountName: Text(
              user?.nombre ?? 'Administrador',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user?.email ?? ''),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleName(user?.rol),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              foregroundImage: user?.imagen != null && user!.imagen!.isNotEmpty
                  ? NetworkImage(user!.imagen!)
                  : null,
              child: (user?.nombre != null && user!.nombre.isNotEmpty)
                  ? Text(
                      user!.nombre.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: DesignSystem.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : const Icon(Icons.person, color: DesignSystem.primaryColor),
            ),
          ),

          // SCROLLABLE MENU ITEMS (To fix overflow)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Dynamic Permissions (Ordered)
                ...sortedPermissions.map(
                  (p) => _buildDrawerItem(
                    context: context,
                    icon: _getIconForPermission(p.modulo),
                    title: p.nombre,
                    onTap: () {
                      Navigator.pop(context); // Cerrar drawer
                      if (p.ruta != null) {
                        // Usar pushReplacement para que actúe como navegación raíz (sin botón back)
                        Navigator.pushReplacementNamed(context, p.ruta!);
                      }
                    },
                  ),
                ),

                // 2. Google Drive (Fixed Position)
                if (user != null && user!.googleDriveFolderUrl != null) ...[
                  /* const Divider(), */
                  // Cleaner without separator? User wants clean list
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.add_to_drive,
                    title: 'Mi Carpeta de Google Drive',
                    onTap: () async {
                      Navigator.pop(context);
                      final url = Uri.parse(user?.googleDriveFolderUrl ?? '');
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se pudo abrir el enlace: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),

          // BOTTOM SECTION (Fixed)
          // Legal Info & Logout
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'INFORMACIÓN LEGAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textSecondary.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.description_outlined,
                  title: 'Términos y Condiciones',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/terms-of-service');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidad',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/privacy-policy');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  color: DesignSystem.errorColor,
                  onTap: () async {
                    Navigator.pop(context);
                    await authController.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
        return 'Super Administrador';
      case 'propietario':
        return 'Dueño de Negocio';
      case 'empleado':
        return 'Empleado';
      default:
        return 'Usuario';
    }
  }

  // Helper to map module keys to Icons
  IconData _getIconForPermission(String modulo) {
    switch (modulo) {
      case 'dashboard':
        return Icons.dashboard;
      case 'usuarios':
        return Icons.admin_panel_settings; // or Icons.people
      case 'roles':
        return Icons.shield_outlined;
      case 'empleados':
        return Icons.people_outline;
      case 'horarios':
        return Icons.schedule;
      case 'sistema':
        return Icons.settings; // Covers permissions and config
      case 'membresias':
        return Icons.card_membership;
      case 'reportes':
        return Icons.bar_chart;
      case 'pagos':
        return Icons.payments;
      case 'drive':
        return Icons.add_to_drive;
      default:
        return Icons.circle_outlined; // Default fallback
    }
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? DesignSystem.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? DesignSystem.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
