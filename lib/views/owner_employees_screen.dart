import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../services/user_management_service.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../utils/error_helper.dart';
import '../widgets/add_employee_dialog.dart'; // NEW
import '../widgets/edit_employee_dialog.dart'; // NEW
import '../views/schedule_management_screen.dart'; // NEW

class OwnerEmployeesScreen extends StatefulWidget {
  final UserModel owner;

  const OwnerEmployeesScreen({super.key, required this.owner});

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
    _searchController.addListener(
      () => _filterEmployees(_searchController.text),
    );
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

        if (mounted) {
          SnackBarHelper.showError(
            context,
            ErrorHelper.processApiError(response),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar empleados: $e');
      }
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees
            .where(
              (employee) =>
                  employee.nombre.toLowerCase().contains(query.toLowerCase()) ||
                  employee.telefono.contains(query),
            )
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
    SnackBarHelper.showLoading(
      context,
      _notificationsEnabled
          ? 'Desactivando notificaciones...'
          : 'Activando notificaciones...',
    );

    try {
      final newState = !_notificationsEnabled;

      for (final employee in _employees) {
        if (employee.activo != newState) {
          final response = await _userService.toggleEmployeeForOwner(
            widget.owner.id,
            employee.id,
            newState,
          );

          if (!response.isSuccess) {
            if (mounted) {
              SnackBarHelper.showError(
                context,
                ErrorHelper.processApiError(response),
              );
            }
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
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cambiar notificaciones: $e',
        );
      }
    }
  }

  Future<void> _addEmployee() async {
    await showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(
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
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${employee.nombre}?',
        ),
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
      if (!mounted) return;
      SnackBarHelper.showLoading(context, 'Eliminando empleado...');

      try {
        final response = await _userService.deleteEmployeeForOwner(
          widget.owner.id,
          employee.id,
        );

        if (response.isSuccess) {
          setState(() {
            _employees.removeWhere((e) => e.id == employee.id);
            _filteredEmployees = _employees;
          });
          _updateNotificationsToggleState();

          // Sin SnackBar de éxito para evitar latencia
        } else {
          if (mounted) {
            SnackBarHelper.showError(
              context,
              ErrorHelper.processApiError(response),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Error al eliminar empleado: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: Column(
          children: [
            _buildHeader(context),
            _buildOwnerInfoCard(),
            _buildNotificationsToggle(),
            _buildSearchBar(),
            Expanded(child: _buildEmployeeList()),
          ],
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

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: 'Empleados de ${widget.owner.nombre}',
      subtitle: '${_employees.length} empleados registrados',
      showBackButton: true,
      menuItems: [
        ThreeDotsMenuItem(
          icon: Icons.refresh,
          title: 'Actualizar',
          onTap: _loadEmployees,
        ),
      ],
    );
  }

  Widget _buildOwnerInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spacingM,
        vertical: DesignSystem.spacingS,
      ),
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: DesignSystem.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: DesignSystem.primaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.owner.imagen != null
                ? NetworkImage(widget.owner.imagen!)
                : null,
            child: widget.owner.imagen == null
                ? Text(
                    widget.owner.initials,
                    style: const TextStyle(
                      color: DesignSystem.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: DesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.owner.nombre,
                  style: const TextStyle(
                    fontSize: DesignSystem.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textPrimary,
                  ),
                ),
                Text(
                  widget.owner.email,
                  style: const TextStyle(
                    fontSize: DesignSystem.fontSizeS,
                    color: DesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spacingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: DesignSystem.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusS),
            ),
            child: const Text(
              'Propietario',
              style: TextStyle(
                fontSize: 10,
                color: DesignSystem.primaryColor,
                fontWeight: FontWeight.bold,
              ),
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
            _notificationsEnabled
                ? Icons.notifications_off
                : Icons.notifications,
            color: _notificationsEnabled
                ? DesignSystem.primaryColor
                : DesignSystem.textTertiary,
          ),
          const SizedBox(width: DesignSystem.spacingS),
          Text(
            _notificationsEnabled
                ? 'Desactivar notificaciones a todos'
                : 'Activar notificaciones a todos',
            style: TextStyle(
              color: _notificationsEnabled
                  ? DesignSystem.primaryColor
                  : DesignSystem.textTertiary,
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
          prefixIcon: const Icon(
            Icons.search,
            color: DesignSystem.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: BorderSide(
              color: DesignSystem.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: BorderSide(
              color: DesignSystem.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: const BorderSide(
              color: DesignSystem.primaryColor,
              width: 2,
            ),
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
        child: CircularProgressIndicator(color: DesignSystem.primaryColor),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: DesignSystem.primaryColor.withValues(alpha: 0.1),
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
                employee.activo ? Icons.notifications : Icons.notifications_off,
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
                  case 'schedule':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScheduleManagementScreen(employee: employee),
                      ),
                    );
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
                // --- NEW ITEM START ---
                const PopupMenuItem(
                  value: 'schedule',
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: DesignSystem.secondaryColor,
                      ),
                      SizedBox(width: DesignSystem.spacingS),
                      Text('Gestionar Horario'),
                    ],
                  ),
                ),
                // --- NEW ITEM END ---
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
    SnackBarHelper.showLoading(
      context,
      employee.activo
          ? 'Desactivando notificaciones...'
          : 'Activando notificaciones...',
    );

    try {
      final newState = !employee.activo;
      final response = await _userService.toggleEmployeeForOwner(
        widget.owner.id,
        employee.id,
        newState,
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
        if (mounted) {
          SnackBarHelper.showError(
            context,
            ErrorHelper.processApiError(response),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cambiar notificaciones: $e',
        );
      }
    }
  }

  Future<void> _editEmployee(EmployeeModel employee) async {
    await showDialog(
      context: context,
      builder: (context) => EditEmployeeDialog(
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
