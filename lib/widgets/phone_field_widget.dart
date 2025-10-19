import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../views/country_picker.dart';
import '../core/design/design_system.dart';

class PhoneFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;

  const PhoneFieldWidget({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
  });

  @override
  State<PhoneFieldWidget> createState() => _PhoneFieldWidgetState();
}

class _PhoneFieldWidgetState extends State<PhoneFieldWidget> {
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _getDefaultCountry();
  }

  Country _getDefaultCountry() {
    return Country(
      name: 'Perú',
      code: 'PE',
      dialCode: '+51',
      flag: '🇵🇪',
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar elegante
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header con título y botón de cierre
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Seleccionar País',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  // Botón de cierre
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Country picker sin header
            Expanded(
              child: CountryPicker(
                showHeader: false,
                onCountrySelected: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getFullPhoneNumber() {
    String phoneNumber = widget.controller.text.trim();
    
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    } else {
      return '${_selectedCountry!.dialCode}$phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Selector de país
        GestureDetector(
          onTap: widget.enabled ? _showCountryPicker : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spacingM,
              vertical: DesignSystem.spacingM,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: DesignSystem.textTertiary.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
              color: widget.enabled 
                  ? DesignSystem.surfaceColor 
                  : DesignSystem.textTertiary.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedCountry != null) ...[
                  Text(
                    _selectedCountry!.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: DesignSystem.spacingS),
                  Text(
                    _selectedCountry!.dialCode,
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeM,
                      fontWeight: FontWeight.w500,
                      color: widget.enabled 
                          ? DesignSystem.textPrimary 
                          : DesignSystem.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(width: DesignSystem.spacingS),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: widget.enabled 
                      ? DesignSystem.textSecondary 
                      : DesignSystem.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: DesignSystem.spacingM),
        // Campo de número
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: DesignSystem.fontSizeM,
              color: widget.enabled 
                  ? DesignSystem.textPrimary 
                  : DesignSystem.textTertiary,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Número de teléfono',
              hintStyle: TextStyle(
                fontSize: DesignSystem.fontSizeM,
                color: DesignSystem.textLight,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: widget.enabled 
                    ? DesignSystem.textSecondary 
                    : DesignSystem.textTertiary,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spacingM,
                vertical: DesignSystem.spacingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                borderSide: BorderSide(
                  color: DesignSystem.textTertiary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                borderSide: BorderSide(
                  color: DesignSystem.textTertiary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                borderSide: const BorderSide(
                  color: DesignSystem.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                borderSide: const BorderSide(
                  color: DesignSystem.errorColor,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                borderSide: const BorderSide(
                  color: DesignSystem.errorColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: widget.enabled 
                  ? DesignSystem.surfaceColor 
                  : DesignSystem.textTertiary.withOpacity(0.05),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}

