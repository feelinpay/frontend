import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  State<BusinessManagementScreen> createState() => _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Business> _businesses = [];
  List<Business> _filteredBusinesses = [];
  bool _isLoading = true;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBusinesses();
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
    // Simular carga de negocios - aquí se conectaría con el backend
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _businesses = [
        Business(
          id: '1',
          name: 'Restaurante El Buen Sabor',
          owner: 'Juan Pérez',
          email: 'juan.perez@restaurante.com',
          phone: '+51 987654321',
          employeesCount: 8,
          isActive: true,
          joinDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Business(
          id: '2',
          name: 'Farmacia San José',
          owner: 'María García',
          email: 'maria.garcia@farmacia.com',
          phone: '+51 912345678',
          employeesCount: 5,
          isActive: true,
          joinDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Business(
          id: '3',
          name: 'Tienda de Ropa Fashion',
          owner: 'Carlos López',
          email: 'carlos.lopez@fashion.com',
          phone: '+51 945678123',
          employeesCount: 12,
          isActive: false,
          joinDate: DateTime.now().subtract(const Duration(days: 45)),
        ),
      ];
      _filteredBusinesses = _businesses;
      _isLoading = false;
    });
  }

  void _filterBusinesses(String query) {
    setState(() {
      _filteredBusinesses = _businesses
          .where((business) =>
              business.name.toLowerCase().contains(query.toLowerCase()) ||
              business.owner.toLowerCase().contains(query.toLowerCase()) ||
              business.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleBusinessStatus(String businessId) {
    setState(() {
      final business = _businesses.firstWhere((b) => b.id == businessId);
      business.isActive = !business.isActive;
      _filteredBusinesses = List.from(_businesses);
    });
  }

  void _viewBusinessDetails(Business business) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(business.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propietario: ${business.owner}'),
            const SizedBox(height: 8),
            Text('Email: ${business.email}'),
            const SizedBox(height: 8),
            Text('Teléfono: ${business.phone}'),
            const SizedBox(height: 8),
            Text('Empleados: ${business.employeesCount}'),
            const SizedBox(height: 8),
            Text('Estado: ${business.isActive ? 'Activo' : 'Inactivo'}'),
            const SizedBox(height: 8),
            Text('Fecha de registro: ${_formatDate(business.joinDate)}'),
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
              _toggleBusinessStatus(business.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: business.isActive 
                  ? DesignSystem.errorColor 
                  : DesignSystem.successColor,
            ),
            child: Text(business.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
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
              _buildSearchBar(),
              Expanded(child: _buildBusinessList()),
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
            'Gestión de Negocios',
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
        onChanged: _filterBusinesses,
        decoration: const InputDecoration(
          hintText: 'Buscar negocios...',
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

  Widget _buildBusinessList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DesignSystem.primaryColor,
        ),
      );
    }

    if (_filteredBusinesses.isEmpty) {
      return const Center(
        child: Text(
          'No hay negocios registrados',
          style: TextStyle(
            color: DesignSystem.textSecondary,
            fontSize: DesignSystem.fontSizeM,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      itemCount: _filteredBusinesses.length,
      itemBuilder: (context, index) {
        final business = _filteredBusinesses[index];
        return _buildBusinessItem(business);
      },
    );
  }

  Widget _buildBusinessItem(Business business) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowS,
        border: Border.all(
          color: business.isActive 
              ? DesignSystem.successColor.withOpacity(0.3)
              : DesignSystem.errorColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(DesignSystem.spacingM),
          decoration: BoxDecoration(
            color: business.isActive 
                ? DesignSystem.successColor.withOpacity(0.1)
                : DesignSystem.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          ),
          child: Icon(
            Icons.business,
            color: business.isActive 
                ? DesignSystem.successColor
                : DesignSystem.errorColor,
            size: DesignSystem.iconSizeM,
          ),
        ),
        title: Text(
          business.name,
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
              'Propietario: ${business.owner}',
              style: const TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: DesignSystem.fontSizeS,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${business.employeesCount} empleados',
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
                color: business.isActive 
                    ? DesignSystem.successColor
                    : DesignSystem.errorColor,
                borderRadius: BorderRadius.circular(DesignSystem.radiusS),
              ),
              child: Text(
                business.isActive ? 'Activo' : 'Inactivo',
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
        onTap: () => _viewBusinessDetails(business),
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

class Business {
  final String id;
  final String name;
  final String owner;
  final String email;
  final String phone;
  final int employeesCount;
  bool isActive;
  final DateTime joinDate;

  Business({
    required this.id,
    required this.name,
    required this.owner,
    required this.email,
    required this.phone,
    required this.employeesCount,
    required this.isActive,
    required this.joinDate,
  });
}
