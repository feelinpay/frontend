import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/admin_drawer.dart';
import '../services/user_management_service.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../widgets/snackbar_helper.dart';
import '../core/design/design_system.dart';
import '../widgets/assign_membership_dialog.dart';
import '../widgets/membership_status_badge.dart';
import 'owner_employees_screen.dart';
import '../widgets/loading_overlay.dart';
import '../services/membresia_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with LoadingStateMixin {
  List<UserModel> _users = [];
  List<dynamic> _roles = [];
  String? _error;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserManagementService _userManagementService = UserManagementService();
  bool _isInitialLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    MembresiaService.clearCache();
    setState(() => _isInitialLoading = true);
    try {
      _error = null;
      // Cargar usuarios y roles en paralelo
      await Future.wait([_loadUsers(), _loadRoles()]);
      if (mounted) setState(() => _isInitialLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        // Error is handled by _buildErrorWidget via _error state or individual load methods could set it
        // Check if _loadUsers sets state on error? No, it rethrows.
        // So we should catch it here and set _error if we want the error widget.
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _loadUsers() async {
    final response = await _userManagementService.getAllUsers();
    if (response.isSuccess && response.data != null) {
      setState(() => _users = response.data!);
    } else {
      throw Exception(response.message);
    }
  }

  Future<void> _loadRoles() async {
    final response = await _userManagementService.getRoles();
    if (response.isSuccess && response.data != null) {
      setState(() => _roles = response.data!);
    } else {
      throw Exception(response.message);
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${user.nombre}?',
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

      await executeWithLoading(() async {
        final response = await _userManagementService.deleteUser(user.id);

        if (response.isSuccess) {
          setState(() {
            _users.removeWhere((u) => u.id == user.id);
          });
          if (mounted) {
            SnackBarHelper.showSuccess(
              context,
              'Usuario eliminado correctamente',
            );
          }
        } else {
          if (mounted) SnackBarHelper.showError(context, response.message);
        }
      }, loadingMessage: 'Eliminando usuario...');
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    await executeWithLoading(() async {
      final response = await _userManagementService.toggleUserStatus(user.id);

      if (response.isSuccess && response.data != null) {
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = response.data!;
          }
        });
        if (mounted) SnackBarHelper.showSuccess(context, 'Estado actualizado');
      } else {
        if (mounted) SnackBarHelper.showError(context, response.message);
      }
    }, loadingMessage: 'Actualizando estado...');
  }

  @override
  Widget build(BuildContext context) {
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
          user: Provider.of<AuthController>(context).currentUser,
          authController: Provider.of<AuthController>(context, listen: false),
        ),
        body: Column(
          children: [
            AppHeader(
              title: 'Gestión de Usuarios',
              subtitle: 'Total: ${_users.length} usuarios',
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              menuItems: [
                ThreeDotsMenuItem(
                  icon: Icons.refresh,
                  title: 'Actualizar',
                  onTap: _loadData,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LoadingOverlay(
                isLoading: isLoading, // Only for blocking actions
                message: loadingMessage,
                child: _isInitialLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      )
                    : _error != null
                    ? _buildErrorWidget()
                    : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_users.isEmpty) {
      return _buildEmptyState('No hay usuarios disponibles');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;
    final isCurrentUser = currentUser?.id == user.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getUserColor(user.rol),
          backgroundImage: user.imagen != null && user.imagen!.isNotEmpty
              ? NetworkImage(user.imagen!)
              : null,
          child: user.imagen == null || user.imagen!.isEmpty
              ? Text(
                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(user.activo),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildBadge('Rol', user.rol ?? 'Sin rol'),
            if (user.rol?.toLowerCase().trim() == 'propietario') ...[
              const SizedBox(height: 4),
              MembershipStatusBadge(userId: user.id),
            ],
          ],
        ),
        trailing: ThreeDotsMenuWidget(
          items: [
            if ([
              'propietario',
              'super_admin',
            ].contains(user.rol?.toLowerCase().trim()))
              ThreeDotsMenuItem(
                icon: Icons.people_outline,
                title: 'Ver Empleados',
                onTap: () => _viewEmployees(user),
              ),
            if (user.rol?.toLowerCase().trim() == 'propietario')
              ThreeDotsMenuItem(
                icon: Icons.card_membership,
                title: 'Asignar Membresía',
                onTap: () => _showAssignMembershipDialog(user),
              ),
            if (!isCurrentUser) ...[
              ThreeDotsMenuItem(
                icon: user.activo ? Icons.block : Icons.check_circle,
                title: user.activo ? 'Desactivar' : 'Activar',
                onTap: () => _toggleUserStatus(user),
              ),
              ThreeDotsMenuItem(
                icon: Icons.delete,
                title: 'Eliminar',
                onTap: () => _deleteUser(user),
              ),
              ThreeDotsMenuItem(
                icon: Icons.admin_panel_settings,
                title: 'Cambiar Rol',
                onTap: () => _showChangeRoleDialog(user),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Cambiar Rol de ${user.nombre}'),
        children: _roles.map((role) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _changeUserRole(user.id, role['id']);
            },
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _getRoleColor(role['nombre']),
                ),
                const SizedBox(width: 8),
                Text(role['nombre']),
                if (user.rol?.toLowerCase() == role['nombre']?.toLowerCase())
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check, size: 16, color: Colors.green),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _viewEmployees(UserModel user) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OwnerEmployeesScreen(owner: user),
      ),
    );
  }

  Future<void> _changeUserRole(String userId, String roleId) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser;

    if (currentUser?.id == userId) {
      if (mounted) {
        SnackBarHelper.showError(context, 'No puedes modificar tu propio rol');
      }
      return;
    }

    await executeWithLoading(() async {
      final response = await _userManagementService.updateUser(
        userId,
        rolId: roleId,
      );

      if (response.isSuccess) {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Rol actualizado correctamente');
        }
        await _loadUsers();
      } else {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Error al actualizar rol: ${response.message}',
          );
        }
      }
    }, loadingMessage: 'Cambiando rol...');
  }

  Color _getUserColor(String? rol) {
    switch (rol?.toLowerCase()) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'propietario':
        return Colors.blue;
      case 'empleado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String? nombre) {
    switch (nombre?.toLowerCase()) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'propietario':
        return Colors.blue;
      case 'empleado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAssignMembershipDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AssignMembershipDialog(
        user: user,
        onAssigned: () {
          _loadUsers(); // Reload users after assignment
        },
      ),
    );
  }
}
