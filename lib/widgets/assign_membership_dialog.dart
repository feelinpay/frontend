import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/design/design_system.dart';
import '../models/user_model.dart';
import '../models/membresia_model.dart';
import '../models/membership_status_model.dart';
import '../services/membresia_service.dart';

class AssignMembershipDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onAssigned;

  const AssignMembershipDialog({
    super.key,
    required this.user,
    required this.onAssigned,
  });

  @override
  State<AssignMembershipDialog> createState() => _AssignMembershipDialogState();
}

class _AssignMembershipDialogState extends State<AssignMembershipDialog> {
  final MembresiaService _membresiaService = MembresiaService();
  List<MembresiaModel> _plans = [];
  MembershipStatusModel? _currentStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load available plans and user's current status
      final plansResponse = await _membresiaService.getAllMembresias();
      final statusResponse = await _membresiaService.getUserMembershipStatus(
        widget.user.id,
      );

      if (mounted) {
        setState(() {
          if (plansResponse.isSuccess && plansResponse.data != null) {
            _plans = plansResponse.data!.where((plan) => plan.activa).toList();
          }

          if (statusResponse.isSuccess && statusResponse.data != null) {
            _currentStatus = MembershipStatusModel.fromJson(
              statusResponse.data!,
            );
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignMembership(MembresiaModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Asignación'),
        content: Text('¿Asignar "${plan.nombre}" a ${widget.user.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _membresiaService.assignMembership(
        userId: widget.user.id,
        membresiaId: plan.id,
      );

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membresía asignada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onAssigned();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignSystem.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_membership, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asignar Membresía',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.user.nombre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current status
                          if (_currentStatus != null) _buildCurrentStatus(),
                          const SizedBox(height: 16),

                          // Available plans
                          const Text(
                            'Planes Disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_plans.isEmpty)
                            const Center(
                              child: Text('No hay planes disponibles'),
                            )
                          else
                            ..._plans.map((plan) => _buildPlanCard(plan)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStatus!.statusText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_currentStatus!.effectiveExpirationDate != null)
                    Text(
                      'Expira: ${_formatDate(_currentStatus!.effectiveExpirationDate!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  Text(
                    '${_currentStatus!.daysRemaining} días restantes',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentStatus!.daysRemaining < 7
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(MembresiaModel plan) {
    final newExpiration =
        _currentStatus?.calculateNewExpiration(plan.meses) ??
        DateTime.now().add(Duration(days: plan.meses * 30));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duración: ${plan.duracionTexto}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Precio: ${plan.precioFormateado}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _assignMembership(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Asignar'),
                ),
              ],
            ),
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nueva expiración: ${_formatDate(newExpiration)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
