import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../widgets/app_header.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/admin_drawer.dart';
import '../services/membresia_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/assign_membership_dialog.dart';
import '../models/user_model.dart';

class MembershipReportsScreen extends StatefulWidget {
  const MembershipReportsScreen({super.key});

  @override
  State<MembershipReportsScreen> createState() =>
      _MembershipReportsScreenState();
}

class _MembershipReportsScreenState extends State<MembershipReportsScreen> {
  final MembresiaService _membresiaService = MembresiaService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _reports = [];
  Map<String, int> _statistics = {
    'total': 0,
    'expired': 0,
    'urgent': 0,
    'soon': 0,
    'active': 0,
    'trial': 0,
  };

  bool _isLoading = true;
  String _currentFilter = 'all';
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final response = await _membresiaService.getMembershipReports(
        filter: _currentFilter,
        search: _searchQuery,
      );

      if (mounted && response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data['reports'] ?? []);
          _statistics = Map<String, int>.from(data['statistics'] ?? {});
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar(response.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _onFilterChanged(String filter) {
    setState(() => _currentFilter = filter);
    _loadReports();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.isEmpty ? null : value);
    _loadReports();
  }

  void _showAssignMembershipDialog(String userId, String userName) async {
    // Create a temporary UserModel to pass to the dialog
    final user = UserModel(
      id: userId,
      nombre: userName,
      email: '',
      rolId: 'mock-id',
      activo: true,
      permissions: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await showDialog(
      context: context,
      builder: (context) => AssignMembershipDialog(
        user: user,
        onAssigned: () {
          _loadReports();
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'expired':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'soon':
        return Colors.yellow.shade700;
      case 'active':
        return Colors.green;
      case 'trial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'expired':
        return 'Vencida';
      case 'urgent':
        return 'Urgente';
      case 'soon':
        return 'Próxima';
      case 'active':
        return 'Activa';
      case 'trial':
        return 'Prueba';
      default:
        return 'Desconocido';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
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
            AppHeader(
              title: 'Reportes de Membresías',
              subtitle: '${_statistics['total']} propietarios',
              showBackButton: false,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              menuItems: [
                ThreeDotsMenuItem(
                  icon: Icons.refresh,
                  title: 'Actualizar',
                  onTap: _loadReports,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildStatisticsSection(),
                        _buildFiltersSection(),
                        Expanded(child: _buildReportsTable()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              'Total',
              _statistics['total'] ?? 0,
              Colors.blue,
              Icons.people,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Vencidas',
              _statistics['expired'] ?? 0,
              Colors.red,
              Icons.error,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Urgentes',
              _statistics['urgent'] ?? 0,
              Colors.orange,
              Icons.warning,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Próximas',
              _statistics['soon'] ?? 0,
              Colors.yellow.shade700,
              Icons.schedule,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Activas',
              _statistics['active'] ?? 0,
              Colors.green,
              Icons.check_circle,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Prueba',
              _statistics['trial'] ?? 0,
              Colors.blue,
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Vencidas', 'expired'),
                const SizedBox(width: 8),
                _buildFilterChip('Urgentes', 'urgent'),
                const SizedBox(width: 8),
                _buildFilterChip('Próximas', 'soon'),
                const SizedBox(width: 8),
                _buildFilterChip('Activas', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Prueba', 'trial'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      selectedColor: DesignSystem.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: DesignSystem.primaryColor,
    );
  }

  Widget _buildReportsTable() {
    if (_reports.isEmpty) {
      return const Center(child: Text('No hay reportes para mostrar'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status'] as String;
    final statusColor = _getStatusColor(status);
    final daysRemaining = report['daysRemaining'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(
            daysRemaining < 7 ? Icons.warning : Icons.person,
            color: statusColor,
          ),
        ),
        title: Text(
          report['nombre'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(report['email'] as String),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$daysRemaining días',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${report['membershipName']} - Vence: ${_formatDate(report['expirationDate'])}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.card_membership),
          onPressed: () => _showAssignMembershipDialog(
            report['userId'] as String,
            report['nombre'] as String,
          ),
          tooltip: 'Asignar Membresía',
        ),
      ),
    );
  }
}
