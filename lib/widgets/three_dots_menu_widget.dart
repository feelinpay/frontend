import 'package:flutter/material.dart';
import '../core/design/design_system.dart';

class ThreeDotsMenuWidget extends StatelessWidget {
  final List<ThreeDotsMenuItem> items;

  const ThreeDotsMenuWidget({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThreeDotsMenuItem>(
      icon: const Icon(
        Icons.more_vert,
        color: DesignSystem.textSecondary,
        size: DesignSystem.iconSizeM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
      ),
      elevation: DesignSystem.elevationL,
      offset: const Offset(0, 50),
      itemBuilder: (BuildContext context) {
        return items.map((ThreeDotsMenuItem item) {
          return PopupMenuItem<ThreeDotsMenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: item.iconColor ?? DesignSystem.textSecondary,
                  size: DesignSystem.iconSizeS,
                ),
                const SizedBox(width: DesignSystem.spacingM),
                Text(
                  item.title,
                  style: TextStyle(
                    color: item.textColor ?? DesignSystem.textPrimary,
                    fontSize: DesignSystem.fontSizeS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.trailing != null) ...[
                  const Spacer(),
                  item.trailing!,
                ],
              ],
            ),
          );
        }).toList();
      },
      onSelected: (ThreeDotsMenuItem item) {
        item.onTap();
      },
    );
  }
}

class ThreeDotsMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const ThreeDotsMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
  });
}

