import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todos';

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUsers();
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

  Future<void> _loadUsers() async {
    // Simular carga de usuarios - aquí se conectaría con el backend
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _users = [
        User(
          id: '1',
          name: 'Juan Pérez',
          email: 'juan.perez@restaurante.com',
          phone: '+51 987654321',
          role: 'propietario',
          businessName: 'Restaurante El Buen Sabor',
          employeeCount: 8,
          isActive: true,
          joinDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        User(
          id: '2',
          name: 'María García',
          email: 'maria.garcia@farmacia.com',
          phone: '+51 912345678',
          role: 'propietario',
          businessName: 'Farmacia San José',
          employeeCount: 5,
          isActive: true,
          joinDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
        User(
          id: '3',
          name: 'Carlos López',
          email: 'carlos.lopez@fashion.com',
          phone: '+51 945678123',
          role: 'propietario',
          businessName: 'Tienda de Ropa Fashion',
          employeeCount: 12,
          isActive: false,
          joinDate: DateTime.now().subtract(const Duration(days: 45)),
        ),
        User(
          id: '4',
          name: 'Ana Rodríguez',
          email: 'ana.rodriguez@tienda.com',
          phone: '+51 978945612',
          role: 'propietario',
          businessName: 'Tienda de Electrónicos',
          employeeCount: 6,
          isActive: true,
          joinDate: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ];
      _filteredUsers = _users;
      _isLoading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.businessName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterByRole(String role) {
    setState(() {
      _selectedFilter = role;
      if (role == 'Todos') {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) => user.role == role).toList();
      }
    });
  }

  void _toggleUserStatus(String userId) {
    setState(() {
      final user = _users.firstWhere((u) => u.id == userId);
      user.isActive = !user.isActive;
      _filteredUsers = List.from(_users);
    });
  }

  void _viewUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Teléfono: ${user.phone}'),
            const SizedBox(height: 8),
            Text('Negocio: ${user.businessName}'),
            const SizedBox(height: 8),
            Text('Empleados: ${user.employeeCount}'),
            const SizedBox(height: 8),
            Text('Estado: ${user.isActive ? 'Activo' : 'Inactivo'}'),
            const SizedBox(height: 8),
            Text('Fecha de registro: ${_formatDate(user.joinDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _manageUserEmployees(user);
            },
            child: const Text('Ver Empleados'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleUserStatus(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive 
                  ? DesignSystem.errorColor 
                  : DesignSystem.successColor,
            ),
            child: Text(user.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }

  void _manageUserEmployees(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EmployeeManagementForUserScreen(user: user),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              _buildSearchBar(),
              Expanded(child: _buildUsersList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      child: Row(
        children: [
          const Text(
            'Gestión de Usuarios',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          const Spacer(),
          ThreeDotsMenuWidget(
            items: [
              ThreeDotsMenuItem(
                title: 'Agregar usuario',
                icon: Icons.person_add_outlined,
                onTap: () => _addUser(),
              ),
              ThreeDotsMenuItem(
                title: 'Exportar datos',
                icon: Icons.download_outlined,
                onTap: () => _exportData(),
              ),
              ThreeDotsMenuItem(
                title: 'Estadísticas',
                icon: Icons.analytics_outlined,
                onTap: () => _showStatistics(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      child: Row(
        children: [
          const Text(
            'Filtrar:',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeM,
              fontWeight: FontWeight.w500,
              color: DesignSystem.textPrimary,
            ),
          ),
          const SizedBox(width: DesignSystem.spacingM),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'propietario', 'super_admin'].map((role) {
                  final isSelected = _selectedFilter == role;
                  return Container(
                    margin: const EdgeInsets.only(right: DesignSystem.spacingS),
                    child: FilterChip(
                      label: Text(role == 'Todos' ? 'Todos' : role == 'propietario' ? 'Propietarios' : 'Super Admins'),
                      selected: isSelected,
                      onSelected: (selected) => _filterByRole(role),
                      selectedColor: DesignSystem.primaryColor.withOpacity(0.2),
                      checkmarkColor: DesignSystem.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowS,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterUsers,
        decoration: const InputDecoration(
          hintText: 'Buscar usuarios...',
          hintStyle: TextStyle(color: DesignSystem.textLight),
          prefixIcon: Icon(Icons.search, color: DesignSystem.textLight),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacingM,
            vertical: DesignSystem.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DesignSystem.primaryColor,
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'No hay usuarios registrados',
          style: TextStyle(
            color: DesignSystem.textSecondary,
            fontSize: DesignSystem.fontSizeM,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildUserItem(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowS,
        border: Border.all(
          color: user.isActive 
              ? DesignSystem.successColor.withOpacity(0.3)
              : DesignSystem.errorColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(DesignSystem.spacingM),
          decoration: BoxDecoration(
            color: user.role == 'super_admin' 
                ? DesignSystem.warningColor.withOpacity(0.1)
                : DesignSystem.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          ),
          child: Icon(
            user.role == 'super_admin' ? Icons.admin_panel_settings : Icons.person,
            color: user.role == 'super_admin' 
                ? DesignSystem.warningColor
                : DesignSystem.primaryColor,
            size: DesignSystem.iconSizeM,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DesignSystem.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.businessName,
              style: const TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: DesignSystem.fontSizeS,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${user.employeeCount} empleados',
              style: const TextStyle(
                color: DesignSystem.textTertiary,
                fontSize: DesignSystem.fontSizeXS,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSystem.spacingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: user.isActive 
                    ? DesignSystem.successColor
                    : DesignSystem.errorColor,
                borderRadius: BorderRadius.circular(DesignSystem.radiusS),
              ),
              child: Text(
                user.isActive ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: DesignSystem.fontSizeXS,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: DesignSystem.spacingS),
            const Icon(
              Icons.chevron_right,
              color: DesignSystem.textTertiary,
            ),
          ],
        ),
        onTap: () => _viewUserDetails(user),
      ),
    );
  }

  void _addUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Usuario'),
        content: const Text('Funcionalidad en desarrollo'),
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

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas'),
        content: const Text('Funcionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String businessName;
  final int employeeCount;
  bool isActive;
  final DateTime joinDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.businessName,
    required this.employeeCount,
    required this.isActive,
    required this.joinDate,
  });
}

class _EmployeeManagementForUserScreen extends StatelessWidget {
  final User user;

  const _EmployeeManagementForUserScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empleados de ${user.name}'),
        backgroundColor: DesignSystem.surfaceColor,
        foregroundColor: DesignSystem.textPrimary,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Pantalla de gestión de empleados para este usuario específico\n(Funcionalidad en desarrollo)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignSystem.textSecondary,
            fontSize: DesignSystem.fontSizeM,
          ),
        ),
      ),
    );
  }
}
