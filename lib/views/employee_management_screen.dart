import 'package:flutter/material.dart';

import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/app_header.dart'; // NEW: AppHeader
import '../widgets/snackbar_helper.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/admin_drawer.dart';
import '../controllers/auth_controller.dart';
import '../services/employee_service.dart';
import '../models/employee_model.dart';
import '../utils/error_helper.dart';
import 'package:provider/provider.dart';
import '../widgets/add_employee_dialog.dart'; // NEW
import '../widgets/edit_employee_dialog.dart'; // NEW
import '../views/schedule_management_screen.dart'; // NEW

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen>
    with TickerProviderStateMixin, LoadingStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  AnimationController? _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        // Don't show error for empty employee list - just show empty state
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

  Future<void> _toggleAllNotifications() async {
    await executeSilently(
      () async {
        // Obtener el estado actual basado en todos los empleados
        final bool allEnabled = _employees.every((employee) => employee.activo);
        final bool newState = !allEnabled;

        // Realizar la operación en el backend
        final response = await _employeeService.toggleAllNotifications(
          newState,
        );

        if (response.isSuccess) {
          // Actualizar UI solo después del éxito
          setState(() {
            _employees = _employees
                .map((employee) => employee.copyWith(activo: newState))
                .toList();
            _filteredEmployees = _employees;
            _notificationsEnabled = newState;
          });
        } else {
          throw Exception(response.message);
        }
      },
      loadingMessage: _notificationsEnabled
          ? 'Desactivando notificaciones para todos...'
          : 'Activando notificaciones para todos...',
      errorMessage: 'Error al actualizar notificaciones',
    );
  }

  void _addEmployee() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    if (currentUser == null) return;

    await showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(
        ownerId: currentUser.id,
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

  void _editEmployee(EmployeeModel employee) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    if (currentUser == null) return;

    await showDialog(
      context: context,
      builder: (context) => EditEmployeeDialog(
        ownerId: currentUser.id,
        employee: employee,
        onEmployeeUpdated: (updatedEmployee) {
          setState(() {
            final index = _employees.indexWhere((emp) => emp.id == employee.id);
            if (index != -1) {
              _employees[index] = updatedEmployee;
              _filteredEmployees = _employees;
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
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${employee.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await _employeeService.deleteEmployee(
                  employee.id,
                );

                if (response.isSuccess) {
                  setState(() {
                    _employees.removeWhere((e) => e.id == employee.id);
                    _filteredEmployees = _employees;
                    _updateNotificationsToggleState();
                  });

                  // Sin SnackBar de éxito para evitar latencia
                } else {
                  if (context.mounted) {
                    SnackBarHelper.showError(
                      context,
                      ErrorHelper.processApiError(response),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarHelper.showError(context, 'Error: $e');
                }
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
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
    await executeSilently(
      () async {
        final bool newState = !employee.activo;
        final int employeeIndex = _employees.indexWhere(
          (emp) => emp.id == employee.id,
        );

        if (employeeIndex == -1) {
          return;
        }

        // Realizar la operación en el backend
        final response = await _employeeService.updateNotificationConfig(
          employeeId: employee.id,
          notificacionesActivas: newState,
        );

        if (response.isSuccess) {
          // Actualizar UI solo después del éxito
          setState(() {
            _employees[employeeIndex] = _employees[employeeIndex].copyWith(
              activo: newState,
            );
            _filteredEmployees = _employees;
            _updateNotificationsToggleState();
          });
        } else {
          throw Exception(response.message);
        }
      },
      loadingMessage:
          '${employee.nombre}: ${employee.activo ? 'Desactivando notificaciones...' : 'Activando notificaciones...'}',
      errorMessage: 'Error al actualizar notificaciones de ${employee.nombre}',
    );
  }

  void _updateNotificationsToggleState() {
    // Verificar si todos los empleados tienen notificaciones activadas
    if (_employees.isEmpty) {
      _notificationsEnabled = false;
    } else {
      _notificationsEnabled = _employees.every((employee) => employee.activo);
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: loadingMessage,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: DesignSystem.backgroundColor,
        drawer: AdminDrawer(
          user: Provider.of<AuthController>(context).currentUser,
          authController: Provider.of<AuthController>(context, listen: false),
        ),
        body: Column(
          children: [
            _buildHeader(context),
            _buildNotificationsToggle(),
            _buildSearchBar(),
            Expanded(child: _buildEmployeeList()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: isLoading ? null : _addEmployee,
          backgroundColor: isLoading
              ? DesignSystem.textTertiary
              : DesignSystem.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: 'Feelin Pay - Empleados',
      subtitle: 'Administración de personal',
      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      menuItems: [
        ThreeDotsMenuItem(
          icon: Icons.refresh,
          title: 'Actualizar',
          onTap: _loadEmployees,
        ),
      ],
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
}
