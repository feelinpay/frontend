import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../services/user_management_service.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../widgets/snackbar_helper.dart';
import '../utils/error_helper.dart';
import '../views/country_picker.dart';

class OwnerEmployeesScreen extends StatefulWidget {
  final UserModel owner;

  const OwnerEmployeesScreen({
    super.key,
    required this.owner,
  });

  @override
  State<OwnerEmployeesScreen> createState() => _OwnerEmployeesScreenState();
}

class _OwnerEmployeesScreenState extends State<OwnerEmployeesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final UserManagementService _userService = UserManagementService();
  
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
    _loadEmployees();
    _searchController.addListener(() => _filterEmployees(_searchController.text));
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

  @override
  void dispose() {
    _animationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _userService.getEmployeesByOwner(widget.owner.id);
      
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

  void _updateNotificationsToggleState() {
    if (_employees.isEmpty) {
      _notificationsEnabled = false;
      return;
    }
    
    _notificationsEnabled = _employees.every((employee) => employee.activo);
  }

  Future<void> _toggleAllNotifications() async {
    SnackBarHelper.showLoading(context, _notificationsEnabled 
        ? 'Desactivando notificaciones...' 
        : 'Activando notificaciones...');

    try {
      final newState = !_notificationsEnabled;
      
      for (final employee in _employees) {
        if (employee.activo != newState) {
          final response = await _userService.toggleEmployeeForOwner(
            widget.owner.id, 
            employee.id,
            newState
          );
          
          if (!response.isSuccess) {
            SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
            return;
          }
        }
      }
      
      setState(() {
        _notificationsEnabled = newState;
        for (int i = 0; i < _employees.length; i++) {
          _employees[i] = _employees[i].copyWith(activo: newState);
        }
        _filteredEmployees = _employees;
      });
      
      // Sin SnackBar de éxito para evitar latencia
          
    } catch (e) {
      SnackBarHelper.showError(context, 'Error al cambiar notificaciones: $e');
    }
  }

  Future<void> _addEmployee() async {
    await showDialog(
      context: context,
      builder: (context) => _AddEmployeeDialog(
        ownerId: widget.owner.id,
        onEmployeeAdded: (employee) {
          setState(() {
            _employees.add(employee);
            _filteredEmployees = _employees;
          });
          _updateNotificationsToggleState();
        },
      ),
    );
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${employee.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SnackBarHelper.showLoading(context, 'Eliminando empleado...');
      
      try {
        final response = await _userService.deleteEmployeeForOwner(widget.owner.id, employee.id);
        
        if (response.isSuccess) {
          setState(() {
            _employees.removeWhere((e) => e.id == employee.id);
            _filteredEmployees = _employees;
          });
          _updateNotificationsToggleState();
          
          // Sin SnackBar de éxito para evitar latencia
        } else {
          SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
        }
      } catch (e) {
        SnackBarHelper.showError(context, 'Error al eliminar empleado: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Empleados de ${widget.owner.nombre}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignSystem.primaryColor,
                DesignSystem.primaryLight,
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: Column(
            children: [
              _buildHeader(),
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

  Widget _buildHeader() {
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
              size: 24,
            ),
          ),
          const SizedBox(width: DesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Empleados',
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeL,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textPrimary,
                  ),
                ),
                Text(
                  '${widget.owner.nombre} • ${_employees.length} empleados',
                  style: TextStyle(
                    fontSize: DesignSystem.fontSizeS,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
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
        controller: _searchController,
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
            employee.nombre.isNotEmpty ? employee.nombre[0].toUpperCase() : 'E',
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

  Future<void> _toggleEmployeeNotifications(EmployeeModel employee) async {
    SnackBarHelper.showLoading(context, employee.activo 
        ? 'Desactivando notificaciones...' 
        : 'Activando notificaciones...');

    try {
      final newState = !employee.activo;
      final response = await _userService.toggleEmployeeForOwner(
        widget.owner.id, 
        employee.id,
        newState
      );
      
      if (response.isSuccess) {
        setState(() {
          final index = _employees.indexWhere((e) => e.id == employee.id);
          if (index != -1) {
            _employees[index] = _employees[index].copyWith(activo: newState);
            _filteredEmployees = _employees;
          }
        });
        _updateNotificationsToggleState();
        
        // Sin SnackBar de éxito para evitar latencia
      } else {
        SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error al cambiar notificaciones: $e');
    }
  }

  Future<void> _editEmployee(EmployeeModel employee) async {
    await showDialog(
      context: context,
      builder: (context) => _EditEmployeeDialog(
        ownerId: widget.owner.id,
        employee: employee,
        onEmployeeUpdated: (updatedEmployee) {
          setState(() {
            final index = _employees.indexWhere((e) => e.id == employee.id);
            if (index != -1) {
              _employees[index] = updatedEmployee;
              _filteredEmployees = _employees;
            }
          });
        },
      ),
    );
  }

}

class _AddEmployeeDialog extends StatefulWidget {
  final String ownerId;
  final Function(EmployeeModel) onEmployeeAdded;

  const _AddEmployeeDialog({
    required this.ownerId,
    required this.onEmployeeAdded,
  });

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserManagementService();
  Country _selectedCountry = countries.firstWhere((c) => c.code == 'PE');

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

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    SnackBarHelper.showLoading(context, 'Agregando empleado...');

    try {
      final response = await _userService.createEmployeeForOwner(
        widget.ownerId,
        nombre: _nameController.text,
        telefono: '${_selectedCountry.dialCode}${_phoneController.text}',
      );

      if (response.isSuccess && response.data != null) {
        widget.onEmployeeAdded(response.data!);
        Navigator.pop(context);
        // Sin SnackBar de éxito para evitar latencia
      } else {
        SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error al agregar empleado: $e');
    }
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
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Nombre completo del empleado',
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
          child: const Text(
            'Cancelar',
            style: TextStyle(color: DesignSystem.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _addEmployee,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            ),
          ),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _EditEmployeeDialog extends StatefulWidget {
  final String ownerId;
  final EmployeeModel employee;
  final Function(EmployeeModel) onEmployeeUpdated;

  const _EditEmployeeDialog({
    required this.ownerId,
    required this.employee,
    required this.onEmployeeUpdated,
  });

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserManagementService();
  Country _selectedCountry = countries.firstWhere((c) => c.code == 'PE');

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.employee.nombre;
    _phoneController.text = widget.employee.telefono.replaceAll(RegExp(r'^\+\d+'), '');
    // Extraer el código de país del teléfono
    final phoneParts = widget.employee.telefono.split(' ');
    if (phoneParts.isNotEmpty) {
      final dialCode = phoneParts.first;
      _selectedCountry = countries.firstWhere(
        (c) => c.dialCode == dialCode,
        orElse: () => countries.firstWhere((c) => c.code == 'PE'),
      );
    }
  }

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

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    SnackBarHelper.showLoading(context, 'Actualizando empleado...');

    try {
      final response = await _userService.updateEmployeeForOwner(
        widget.ownerId,
        widget.employee.id,
        nombre: _nameController.text,
        telefono: '${_selectedCountry.dialCode}${_phoneController.text}',
      );

      if (response.isSuccess && response.data != null) {
        widget.onEmployeeUpdated(response.data!);
        Navigator.pop(context);
        // Sin SnackBar de éxito para evitar latencia
      } else {
        SnackBarHelper.showError(context, ErrorHelper.processApiError(response));
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error al actualizar empleado: $e');
    }
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
          child: const Text(
            'Cancelar',
            style: TextStyle(color: DesignSystem.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _updateEmployee,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            ),
          ),
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}











