import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../models/rol_model.dart';
import '../models/permiso_model.dart';
import '../models/api_response.dart' as api_models;
import '../services/rol_service.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/admin_drawer.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_header.dart';
import '../widgets/three_dots_menu_widget.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final RolService _rolService = RolService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<RolModel> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _rolService.getRoles();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _roles = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _showRoleEditorIfNeeded(RolModel? role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleEditorScreen(roleId: role?.id),
      ),
    ).then((_) => _loadRoles());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthController>(context);

    // FIX: PopScope to prevent black screen/app exit
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: DesignSystem.backgroundColor,
        drawer: AdminDrawer(
          user: authProvider.currentUser,
          authController: authProvider,
        ),
        body: Column(
          children: [
            // Custom Header
            AppHeader(
              title: 'Gestión de Permisos',
              subtitle: 'Roles y niveles de acceso',
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              menuItems: [
                ThreeDotsMenuItem(
                  icon: Icons.refresh,
                  title: 'Actualizar',
                  onTap: _loadRoles,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(DesignSystem.spacingM),
                      itemCount: _roles.length,
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        return _buildRoleCard(role);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showRoleEditorIfNeeded(null),
          backgroundColor: DesignSystem.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRoleCard(RolModel role) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          role.nombre.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(role.descripcion),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showRoleEditorIfNeeded(role),
      ),
    );
  }
}

class RoleEditorScreen extends StatefulWidget {
  final String? roleId; // Null for create, String for edit

  const RoleEditorScreen({super.key, this.roleId});

  @override
  State<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends State<RoleEditorScreen> {
  final RolService _rolService = RolService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = true;
  List<PermisoModel> _allPermissions = [];
  final Set<String> _selectedPermissionIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get All Permissions
      final permissionsResponse = await _rolService.getAllPermissions();
      if (permissionsResponse.isSuccess && permissionsResponse.data != null) {
        _allPermissions = permissionsResponse.data!;
      }

      // 2. If Editing, Load Role & Its Permissions
      if (widget.roleId != null) {
        final roleResponse = await _rolService.getRoleWithPermissions(
          widget.roleId!,
        );

        if (roleResponse.isSuccess && roleResponse.data != null) {
          final role = roleResponse.data!;
          _nameController.text = role.nombre;
          _descController.text = role.descripcion;

          if (role.permisos.isNotEmpty) {
            _selectedPermissionIds.clear();
            _selectedPermissionIds.addAll(role.permisos.map((p) => p.id));
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Error cargando datos: $e');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      api_models.ApiResponse<RolModel> result;

      if (widget.roleId != null) {
        result = await _rolService.updateRole(
          widget.roleId!,
          nombre: _nameController.text,
          descripcion: _descController.text,
        );
      } else {
        result = await _rolService.createRole(
          nombre: _nameController.text,
          descripcion: _descController.text,
        );
      }

      if (result.isSuccess && result.data != null) {
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) SnackBarHelper.showError(context, result.message);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Error guardando: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePermission(String permId, bool value) async {
    // Prevent modifying critical roles
    final roleName = _nameController.text.toLowerCase().trim();
    if (widget.roleId != null &&
        (roleName == 'super_admin' || roleName == 'propietario')) {
      SnackBarHelper.showError(
        context,
        'No se pueden modificar permisos de este rol crítico',
      );
      return;
    }
    setState(() {
      if (value) {
        _selectedPermissionIds.add(permId);
      } else {
        _selectedPermissionIds.remove(permId);
      }
    });

    // Immediate sync for existing roles
    if (widget.roleId != null) {
      if (value) {
        await _rolService.assignPermission(widget.roleId!, permId);
      } else {
        await _rolService.removePermission(widget.roleId!, permId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if role is critical
    final isCriticalRole =
        widget.roleId != null &&
        (_nameController.text.toLowerCase().trim() == 'super_admin' ||
            _nameController.text.toLowerCase().trim() == 'propietario');

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: widget.roleId != null ? 'Editar Rol' : 'Nuevo Rol',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            readOnly: isCriticalRole,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Rol',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            readOnly: isCriticalRole,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Permisos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allPermissions.length,
                      itemBuilder: (context, index) {
                        final perm = _allPermissions[index];
                        final isSelected = _selectedPermissionIds.contains(
                          perm.id,
                        );
                        return SwitchListTile(
                          title: Text(perm.nombre),
                          subtitle: Text(perm.modulo),
                          value: isSelected,
                          onChanged: isCriticalRole
                              ? null
                              : (val) => _togglePermission(perm.id, val),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: !isCriticalRole
          ? FloatingActionButton(
              onPressed: _save,
              backgroundColor: DesignSystem.primaryColor,
              child: const Icon(Icons.save, color: Colors.white),
            )
          : null,
    );
  }
}
