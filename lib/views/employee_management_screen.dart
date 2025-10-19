import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/phone_field_widget.dart';
import '../controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen>
    with TickerProviderStateMixin {
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  void _loadEmployees() {
    setState(() {
      _isLoading = true;
    });

    // Simular carga de empleados
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _employees = [
          Employee(
            id: '1',
            name: 'Juan Pérez',
            phone: '+51 987654321',
            notificationsEnabled: true,
          ),
          Employee(
            id: '2',
            name: 'María García',
            phone: '+51 945786512',
            notificationsEnabled: true,
          ),
          Employee(
            id: '3',
            name: 'Carlos López',
            phone: '+51 948567153',
            notificationsEnabled: false,
          ),
          Employee(
            id: '4',
            name: 'Ana Martínez',
            phone: '+51 987654321',
            notificationsEnabled: true,
          ),
          Employee(
            id: '5',
            name: 'Luis Rodríguez',
            phone: '+51 912345678',
            notificationsEnabled: true,
          ),
          Employee(
            id: '6',
            name: 'Sofia Hernández',
            phone: '+51 945123678',
            notificationsEnabled: false,
          ),
          Employee(
            id: '7',
            name: 'Diego Torres',
            phone: '+51 978945612',
            notificationsEnabled: true,
          ),
        ];
        _filteredEmployees = _employees;
        _isLoading = false;
        
        // Actualizar el estado del toggle basado en los empleados reales
        _updateNotificationsToggleState();
      });
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees
            .where((employee) =>
                employee.name.toLowerCase().contains(query.toLowerCase()) ||
                employee.phone.contains(query))
            .toList();
      }
    });
  }

  void _toggleAllNotifications() {
    setState(() {
      // Obtener el estado actual basado en todos los empleados
      bool allEnabled = _employees.every((employee) => employee.notificationsEnabled);
      
      // Si todos están activados, desactivar todos; si no, activar todos
      bool newState = !allEnabled;
      
      for (var employee in _employees) {
        employee.notificationsEnabled = newState;
      }
      
      _notificationsEnabled = newState;
    });
  }


  void _addEmployee() {
    showDialog(
      context: context,
      builder: (context) => _AddEmployeeDialog(
        onEmployeeAdded: (employee) {
          setState(() {
            _employees.add(employee);
            _filteredEmployees = _employees;
            _updateNotificationsToggleState();
          });
        },
      ),
    );
  }

  void _editEmployee(Employee employee) {
    // TODO: Implementar edición de empleado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando ${employee.name}')),
    );
  }

  void _deleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text('¿Estás seguro de que deseas eliminar a ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _employees.removeWhere((e) => e.id == employee.id);
                _filteredEmployees = _employees;
                _updateNotificationsToggleState();
              });
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

  void _toggleEmployeeNotifications(Employee employee) {
    setState(() {
      employee.notificationsEnabled = !employee.notificationsEnabled;
      _updateNotificationsToggleState();
    });
  }

  void _updateNotificationsToggleState() {
    // Verificar si todos los empleados tienen notificaciones activadas
    if (_employees.isEmpty) {
      _notificationsEnabled = false;
    } else {
      _notificationsEnabled = _employees.every((employee) => employee.notificationsEnabled);
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
            activeColor: DesignSystem.primaryColor,
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

  Widget _buildEmployeeItem(Employee employee) {
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
            employee.name[0].toUpperCase(),
            style: const TextStyle(
              color: DesignSystem.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DesignSystem.textPrimary,
          ),
        ),
        subtitle: Text(
          employee.phone,
          style: const TextStyle(color: DesignSystem.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _toggleEmployeeNotifications(employee),
              icon: Icon(
                employee.notificationsEnabled
                    ? Icons.notifications
                    : Icons.notifications_off,
                color: employee.notificationsEnabled
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

class Employee {
  final String id;
  final String name;
  final String phone;
  bool notificationsEnabled;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.notificationsEnabled,
  });
}

class _AddEmployeeDialog extends StatefulWidget {
  final Function(Employee) onEmployeeAdded;

  const _AddEmployeeDialog({required this.onEmployeeAdded});

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

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
            PhoneFieldWidget(
              controller: _phoneController,
              labelText: 'Teléfono',
              hintText: 'Número de teléfono',
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final employee = Employee(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                phone: _phoneController.text,
                notificationsEnabled: true,
              );
              widget.onEmployeeAdded(employee);
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
