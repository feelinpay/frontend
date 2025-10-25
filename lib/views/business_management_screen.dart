import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design/design_system.dart';
import '../services/user_management_service.dart';
import '../models/user_model.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/loading_overlay.dart';
import '../views/country_picker.dart';
import 'owner_employees_screen.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() => _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen>
    with TickerProviderStateMixin, LoadingStateMixin {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cuando la pantalla se vuelve visible
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadBusinesses();
    }
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
      print('🔍 [BusinessManagementScreen] Loading businesses with rol: propietario');
      final response = await _userService.getAllUsers(rol: 'propietario');
      
      print('🔍 [BusinessManagementScreen] Response received:');
      print('  Success: ${response.isSuccess}');
      print('  Message: ${response.message}');
      print('  Data count: ${response.data?.length ?? 0}');
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _businesses = response.data!;
          _filteredBusinesses = _businesses;
          _isLoading = false;
        });
        _updateToggleState();
        print('🔍 [BusinessManagementScreen] Businesses loaded: ${_businesses.length}');
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
        print('🔍 [BusinessManagementScreen] Error: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar propietarios: $e';
        _isLoading = false;
      });
      print('🔍 [BusinessManagementScreen] Exception: $e');
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
      
      // Sin SnackBar de éxito para evitar latencia
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
    final phoneFieldKey = GlobalKey<_AddBusinessDialogState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddBusinessDialog(
        key: phoneFieldKey,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        formKey: formKey,
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

        // Obtener el número de teléfono completo con código de país
        final fullPhoneNumber = phoneFieldKey.currentState?.getFullPhoneNumber() ?? phoneController.text;

        // Crear propietario usando el servicio real
        final response = await _userService.createUser(
          nombre: nameController.text,
          email: emailController.text,
          telefono: fullPhoneNumber,
          password: 'temp123456', // Contraseña temporal
          rolId: propietarioRolId ?? 'default-rol-id',
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            _businesses.add(response.data!);
            _filterBusinesses();
          });
          _updateToggleState();
          
          // Sin SnackBar de éxito para evitar latencia
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
    final phoneController = TextEditingController(text: business.telefono);
    final formKey = GlobalKey<FormState>();
    final phoneFieldKey = GlobalKey<_EditBusinessDialogState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditBusinessDialog(
        key: phoneFieldKey,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        formKey: formKey,
      ),
    );

    if (result == true) {
      try {
        // Obtener el número de teléfono completo con código de país
        final fullPhoneNumber = phoneFieldKey.currentState?.getFullPhoneNumber() ?? phoneController.text;

        final response = await _userService.updateUser(
          business.id,
          nombre: nameController.text,
          email: emailController.text,
          telefono: fullPhoneNumber,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            final index = _businesses.indexWhere((b) => b.id == business.id);
            if (index != -1) {
              _businesses[index] = response.data!;
              _filterBusinesses(); // Actualizar la lista filtrada
            }
          });
          
          // Sin SnackBar de éxito para evitar latencia
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
      await executeSilently(
        () async {
          final response = await _userService.deleteUser(business.id);
          
          if (response.isSuccess) {
            setState(() {
              _businesses.removeWhere((b) => b.id == business.id);
              _filterBusinesses();
            });
            _updateToggleState();
          } else {
            throw Exception(response.message);
          }
        },
        loadingMessage: 'Eliminando propietario ${business.nombre}...',
        errorMessage: 'Error al eliminar propietario',
      );
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
        
        // Sin SnackBar de éxito para evitar latencia
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
    return LoadingOverlay(
      isLoading: isLoading,
      message: loadingMessage,
      child: Scaffold(
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
                          activeThumbColor: Colors.white,
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
        onPressed: isLoading ? null : _addBusiness,
        backgroundColor: isLoading ? DesignSystem.textTertiary : DesignSystem.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

class _EditBusinessDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final GlobalKey<FormState> formKey;

  const _EditBusinessDialog({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.formKey,
  });

  @override
  State<_EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<_EditBusinessDialog> {
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _getDefaultCountry();
    _parseExistingPhoneNumber();
  }

  Country _getDefaultCountry() {
    return Country(
      name: 'Perú',
      code: 'PE',
      dialCode: '+51',
      flag: '🇵🇪',
    );
  }

  void _parseExistingPhoneNumber() {
    final phoneNumber = widget.phoneController.text;
    if (phoneNumber.isNotEmpty) {
      // Buscar el país que coincida con el código de país del teléfono
      for (final country in countries) {
        if (phoneNumber.startsWith(country.dialCode)) {
          setState(() {
            _selectedCountry = country;
          });
          // Remover el código de país del número para mostrar solo el número
          widget.phoneController.text = phoneNumber.substring(country.dialCode.length);
          break;
        }
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar elegante
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header con título y botón de cierre
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Seleccionar País',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  // Botón de cierre
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Country picker sin header
            Expanded(
              child: CountryPicker(
                showHeader: false,
                onCountrySelected: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtener el número de teléfono completo con código de país
  String getFullPhoneNumber() {
    String phoneNumber = widget.phoneController.text.trim();
    
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    } else {
      return '${_selectedCountry!.dialCode}$phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      title: const Text('Editar Propietario'),
      content: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.nameController,
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
              controller: widget.emailController,
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
            // Campo de teléfono con selector de país
            Row(
              children: [
                // Selector de país
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingM,
                      vertical: DesignSystem.spacingM,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: DesignSystem.textTertiary.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                      color: DesignSystem.surfaceColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedCountry != null) ...[
                          Text(
                            _selectedCountry!.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: DesignSystem.spacingS),
                          Text(
                            _selectedCountry!.dialCode,
                            style: TextStyle(
                              fontSize: DesignSystem.fontSizeM,
                              fontWeight: FontWeight.w500,
                              color: DesignSystem.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(width: DesignSystem.spacingS),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: DesignSystem.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
                // Campo de número
                Expanded(
                  child: TextFormField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeM,
                      color: DesignSystem.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Número de teléfono',
                      hintStyle: TextStyle(
                        fontSize: DesignSystem.fontSizeM,
                        color: DesignSystem.textLight,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: DesignSystem.textSecondary,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacingM,
                        vertical: DesignSystem.spacingM,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: BorderSide(
                          color: DesignSystem.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: BorderSide(
                          color: DesignSystem.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: const BorderSide(
                          color: DesignSystem.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: const BorderSide(
                          color: DesignSystem.errorColor,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: const BorderSide(
                          color: DesignSystem.errorColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: DesignSystem.surfaceColor,
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: DesignSystem.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.formKey.currentState!.validate()) {
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
    );
  }
}

class _AddBusinessDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final GlobalKey<FormState> formKey;

  const _AddBusinessDialog({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.formKey,
  });

  @override
  State<_AddBusinessDialog> createState() => _AddBusinessDialogState();
}

class _AddBusinessDialogState extends State<_AddBusinessDialog> {
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _getDefaultCountry();
  }

  Country _getDefaultCountry() {
    return Country(
      name: 'Perú',
      code: 'PE',
      dialCode: '+51',
      flag: '🇵🇪',
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar elegante
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header con título y botón de cierre
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Seleccionar País',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  // Botón de cierre
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Country picker sin header
            Expanded(
              child: CountryPicker(
                showHeader: false,
                onCountrySelected: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtener el número de teléfono completo con código de país
  String getFullPhoneNumber() {
    String phoneNumber = widget.phoneController.text.trim();
    
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    } else {
      return '${_selectedCountry!.dialCode}$phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      title: const Text('Agregar Propietario'),
      content: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.nameController,
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
              controller: widget.emailController,
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
            // Campo de teléfono con selector de país
            Row(
              children: [
                // Selector de país
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacingM,
                      vertical: DesignSystem.spacingM,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: DesignSystem.textTertiary.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                      color: DesignSystem.surfaceColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedCountry != null) ...[
                          Text(
                            _selectedCountry!.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: DesignSystem.spacingS),
                          Text(
                            _selectedCountry!.dialCode,
                            style: TextStyle(
                              fontSize: DesignSystem.fontSizeM,
                              fontWeight: FontWeight.w500,
                              color: DesignSystem.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(width: DesignSystem.spacingS),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: DesignSystem.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DesignSystem.spacingM),
                // Campo de número
                Expanded(
                  child: TextFormField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: DesignSystem.fontSizeM,
                      color: DesignSystem.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Número de teléfono',
                      hintStyle: TextStyle(
                        fontSize: DesignSystem.fontSizeM,
                        color: DesignSystem.textLight,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: DesignSystem.textSecondary,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacingM,
                        vertical: DesignSystem.spacingM,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: BorderSide(
                          color: DesignSystem.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: BorderSide(
                          color: DesignSystem.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: const BorderSide(
                          color: DesignSystem.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: const BorderSide(
                          color: DesignSystem.errorColor,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                        borderSide: const BorderSide(
                          color: DesignSystem.errorColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: DesignSystem.surfaceColor,
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: DesignSystem.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.formKey.currentState!.validate()) {
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
    );
  }
}