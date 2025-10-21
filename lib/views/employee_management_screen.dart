import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/snackbar_helper.dart';
import '../controllers/auth_controller.dart';
import '../services/employee_service.dart';
import '../models/employee_model.dart';
import '../utils/error_helper.dart';
import '../views/country_picker.dart';
import 'package:provider/provider.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen>
    with TickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndLoadEmployees();
  }

  Future<void> _checkAuthAndLoadEmployees() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Verificar si el usuario está autenticado y verificado
    if (!authController.isAuthenticated || !authController.isVerified) {
      // Si no está autenticado o verificado, no cargar empleados
      return;
    }
    
    // Si está autenticado y verificado, cargar empleados
    _loadEmployees();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _animationController!.forward();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _employeeService.getEmployees();
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _employees = response.data!;
          _filteredEmployees = _employees;
          _isLoading = false;
        });
        _updateNotificationsToggleState();
      } else {
        setState(() {
          _isLoading = false;
        });
        
        SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      SnackBarHelper.showError(context, 'Error al cargar empleados: $e');
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees
            .where((employee) =>
                employee.nombre.toLowerCase().contains(query.toLowerCase()) ||
                employee.telefono.contains(query))
            .toList();
      }
    });
  }

  Future<void> _toggleAllNotifications() async {
    try {
      // Obtener el estado actual basado en todos los empleados
      final bool allEnabled = _employees.every((employee) => employee.activo);
      final bool newState = !allEnabled;
      
      // Mostrar indicador de carga y bloquear navegación
      SnackBarHelper.showLoading(
        context,
        newState ? 'Activando notificaciones para todos...' : 'Desactivando notificaciones para todos...'
      );
      
      // Realizar la operación en el backend
      final response = await _employeeService.toggleAllNotifications(newState);

      if (response.isSuccess) {
        // Actualizar UI solo después del éxito
        setState(() {
          _employees = _employees.map((employee) => 
            employee.copyWith(activo: newState)
          ).toList();
          _filteredEmployees = _employees;
          _notificationsEnabled = newState;
        });
        
        SnackBarHelper.showSuccess(
          context,
          newState ? 'Notificaciones activadas para todos' : 'Notificaciones desactivadas para todos'
        );
      } else {
        SnackBarHelper.showError(context, 'Error: ${response.message}');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error de conexión: ${e.toString()}');
    }
  }

  void _addEmployee() async {
    final result = await showDialog<EmployeeModel>(
      context: context,
      builder: (context) => _AddEmployeeDialog(),
    );

    if (result != null) {
      try {
        final response = await _employeeService.createEmployee(
          nombre: result.nombre,
          telefono: result.telefono,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            _employees.add(response.data!);
            _filteredEmployees = _employees;
            _updateNotificationsToggleState();
          });
          
          SnackBarHelper.showSuccess(context, 'Empleado ${result.nombre} agregado exitosamente');
        } else {
          SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
        }
      } catch (e) {
        SnackBarHelper.showError(context, 'Error: $e');
      }
    }
  }

  void _editEmployee(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => _EditEmployeeDialog(
        employee: employee,
        onEmployeeUpdated: (updatedEmployee) {
          setState(() {
            final index = _employees.indexWhere((emp) => emp.id == employee.id);
            if (index != -1) {
              _employees[index] = updatedEmployee;
            }
            _updateNotificationsToggleState();
          });
        },
      ),
    );
  }

  void _deleteEmployee(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text('¿Estás seguro de que deseas eliminar a ${employee.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await _employeeService.deleteEmployee(employee.id);
                
                if (response.isSuccess) {
                  setState(() {
                    _employees.removeWhere((e) => e.id == employee.id);
                    _filteredEmployees = _employees;
                    _updateNotificationsToggleState();
                  });
                  
                  SnackBarHelper.showSuccess(context, 'Empleado ${employee.nombre} eliminado exitosamente');
                } else {
                  SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
                }
              } catch (e) {
                SnackBarHelper.showError(context, 'Error: $e');
              }
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEmployeeNotifications(EmployeeModel employee) async {
    try {
      final bool newState = !employee.activo;
      final int employeeIndex = _employees.indexWhere((emp) => emp.id == employee.id);
      
      if (employeeIndex == -1) return;
      
      // Mostrar indicador de carga y bloquear navegación
      SnackBarHelper.showLoading(
        context,
        '${employee.nombre}: ${newState ? 'Activando notificaciones...' : 'Desactivando notificaciones...'}'
      );
      
      // Realizar la operación en el backend
      final response = await _employeeService.updateNotificationConfig(
        employeeId: employee.id,
        notificacionesActivas: newState,
      );

      if (response.isSuccess) {
        // Actualizar UI solo después del éxito
        setState(() {
          _employees[employeeIndex] = _employees[employeeIndex].copyWith(activo: newState);
          _filteredEmployees = _employees;
          _updateNotificationsToggleState();
        });
        
        SnackBarHelper.showSuccess(
          context,
          '${employee.nombre}: ${newState ? 'Notificaciones activadas' : 'Notificaciones desactivadas'}'
        );
      } else {
        SnackBarHelper.showError(context, 'Error: ${response.message}');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error de conexión: ${e.toString()}');
    }
  }


  void _updateNotificationsToggleState() {
    // Verificar si todos los empleados tienen notificaciones activadas
    if (_employees.isEmpty) {
      _notificationsEnabled = false;
    } else {
      _notificationsEnabled = _employees.every((employee) => employee.activo);
    }
  }


  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: const Text('Configuración de empleados'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando datos...')),
    );
  }

  void _openGoogleSheets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo Google Sheets...')),
    );
  }

  void _manageUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando a gestión de usuarios...')),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isSuperAdmin = authController.isSuperAdmin;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: Column(
            children: [
              _buildHeader(context, isSuperAdmin),
              _buildNotificationsToggle(),
              _buildSearchBar(),
              Expanded(child: _buildEmployeeList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        backgroundColor: DesignSystem.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context, bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spacingM,
        DesignSystem.spacingL,
        DesignSystem.spacingM,
        DesignSystem.spacingM,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignSystem.primaryColor.withOpacity(0.05),
            DesignSystem.primaryColor.withOpacity(0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignSystem.primaryColor, DesignSystem.primaryLight],
              ),
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: DesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [DesignSystem.primaryColor, DesignSystem.primaryLight],
                  ).createShader(bounds),
                  child: const Text(
                    'Gestión de Empleados',
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredEmployees.length} empleados registrados',
                  style: const TextStyle(
                    fontSize: DesignSystem.fontSizeS,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ThreeDotsMenuWidget(
            items: [
              ThreeDotsMenuItem(
                title: 'Configuración',
                icon: Icons.settings_outlined,
                onTap: () => _showSettingsDialog(),
              ),
              ThreeDotsMenuItem(
                title: 'Exportar datos',
                icon: Icons.download_outlined,
                onTap: () => _exportData(),
              ),
              ThreeDotsMenuItem(
                title: 'Google Sheets',
                icon: Icons.table_chart_outlined,
                onTap: () => _openGoogleSheets(),
              ),
              if (isSuperAdmin)
                ThreeDotsMenuItem(
                  title: 'Gestionar usuarios',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () => _manageUsers(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      child: Row(
        children: [
          Icon(
            _notificationsEnabled ? Icons.notifications_off : Icons.notifications,
            color: _notificationsEnabled ? DesignSystem.primaryColor : DesignSystem.textTertiary,
          ),
          const SizedBox(width: DesignSystem.spacingS),
          Text(
            _notificationsEnabled ? 'Desactivar notificaciones a todos' : 'Activar notificaciones a todos',
            style: TextStyle(
              color: _notificationsEnabled ? DesignSystem.primaryColor : DesignSystem.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: _notificationsEnabled,
            onChanged: (value) => _toggleAllNotifications(),
            activeThumbColor: DesignSystem.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      child: TextField(
        onChanged: _filterEmployees,
        decoration: InputDecoration(
          hintText: 'Buscar empleados...',
          prefixIcon: const Icon(Icons.search, color: DesignSystem.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: BorderSide(color: DesignSystem.textTertiary.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: BorderSide(color: DesignSystem.textTertiary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: const BorderSide(color: DesignSystem.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: DesignSystem.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignSystem.spacingM,
            vertical: DesignSystem.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DesignSystem.primaryColor,
        ),
      );
    }

    if (_filteredEmployees.isEmpty) {
      return const Center(
        child: Text(
          'No hay empleados registrados',
          style: TextStyle(
            color: DesignSystem.textSecondary,
            fontSize: DesignSystem.fontSizeM,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        DesignSystem.spacingM,
        0,
        DesignSystem.spacingM,
        DesignSystem.spacingXL + 20, // Padding inferior para el botón flotante
      ),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeItem(employee);
      },
    );
  }

  Widget _buildEmployeeItem(EmployeeModel employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingS),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DesignSystem.primaryColor.withOpacity(0.1),
          child: Text(
            employee.nombre[0].toUpperCase(),
            style: const TextStyle(
              color: DesignSystem.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DesignSystem.textPrimary,
          ),
        ),
        subtitle: Text(
          employee.telefono,
          style: const TextStyle(color: DesignSystem.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _toggleEmployeeNotifications(employee),
              icon: Icon(
                employee.activo
                    ? Icons.notifications
                    : Icons.notifications_off,
                color: employee.activo
                    ? DesignSystem.primaryColor
                    : DesignSystem.textTertiary,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editEmployee(employee);
                    break;
                  case 'delete':
                    _deleteEmployee(employee);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: DesignSystem.primaryColor),
                      SizedBox(width: DesignSystem.spacingS),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: DesignSystem.errorColor),
                      SizedBox(width: DesignSystem.spacingS),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog();

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _selectedCountry = Country(
    name: 'Perú',
    code: 'PE',
    dialCode: '+51',
    flag: '🇵🇪',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CountryPicker(
          onCountrySelected: (country) {
            setState(() {
              _selectedCountry = country;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      title: const Text('Agregar Empleado'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
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
              children: [
                // Selector de país
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingM,
                      vertical: DesignSystem.spacingM,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: DesignSystem.textTertiary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: DesignSystem.spacingS),
                        Text(
                          _selectedCountry.dialCode,
                          style: const TextStyle(
                            color: DesignSystem.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: DesignSystem.spacingS),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: DesignSystem.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingS),
                // Campo de teléfono
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      hintText: 'Número de teléfono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El teléfono es requerido';
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final employee = EmployeeModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                usuarioId: '', // Se asignará en el backend
                nombre: _nameController.text,
                telefono: '${_selectedCountry.dialCode}${_phoneController.text}', // Usar número completo con código de país
                activo: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              Navigator.pop(context, employee); // Retornar el empleado
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _EditEmployeeDialog extends StatefulWidget {
  final EmployeeModel employee;
  final Function(EmployeeModel) onEmployeeUpdated;

  const _EditEmployeeDialog({
    required this.employee,
    required this.onEmployeeUpdated,
  });

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late GlobalKey<FormState> _formKey;
  late Country _selectedCountry;
  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.nombre);
    
    // Extraer código de país del teléfono
    final phoneNumber = widget.employee.telefono;
    _selectedCountry = _getCountryFromPhone(phoneNumber);
    _phoneController = TextEditingController(text: _getPhoneWithoutCountryCode(phoneNumber));
    
    _formKey = GlobalKey<FormState>();
  }

  Country _getCountryFromPhone(String phone) {
    // Por defecto Perú, pero se puede mejorar la lógica
    return Country(
      name: 'Peru',
      code: 'PE',
      dialCode: '+51',
      flag: '🇵🇪',
    );
  }

  String _getPhoneWithoutCountryCode(String phone) {
    // Remover el código de país del número
    if (phone.startsWith('+51')) {
      return phone.substring(3);
    }
    return phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      title: const Text('Editar Empleado'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Nombre del empleado',
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
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () async {
                      final country = await showDialog<Country>(
                        context: context,
                        builder: (context) => CountryPicker(
                          onCountrySelected: (country) => Navigator.pop(context, country),
                        ),
                      );
                      if (country != null) {
                        setState(() {
                          _selectedCountry = country;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignSystem.spacingM,
                        horizontal: DesignSystem.spacingM,
                      ),
                      decoration: BoxDecoration(
                        color: DesignSystem.surfaceColor,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCountry.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: DesignSystem.spacingS),
                          Text(
                            _selectedCountry.dialCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: DesignSystem.textPrimary,
                            ),
                          ),
                          const SizedBox(width: DesignSystem.spacingS),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: DesignSystem.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingS),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      hintText: 'Número de teléfono',
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
                        return 'El teléfono es requerido';
                      }
                      if (value.length < 9) {
                        return 'El teléfono debe tener al menos 9 dígitos';
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final updatedEmployee = widget.employee.copyWith(
                  nombre: _nameController.text,
                  telefono: '${_selectedCountry.dialCode}${_phoneController.text}',
                );

                final response = await _employeeService.updateEmployee(
                  employeeId: widget.employee.id,
                  nombre: _nameController.text,
                  telefono: '${_selectedCountry.dialCode}${_phoneController.text}',
                );

                if (response.isSuccess) {
                  widget.onEmployeeUpdated(updatedEmployee);
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${updatedEmployee.nombre} actualizado'),
                        backgroundColor: DesignSystem.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.message),
                        backgroundColor: DesignSystem.errorColor,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: DesignSystem.errorColor,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
