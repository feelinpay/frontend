import 'package:flutter/material.dart';
import '../design/design_system.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool center;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = DesignSystem.getResponsivePadding(context);

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(responsivePadding),
      child: center
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth ?? _getMaxWidth(context),
                ),
                child: child,
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? _getMaxWidth(context),
              ),
              child: child,
            ),
    );
  }

  double _getMaxWidth(BuildContext context) {
    if (DesignSystem.isMobile(context)) return 400;
    if (DesignSystem.isTablet(context)) return 600;
    return 800;
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = DesignSystem.spacingM,
    this.runSpacing = DesignSystem.spacingM,
    this.crossAxisCount,
    this.childAspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns =
        crossAxisCount ?? DesignSystem.getResponsiveColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final List<BoxShadow>? shadow;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.shadow,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = DesignSystem.getResponsivePadding(context);

    return Container(
      margin: margin ?? EdgeInsets.all(responsivePadding * 0.5),
      child: Material(
        color: color ?? DesignSystem.cardColor,
        borderRadius:
            borderRadius ?? BorderRadius.circular(DesignSystem.radiusM),
        elevation: DesignSystem.elevationS,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(DesignSystem.radiusM),
          child: Container(
            padding: padding ?? EdgeInsets.all(responsivePadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonType type;
  final ButtonSize size;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getButtonHeight();
    final fontSize = _getFontSize();

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.primary
                    ? Colors.white
                    : DesignSystem.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: DesignSystem.spacingS),
        ] else if (icon != null) ...[
          Icon(icon, size: fontSize),
          const SizedBox(width: DesignSystem.spacingS),
        ],
        Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ],
    );

    if (type == ButtonType.primary) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      );
    } else if (type == ButtonType.secondary) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      );
    } else {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: buttonHeight,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      );
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return DesignSystem.buttonHeightS;
      case ButtonSize.medium:
        return DesignSystem.buttonHeightM;
      case ButtonSize.large:
        return DesignSystem.buttonHeightL;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return DesignSystem.fontSizeS;
      case ButtonSize.medium:
        return DesignSystem.fontSizeM;
      case ButtonSize.large:
        return DesignSystem.fontSizeL;
    }
  }
}

class ResponsiveInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;
  final VoidCallback? onTap;

  const ResponsiveInput({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: DesignSystem.fontSizeS,
              fontWeight: FontWeight.w600,
              color: DesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: DesignSystem.spacingS),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spacingM,
              vertical: DesignSystem.spacingM,
            ),
          ),
        ),
      ],
    );
  }
}

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: DesignSystem.getResponsiveFontSize(
            context,
            mobile: DesignSystem.fontSizeL,
            tablet: DesignSystem.fontSizeXL,
            desktop: DesignSystem.fontSizeXL,
          ),
          fontWeight: FontWeight.w700,
          color: foregroundColor ?? DesignSystem.textPrimary,
        ),
      ),
      backgroundColor: backgroundColor ?? DesignSystem.surfaceColor,
      foregroundColor: foregroundColor ?? DesignSystem.textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextType type;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.type = TextType.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = _getResponsiveStyle(context);
    final finalStyle = style != null
        ? responsiveStyle.merge(style)
        : responsiveStyle;

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getResponsiveStyle(BuildContext context) {
    switch (type) {
      case TextType.display:
        return TextStyle(
          fontSize: DesignSystem.getResponsiveFontSize(
            context,
            mobile: DesignSystem.fontSizeXL,
            tablet: DesignSystem.fontSizeXXL,
            desktop: 36,
          ),
          fontWeight: FontWeight.bold,
          color: DesignSystem.textPrimary,
        );
      case TextType.headline:
        return TextStyle(
          fontSize: DesignSystem.getResponsiveFontSize(
            context,
            mobile: DesignSystem.fontSizeL,
            tablet: DesignSystem.fontSizeXL,
            desktop: DesignSystem.fontSizeXL,
          ),
          fontWeight: FontWeight.w600,
          color: DesignSystem.textPrimary,
        );
      case TextType.title:
        return TextStyle(
          fontSize: DesignSystem.getResponsiveFontSize(
            context,
            mobile: DesignSystem.fontSizeM,
            tablet: DesignSystem.fontSizeL,
            desktop: DesignSystem.fontSizeL,
          ),
          fontWeight: FontWeight.w600,
          color: DesignSystem.textPrimary,
        );
      case TextType.body:
        return TextStyle(
          fontSize: DesignSystem.getResponsiveFontSize(
            context,
            mobile: DesignSystem.fontSizeS,
            tablet: DesignSystem.fontSizeM,
            desktop: DesignSystem.fontSizeM,
          ),
          fontWeight: FontWeight.normal,
          color: DesignSystem.textPrimary,
        );
      case TextType.caption:
        return TextStyle(
          fontSize: DesignSystem.getResponsiveFontSize(
            context,
            mobile: DesignSystem.fontSizeXS,
            tablet: DesignSystem.fontSizeS,
            desktop: DesignSystem.fontSizeS,
          ),
          fontWeight: FontWeight.normal,
          color: DesignSystem.textSecondary,
        );
    }
  }
}

enum ButtonType { primary, secondary, text }

enum ButtonSize { small, medium, large }

enum TextType { display, headline, title, body, caption }
