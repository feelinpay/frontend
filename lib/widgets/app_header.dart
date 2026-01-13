import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';

import 'three_dots_menu_widget.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ThreeDotsMenuItem>? menuItems;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final bool showMenu; // NEW: Control menu visibility
  final bool showUserInfo; // NEW: Control user info row visibility

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.menuItems,
    this.showBackButton = false,
    this.onMenuPressed,
    this.showMenu = true, // Default to true
    this.showUserInfo = true, // Default to true
  });

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    final user = authController.currentUser;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignSystem.spacingM,
        MediaQuery.of(context).padding.top +
            DesignSystem.spacingM, // Padding dinámico para status bar
        DesignSystem.spacingM,
        DesignSystem.spacingM,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6), // Primary Purple
            const Color(0xFFA855F7), // Light Purple
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(DesignSystem.radiusXL),
          bottomRight: Radius.circular(DesignSystem.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back Button, User Info, and Logout/Menu
          if (showUserInfo)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBackButton)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                else if (onMenuPressed != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: onMenuPressed,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: user?.imagen != null
                        ? DecorationImage(
                            image: NetworkImage(user!.imagen!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user?.imagen == null
                      ? Center(
                          child: Text(
                            user != null ? user.initials : 'U',
                            style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // User Name and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nombre ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu
                if (showMenu && menuItems != null && menuItems!.isNotEmpty)
                  ThreeDotsMenuWidget(items: [...?menuItems]),
              ],
            )
          else if (showBackButton)
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          // Row 2: Page Title and System Status Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
}
