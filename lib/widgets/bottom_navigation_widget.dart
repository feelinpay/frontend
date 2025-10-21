import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserModel? user;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    // Usar el usuario pasado como parámetro o el del AuthController
    final currentUser = user ?? authController.currentUser;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    
    // Debug: Verificar el rol en la navegación
    print('🔍 [BOTTOM NAV] Usuario: ${currentUser?.nombre}');
    print('🔍 [BOTTOM NAV] ¿Es Super Admin?: $isSuperAdmin');

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: DesignSystem.bottomNavColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isSuperAdmin ? [
          // Super Admin: Perfil, Inicio (Dashboard), Propietarios
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Perfil',
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            label: 'Inicio',
            index: 1,
            isActive: currentIndex == 1,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.people_outline,
            label: 'Propietarios',
            index: 2,
            isActive: currentIndex == 2,
          ),
        ] : [
          // Propietario: Solo Perfil y Empleados
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            label: 'Perfil',
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.people_outline,
            label: 'Empleados',
            index: 1,
            isActive: currentIndex == 1,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.spacingM,
          vertical: DesignSystem.spacingS,
        ),
        decoration: BoxDecoration(
          color: isActive ? DesignSystem.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : DesignSystem.textSecondary,
                  size: DesignSystem.iconSizeM,
                ),
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : DesignSystem.textSecondary,
                fontSize: DesignSystem.fontSizeXS,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
