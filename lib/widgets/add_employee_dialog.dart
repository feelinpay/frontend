import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../core/design/design_system.dart';
import '../services/user_management_service.dart';
import '../models/employee_model.dart';
import '../views/country_picker.dart';
import '../widgets/snackbar_helper.dart';
import '../utils/error_helper.dart';

class AddEmployeeDialog extends StatefulWidget {
  final String ownerId; // Optional: If adding for a specific owner
  final Function(EmployeeModel) onEmployeeAdded;

  const AddEmployeeDialog({
    super.key,
    required this.ownerId,
    required this.onEmployeeAdded,
  });

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserManagementService();

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '### ### ###',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  Country _selectedCountry = Country(
    name: 'Perú',
    code: 'PE',
    dialCode: '+51',
    flag: '🇵🇪',
  );

  bool _isLoading = false;
  String? _errorMessage; // NEW: Local error state

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (context) => CountryPicker(
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.ownerId.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // FIX: Use controller text directly
      final cleanPhone = _phoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      final response = await _userService.createEmployeeForOwner(
        widget.ownerId,
        nombre: _nameController.text,
        telefono: '${_selectedCountry.dialCode}$cleanPhone',
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        widget.onEmployeeAdded(response.data!);
        Navigator.pop(context);
        SnackBarHelper.showSuccess(context, 'Empleado agregado exitosamente');
      } else {
        setState(() {
          _errorMessage = ErrorHelper.processApiError(response);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al agregar empleado: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      title: const Text('Agregar Empleado'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
                  padding: const EdgeInsets.all(DesignSystem.spacingS),
                  decoration: BoxDecoration(
                    color: DesignSystem.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                    border: Border.all(color: DesignSystem.errorColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: DesignSystem.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: DesignSystem.errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Nombre del empleado',
                  helperText: ' ', // Reserve space for error
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: DesignSystem.surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: DesignSystem.spacingM,
                    horizontal: DesignSystem.spacingM,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DesignSystem.spacingM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Picker - Using defined width with FittedBox for safety
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      width: 80, // Safer width for small screens
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: DesignSystem.spacingS,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: DesignSystem.textTertiary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignSystem.radiusM,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedCountry.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCountry.dialCode,
                              style: const TextStyle(
                                color: DesignSystem.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignSystem.spacingS),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneFormatter],
                      maxLines: 1, // Prevent height expansion
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '999 999 999',
                        helperText: ' ', // Reserve space for error
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            DesignSystem.radiusM,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: DesignSystem.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: DesignSystem.spacingM,
                          horizontal: DesignSystem.spacingM,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        // FIX: Check controller text directly
                        final unmasked = _phoneController.text.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (unmasked.length < 9) {
                          return 'Mínimo 9 dígitos';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: DesignSystem.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Agregar'),
        ),
      ],
    );
  }
}
