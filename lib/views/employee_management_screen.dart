import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../services/employee_service.dart';
import '../models/employee_model.dart';
import '../controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import '../widgets/add_employee_dialog.dart';
import '../widgets/edit_employee_dialog.dart';
import 'schedule_management_screen.dart';
import '../core/design/design_system.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/snackbar_helper.dart';

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
  bool _notificationsEnabled = true;
  bool _isInitialLoading = false; // Separate state for initial body load
  AnimationController? _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndLoadEmployees();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _checkAuthAndLoadEmployees() {
    // Verificar si el usuario está autenticado
    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.currentUser != null) {
      _loadEmployees();
    } else {
      // Reintentar en un momento si aún no está inicializado
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAuthAndLoadEmployees();
      });
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isInitialLoading = true);
    try {
      final response = await _employeeService.getEmployees();

      if (response.isSuccess && response.data != null) {
        setState(() {
          _employees = response.data!;
          _filteredEmployees = _employees;
          _isInitialLoading = false;
        });
        _updateNotificationsToggleState();
      } else {
        setState(() => _isInitialLoading = false);
        if (mounted) SnackBarHelper.showError(context, response.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
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
              (e) =>
                  e.nombre.toLowerCase().contains(query.toLowerCase()) ||
                  e.telefono.contains(query),
            )
            .toList();
      }
    });
  }

  void _updateNotificationsToggleState() {
    if (_employees.isEmpty) {
      setState(() => _notificationsEnabled = false);
      return;
    }

    // Si al menos uno tiene notificaciones activas, el toggle global está activo
    final anyActive = _employees.any((e) => e.notificacionesActivas ?? false);
    setState(() => _notificationsEnabled = anyActive);
  }

  Future<void> _toggleAllNotifications() async {
    await executeSilently(() async {
      final newState = !_notificationsEnabled;
      final response = await _employeeService.toggleAllNotifications(newState);

      if (response.isSuccess) {
        setState(() {
          _notificationsEnabled = newState;
          // Actualizar localmente para feedback inmediato
          for (var i = 0; i < _employees.length; i++) {
            _employees[i] = _employees[i].copyWith(
              notificacionesActivas: newState,
            );
          }
          _filteredEmployees = List.from(_employees);
        });
        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            newState
                ? 'Notificaciones activadas para todos'
                : 'Notificaciones desactivadas para todos',
          );
        }
      }
    }, loadingMessage: 'Actualizando notificaciones...');
  }

  Future<void> _toggleEmployeeNotifications(EmployeeModel employee) async {
    final newState = !(employee.notificacionesActivas ?? false);

    setState(() {
      final index = _employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _employees[index] = employee.copyWith(notificacionesActivas: newState);
        _filteredEmployees = List.from(_employees);
      }
    });

    try {
      final response = await _employeeService.updateNotificationConfig(
        employeeId: employee.id,
        notificacionesActivas: newState,
      );

      if (!response.isSuccess) {
        // Revertir en caso de error
        setState(() {
          final index = _employees.indexWhere((e) => e.id == employee.id);
          if (index != -1) {
            _employees[index] = employee.copyWith(
              notificacionesActivas: !newState,
            );
            _filteredEmployees = List.from(_employees);
          }
        });
        if (mounted) SnackBarHelper.showError(context, response.message);
      } else {
        _updateNotificationsToggleState();
      }
    } catch (e) {
      // Revertir
      setState(() {
        final index = _employees.indexWhere((e) => e.id == employee.id);
        if (index != -1) {
          _employees[index] = employee.copyWith(
            notificacionesActivas: !newState,
          );
          _filteredEmployees = List.from(_employees);
        }
      });
    }
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${employee.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
      await executeWithLoading(() async {
        final response = await _employeeService.deleteEmployee(employee.id);
        if (response.isSuccess) {
          setState(() {
            _employees.removeWhere((e) => e.id == employee.id);
            _filteredEmployees = List.from(_employees);
          });
          if (mounted) {
            SnackBarHelper.showSuccess(context, 'Empleado eliminado');
          }
        }
      }, loadingMessage: 'Eliminando...');
    }
  }

  void _showAddEmployeeDialog() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(
        ownerId: user.id,
        onEmployeeAdded: (newEmployee) {
          setState(() {
            _employees.add(newEmployee);
            _filteredEmployees = List.from(_employees);
          });
          _updateNotificationsToggleState();
        },
      ),
    );
  }

  void _showEditEmployeeDialog(EmployeeModel employee) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => EditEmployeeDialog(
        ownerId: user.id,
        employee: employee,
        onEmployeeUpdated: (updatedEmployee) {
          setState(() {
            final index = _employees.indexWhere(
              (e) => e.id == updatedEmployee.id,
            );
            if (index != -1) {
              _employees[index] = updatedEmployee;
              _filteredEmployees = List.from(_employees);
            }
          });
          _updateNotificationsToggleState();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: loadingMessage,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pushReplacementNamed('/dashboard');
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: DesignSystem.backgroundColor,
          drawer: AdminDrawer(
            user: Provider.of<AuthController>(context).currentUser,
            authController: Provider.of<AuthController>(context, listen: false),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddEmployeeDialog,
            backgroundColor: DesignSystem.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              AppHeader(
                title: 'Mis Empleados',
                subtitle: 'Gestiona tu equipo de trabajo',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                showMenu: true,
                menuItems: [
                  ThreeDotsMenuItem(
                    icon: Icons.refresh,
                    title: 'Actualizar Lista',
                    onTap: _loadEmployees,
                  ),
                ],
              ),
              _buildSearchBar(),
              _buildGlobalToggle(),
              Expanded(child: _buildEmployeeList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      child: TextField(
        onChanged: _filterEmployees,
        decoration: InputDecoration(
          hintText: 'Buscar empleado...',
          prefixIcon: const Icon(
            Icons.search,
            color: DesignSystem.textTertiary,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
            borderSide: const BorderSide(
              color: DesignSystem.primaryColor,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: DesignSystem.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      child: Container(
        padding: const EdgeInsets.all(DesignSystem.spacingM),
        decoration: BoxDecoration(
          color: DesignSystem.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          border: Border.all(
            color: DesignSystem.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: DesignSystem.primaryColor,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notificaciones Globales',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Activa/Desactiva para todos',
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _notificationsEnabled,
              onChanged: (val) => _toggleAllNotifications(),
              activeThumbColor: DesignSystem.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignSystem.primaryColor),
      );
    }

    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: DesignSystem.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron empleados',
              style: TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee, index);
      },
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee, int index) {
    // OPTIMIZATION: Removed Animations for performance on low-end devices
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        // OPTIMIZATION: Shadows removed for performance
        boxShadow: [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        child: InkWell(
          onTap: () => _showEditEmployeeDialog(employee),
          borderRadius: BorderRadius.circular(DesignSystem.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: DesignSystem.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    employee.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      color: DesignSystem.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android,
                            size: 14,
                            color: DesignSystem.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.telefono,
                            style: const TextStyle(
                              fontSize: 13,
                              color: DesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: employee.notificacionesActivas ?? false,
                      onChanged: (val) =>
                          _toggleEmployeeNotifications(employee),
                      activeThumbColor: DesignSystem.successColor,
                    ),
                    ThreeDotsMenuWidget(
                      items: [
                        ThreeDotsMenuItem(
                          icon: Icons.edit_outlined,
                          title: 'Editar',
                          onTap: () => _showEditEmployeeDialog(employee),
                        ),
                        ThreeDotsMenuItem(
                          icon: Icons.calendar_month_outlined,
                          title: 'Horarios',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScheduleManagementScreen(
                                  employee: employee,
                                ),
                              ),
                            );
                          },
                        ),
                        ThreeDotsMenuItem(
                          icon: Icons.delete_outline,
                          title: 'Eliminar',
                          iconColor: DesignSystem.errorColor,
                          textColor: DesignSystem.errorColor,
                          onTap: () => _deleteEmployee(employee),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
