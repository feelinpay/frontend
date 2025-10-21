import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../services/employee_service.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/phone_field_widget.dart';

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
  final EmployeeService _employeeService = EmployeeService();
  
  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];
  bool _isLoading = true;
  String? _error;
  bool _notificationsEnabled = false;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
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
      _error = null;
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
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar empleados: $e';
        _isLoading = false;
      });
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        return employee.nombre.toLowerCase().contains(query) ||
               employee.telefono.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _updateNotificationsToggleState() {
    if (_employees.isEmpty) {
      _notificationsEnabled = false;
      return;
    }
    
    _notificationsEnabled = _employees.every((employee) => 
      employee.notificacionesActivas == true);
  }

  Future<void> _toggleAllNotifications() async {
    try {
      // TODO: Implementar toggle de todas las notificaciones
      setState(() {
        _notificationsEnabled = !_notificationsEnabled;
        // Actualizar estado de todos los empleados
        for (int i = 0; i < _employees.length; i++) {
          _employees[i] = _employees[i].copyWith(
            notificacionesActivas: _notificationsEnabled,
          );
        }
        _filterEmployees(); // Actualizar la lista filtrada
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _notificationsEnabled 
                ? 'Notificaciones activadas para todos los empleados'
                : 'Notificaciones desactivadas para todos los empleados'
            ),
            backgroundColor: DesignSystem.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DesignSystem.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _addEmployee() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        ),
        title: const Text('Agregar Empleado'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
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
              PhoneFieldWidget(
                controller: phoneController,
                labelText: 'Teléfono',
                hintText: 'Número de teléfono del empleado',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: DesignSystem.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
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
      ),
    );

    if (result == true) {
      try {
        final response = await _employeeService.createEmployee(
          nombre: nameController.text,
          telefono: phoneController.text,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            _employees.add(response.data!);
            _filterEmployees();
          });
          _updateNotificationsToggleState();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Empleado ${nameController.text} agregado exitosamente'),
                backgroundColor: DesignSystem.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
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
      try {
        final response = await _employeeService.deleteEmployee(employee.id);
        
        if (response.isSuccess) {
          setState(() {
            _employees.removeWhere((e) => e.id == employee.id);
            _filterEmployees();
          });
          _updateNotificationsToggleState();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Empleado ${employee.nombre} eliminado exitosamente'),
                backgroundColor: DesignSystem.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
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
        title: const Text(
          'Empleados',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      body: Column(
        children: [
          // Información del propietario
          Container(
            margin: const EdgeInsets.all(DesignSystem.spacingM),
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              boxShadow: DesignSystem.shadowM,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: DesignSystem.primaryColor,
                  child: Text(
                    widget.owner.nombre.isNotEmpty 
                      ? widget.owner.nombre[0].toUpperCase() 
                      : 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.owner.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.owner.email,
                        style: TextStyle(
                          color: DesignSystem.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_employees.length} empleados',
                  style: TextStyle(
                    color: DesignSystem.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Toggle de notificaciones
          Container(
            margin: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spacingM,
              vertical: DesignSystem.spacingS,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
              boxShadow: DesignSystem.shadowM,
            ),
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
                  activeColor: DesignSystem.primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignSystem.spacingM),

          // Lista de empleados
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DesignSystem.primaryColor,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: DesignSystem.errorColor,
                            ),
                            const SizedBox(height: DesignSystem.spacingM),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: DesignSystem.errorColor,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DesignSystem.spacingM),
                            ElevatedButton(
                              onPressed: _loadEmployees,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignSystem.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _filteredEmployees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: DesignSystem.textTertiary,
                                ),
                                const SizedBox(height: DesignSystem.spacingM),
                                Text(
                                  _employees.isEmpty 
                                    ? 'No hay empleados registrados'
                                    : 'No se encontraron empleados',
                                  style: TextStyle(
                                    color: DesignSystem.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation!,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(DesignSystem.spacingM),
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) {
                                final employee = _filteredEmployees[index];
                                return _buildEmployeeCard(employee);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        backgroundColor: DesignSystem.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowM,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DesignSystem.spacingM),
        leading: CircleAvatar(
          backgroundColor: employee.activo 
            ? DesignSystem.primaryColor 
            : DesignSystem.textTertiary,
          child: Text(
            employee.nombre.isNotEmpty ? employee.nombre[0].toUpperCase() : 'E',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.telefono),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  employee.activo ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: employee.activo 
                    ? DesignSystem.successColor 
                    : DesignSystem.errorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  employee.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: employee.activo 
                      ? DesignSystem.successColor 
                      : DesignSystem.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
                Icon(
                  employee.notificacionesActivas == true ? Icons.notifications : Icons.notifications_off,
                  size: 16,
                  color: employee.notificacionesActivas == true 
                    ? DesignSystem.primaryColor 
                    : DesignSystem.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  employee.notificacionesActivas == true ? 'Notificaciones ON' : 'Notificaciones OFF',
                  style: TextStyle(
                    color: employee.notificacionesActivas == true 
                      ? DesignSystem.primaryColor 
                      : DesignSystem.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ThreeDotsMenuWidget(
          items: [
            ThreeDotsMenuItem(
              icon: Icons.edit,
              title: 'Editar',
              onTap: () {
                // TODO: Implementar edición de empleado
              },
            ),
            ThreeDotsMenuItem(
              icon: Icons.delete,
              title: 'Eliminar',
              onTap: () => _deleteEmployee(employee),
            ),
          ],
        ),
      ),
    );
  }
}
