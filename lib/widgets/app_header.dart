import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../models/user_model.dart';

import 'three_dots_menu_widget.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ThreeDotsMenuItem>? menuItems;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final bool showMenu; // NEW: Control menu visibility
  final bool showUserInfo; // NEW: Control user info row visibility
  final UserModel? customUser; // NEW: Optional custom user to display

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.menuItems,
    this.showBackButton = false,
    this.onMenuPressed,
    this.showMenu = true, // Default to true
    this.showUserInfo = true, // Default to true
    this.customUser, // Optional custom user
  });

  @override
  Widget build(BuildContext context) {
    // Variable user is no longer needed since we removed the info display
    // keeping authController just in case, or removing if unused
    // actually authController was only used to get user.

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignSystem.spacingM,
        MediaQuery.of(context).padding.top +
            DesignSystem.spacingM, // Padding dinámico para status bar
        DesignSystem.spacingM,
        DesignSystem.spacingM,
      ),
      decoration: const BoxDecoration(
        color: DesignSystem.primaryColor, // Solid color instead of gradient
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DesignSystem.radiusXL),
          bottomRight: Radius.circular(DesignSystem.radiusXL),
        ),
        // Removed boxShadow for performance
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Unified Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Navigation Control (Left)
              if (showBackButton)
                _buildBackButton(context)
              else if (onMenuPressed != null)
                _buildMenuButton(context),

              // 2. Middle Content (Spacer)
              const Spacer(),

              // 3. Actions (Right)
              // Only show menu if we have items
              if (showMenu && menuItems != null && menuItems!.isNotEmpty)
                ThreeDotsMenuWidget(
                  items: [...?menuItems],
                  iconColor: Colors.white, // WHITE dots for header
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

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onMenuPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
