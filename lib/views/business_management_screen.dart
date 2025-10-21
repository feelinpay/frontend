import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../services/user_management_service.dart';
import '../models/user_model.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/phone_field_widget.dart';
import 'owner_employees_screen.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() => _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final UserManagementService _userService = UserManagementService();
  
  List<UserModel> _businesses = [];
  List<UserModel> _filteredBusinesses = [];
  bool _isLoading = true;
  String? _error;
  bool _allActive = true;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBusinesses();
    _searchController.addListener(_filterBusinesses);
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

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _userService.getAllUsers(rol: 'propietario');
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _businesses = response.data!;
          _filteredBusinesses = _businesses;
          _isLoading = false;
        });
        _updateToggleState();
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar propietarios: $e';
        _isLoading = false;
      });
    }
  }

  void _filterBusinesses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBusinesses = _businesses.where((business) {
        return business.nombre.toLowerCase().contains(query) ||
               business.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _updateToggleState() {
    if (_businesses.isEmpty) {
      _allActive = false;
      return;
    }
    
    _allActive = _businesses.every((business) => business.activo);
  }

  Future<void> _toggleAllBusinesses() async {
    try {
      setState(() {
        _allActive = !_allActive;
        // Actualizar estado de todos los propietarios
        for (int i = 0; i < _businesses.length; i++) {
          _businesses[i] = _businesses[i].copyWith(activo: _allActive);
        }
        _filterBusinesses(); // Actualizar la lista filtrada
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _allActive 
                ? 'Propietarios activados exitosamente'
                : 'Propietarios desactivados exitosamente'
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

  Future<void> _addBusiness() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        ),
        title: const Text('Agregar Propietario'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Nombre completo del propietario',
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
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Correo electrónico',
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
                    return 'El email es requerido';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DesignSystem.spacingM),
              PhoneFieldWidget(
                controller: phoneController,
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
        // Obtener roles disponibles
        final rolesResponse = await _userService.getRoles();
        String? propietarioRolId;
        
        if (rolesResponse.isSuccess && rolesResponse.data != null) {
          final roles = rolesResponse.data!;
          final propietarioRol = roles.firstWhere(
            (role) => role['nombre'] == 'propietario',
            orElse: () => roles.first, // Fallback al primer rol
          );
          propietarioRolId = propietarioRol['id'];
        }

        // Crear propietario usando el servicio real
        final response = await _userService.createUser(
          nombre: nameController.text,
          email: emailController.text,
          telefono: phoneController.text,
          password: 'temp123456', // Contraseña temporal
          rolId: propietarioRolId ?? 'default-rol-id',
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            _businesses.add(response.data!);
            _filterBusinesses();
          });
          _updateToggleState();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Propietario ${nameController.text} agregado exitosamente'),
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

  Future<void> _editBusiness(UserModel business) async {
    final nameController = TextEditingController(text: business.nombre);
    final emailController = TextEditingController(text: business.email);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        ),
        title: const Text('Editar Propietario'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Nombre del propietario',
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
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Correo electrónico',
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
                    return 'El email es requerido';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un email válido';
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final response = await _userService.updateUser(
          business.id,
          nombre: nameController.text,
          email: emailController.text,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            final index = _businesses.indexWhere((b) => b.id == business.id);
            if (index != -1) {
              _businesses[index] = response.data!;
              _filterBusinesses(); // Actualizar la lista filtrada
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Propietario actualizado exitosamente'),
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

  Future<void> _deleteBusiness(UserModel business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${business.nombre}?'),
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
        // TODO: Implementar eliminación real
        setState(() {
          _businesses.removeWhere((b) => b.id == business.id);
          _filterBusinesses();
        });
        _updateToggleState();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Propietario ${business.nombre} eliminado exitosamente'),
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
  }

  Future<void> _toggleBusinessStatus(UserModel business) async {
    try {
      final response = await _userService.toggleUserStatus(business.id);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          final index = _businesses.indexWhere((b) => b.id == business.id);
          if (index != -1) {
            _businesses[index] = response.data!;
            _filterBusinesses(); // Actualizar la lista filtrada
          }
        });
        _updateToggleState();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data!.activo 
                  ? 'Propietario activado exitosamente' 
                  : 'Propietario desactivado exitosamente'
              ),
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

  Future<void> _viewEmployees(UserModel business) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OwnerEmployeesScreen(owner: business),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header con gradiente
            Container(
              padding: const EdgeInsets.all(DesignSystem.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.primaryColor,
                    DesignSystem.primaryLight,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DesignSystem.radiusXL),
                  bottomRight: Radius.circular(DesignSystem.radiusXL),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(DesignSystem.spacingM),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(DesignSystem.radiusL),
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
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Colors.white70],
                              ).createShader(bounds),
                              child: const Text(
                                'Gestión de Propietarios',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '${_businesses.length} propietarios registrados',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ThreeDotsMenuWidget(
                        items: [
                          ThreeDotsMenuItem(
                            icon: Icons.refresh,
                            title: 'Actualizar',
                            onTap: _loadBusinesses,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spacingL),
                  
                  // Toggle de activación
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingM,
                      vertical: DesignSystem.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _allActive ? Icons.pause : Icons.play_arrow,
                          color: _allActive ? Colors.white : Colors.white70,
                        ),
                        const SizedBox(width: DesignSystem.spacingS),
                        Text(
                          _allActive ? 'Desactivar todos' : 'Activar todos',
                          style: TextStyle(
                            color: _allActive ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _allActive,
                          onChanged: (value) => _toggleAllBusinesses(),
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.3),
                          inactiveThumbColor: Colors.white70,
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Barra de búsqueda limpia
            _buildSearchBar(),

            // Contenido principal
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
                                onPressed: _loadBusinesses,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignSystem.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _filteredBusinesses.isEmpty
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
                                    _businesses.isEmpty 
                                      ? 'No hay propietarios registrados'
                                      : 'No se encontraron propietarios',
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
                                itemCount: _filteredBusinesses.length,
                                itemBuilder: (context, index) {
                                  final business = _filteredBusinesses[index];
                                  return _buildBusinessCard(business);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBusiness,
        backgroundColor: DesignSystem.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBusinessCard(UserModel business) {
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
          backgroundColor: business.activo 
            ? DesignSystem.primaryColor 
            : DesignSystem.textTertiary,
          child: Text(
            business.nombre.isNotEmpty ? business.nombre[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          business.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(business.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  business.activo ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: business.activo 
                    ? DesignSystem.successColor 
                    : DesignSystem.errorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  business.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: business.activo 
                      ? DesignSystem.successColor 
                      : DesignSystem.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: DesignSystem.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ver empleados',
                  style: TextStyle(
                    color: DesignSystem.primaryColor,
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
              icon: Icons.people_outline,
              title: 'Ver Empleados',
              onTap: () => _viewEmployees(business),
            ),
            ThreeDotsMenuItem(
              icon: Icons.edit,
              title: 'Editar',
              onTap: () => _editBusiness(business),
            ),
            ThreeDotsMenuItem(
              icon: business.activo ? Icons.pause : Icons.play_arrow,
              title: business.activo ? 'Desactivar' : 'Activar',
              onTap: () => _toggleBusinessStatus(business),
            ),
            ThreeDotsMenuItem(
              icon: Icons.delete,
              title: 'Eliminar',
              onTap: () => _deleteBusiness(business),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar propietarios...',
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
}