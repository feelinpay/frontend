import 'package:flutter/material.dart';
import '../core/design/design_system.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  List<FavoriteItem> _favorites = [];
  bool _isLoading = true;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavorites();
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
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    // Simular carga de favoritos - aquí se conectaría con el backend
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _favorites = [
        FavoriteItem(
          id: '1',
          title: 'Pagos de hoy',
          subtitle: 'Resumen de pagos recibidos',
          icon: Icons.today,
          color: DesignSystem.successColor,
          action: () => _showTodaysPayments(),
        ),
        FavoriteItem(
          id: '2',
          title: 'Empleados activos',
          subtitle: 'Lista de empleados con notificaciones activas',
          icon: Icons.people,
          color: DesignSystem.primaryColor,
          action: () => _showActiveEmployees(),
        ),
        FavoriteItem(
          id: '3',
          title: 'Reporte semanal',
          subtitle: 'Estadísticas de la semana',
          icon: Icons.bar_chart,
          color: DesignSystem.warningColor,
          action: () => _showWeeklyReport(),
        ),
        FavoriteItem(
          id: '4',
          title: 'Configuración rápida',
          subtitle: 'Ajustes frecuentes',
          icon: Icons.settings,
          color: DesignSystem.textSecondary,
          action: () => _showQuickSettings(),
        ),
      ];
      _isLoading = false;
    });
  }

  void _showTodaysPayments() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pagos de hoy'),
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

  void _showActiveEmployees() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empleados activos'),
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

  void _showWeeklyReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reporte semanal'),
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

  void _showQuickSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración rápida'),
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
              Expanded(child: _buildFavoritesList()),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: DesignSystem.spacingS),
          const Text(
            'Favoritos',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showAddFavoriteDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DesignSystem.primaryColor,
        ),
      );
    }

    if (_favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: DesignSystem.textTertiary,
            ),
            SizedBox(height: DesignSystem.spacingM),
            Text(
              'No hay favoritos',
              style: TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: DesignSystem.fontSizeM,
              ),
            ),
            SizedBox(height: DesignSystem.spacingS),
            Text(
              'Agrega tus acciones favoritas aquí',
              style: TextStyle(
                color: DesignSystem.textTertiary,
                fontSize: DesignSystem.fontSizeS,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return _buildFavoriteItem(favorite);
      },
    );
  }

  Widget _buildFavoriteItem(FavoriteItem favorite) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowS,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(DesignSystem.spacingM),
          decoration: BoxDecoration(
            color: favorite.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          ),
          child: Icon(
            favorite.icon,
            color: favorite.color,
            size: DesignSystem.iconSizeM,
          ),
        ),
        title: Text(
          favorite.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DesignSystem.textPrimary,
          ),
        ),
        subtitle: Text(
          favorite.subtitle,
          style: const TextStyle(
            color: DesignSystem.textSecondary,
            fontSize: DesignSystem.fontSizeS,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: DesignSystem.textTertiary,
        ),
        onTap: favorite.action,
      ),
    );
  }

  void _showAddFavoriteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar a favoritos'),
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

class FavoriteItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback action;

  FavoriteItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.action,
  });
}

