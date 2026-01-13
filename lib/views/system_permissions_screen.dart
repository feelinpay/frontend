import 'package:flutter/material.dart';
import '../services/api_service.dart';
// import 'package:flutter_notification_listener_plus/flutter_notification_listener_plus.dart';
// import '../services/notification_reader_service.dart';

class SystemPermissionsScreen extends StatefulWidget {
  const SystemPermissionsScreen({super.key});

  @override
  State<SystemPermissionsScreen> createState() =>
      _SystemPermissionsScreenState();
}

class _SystemPermissionsScreenState extends State<SystemPermissionsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _permissions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService().get<Map<String, dynamic>>(
        '/system/permissions',
      );

      if (response.isSuccess) {
        // ApiService parses JSON automatically, but we need to match the structure
        // If ApiService returns Map<String, dynamic>, we can use it directly
        // However, if the response is dynamic, we need to cast or ensure it is what we expect.
        // Assuming ApiService returns the parsed JSON body.
        setState(() {
          _permissions = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar permisos: ${response.message}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildPermissionsContent(),
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
          ElevatedButton(
            onPressed: _loadPermissions,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsContent() {
    final permissions = _permissions?['data']?['permisos'] as List? ?? [];
    final totalPermisos = _permissions?['data']?['totalPermisos'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Sistema de Permisos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total de permisos: $totalPermisos',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lista de permisos
          if (permissions.isEmpty)
            _buildEmptyState()
          else
            ...permissions.map(
              (permission) => _buildPermissionCard(permission),
            ),

          const SizedBox(height: 32),
          _buildDebugSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.security_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay permisos disponibles',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(Map<String, dynamic> permission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPermissionIcon(permission['modulo']),
                  color: _getPermissionColor(permission['modulo']),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    permission['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              permission['descripcion'] ?? 'Sin descripción',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBadge('Módulo', permission['modulo'] ?? 'N/A'),
                const SizedBox(width: 8),
                _buildBadge('Acción', permission['accion'] ?? 'N/A'),
              ],
            ),
          ],
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

  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🛠️ Zona de Pruebas (Debug)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _simulateYapePayment,
              icon: const Icon(Icons.notifications_active),
              label: const Text("Simular Yape de S/ 1.00"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7421B0), // Yape color
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateYapePayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚀 Simulación deshabilitada (Servicio actualizado)"),
      ),
    );
  }

  IconData _getPermissionIcon(String? modulo) {
    switch (modulo?.toLowerCase()) {
      case 'usuarios':
        return Icons.people;
      case 'empleados':
        return Icons.badge;
      case 'pagos':
        return Icons.payment;
      case 'reportes':
        return Icons.analytics;
      case 'membresias':
        return Icons.card_membership;
      case 'sistema':
        return Icons.settings;
      default:
        return Icons.security;
    }
  }

  Color _getPermissionColor(String? modulo) {
    switch (modulo?.toLowerCase()) {
      case 'usuarios':
        return Colors.blue;
      case 'empleados':
        return Colors.green;
      case 'pagos':
        return Colors.orange;
      case 'reportes':
        return Colors.purple;
      case 'membresias':
        return Colors.teal;
      case 'sistema':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
