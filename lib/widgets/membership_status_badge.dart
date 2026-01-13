import 'package:flutter/material.dart';
import '../models/membership_status_model.dart';
import '../services/membresia_service.dart';

class MembershipStatusBadge extends StatefulWidget {
  final String userId;

  const MembershipStatusBadge({super.key, required this.userId});

  @override
  State<MembershipStatusBadge> createState() => _MembershipStatusBadgeState();
}

class _MembershipStatusBadgeState extends State<MembershipStatusBadge> {
  final MembresiaService _membresiaService = MembresiaService();
  MembershipStatusModel? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final response = await _membresiaService.getUserMembershipStatus(
        widget.userId,
      );

      if (mounted && response.isSuccess && response.data != null) {
        setState(() {
          _status = MembershipStatusModel.fromJson(response.data!);
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(int daysRemaining) {
    if (daysRemaining > 30) return Colors.green;
    if (daysRemaining > 7) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(int daysRemaining) {
    if (daysRemaining > 30) return Icons.check_circle;
    if (daysRemaining > 7) return Icons.warning;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_status == null) {
      return const SizedBox.shrink();
    }

    final daysRemaining = _status!.daysRemaining;
    final color = _getStatusColor(daysRemaining);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(daysRemaining), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$daysRemaining días',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (daysRemaining < 7) ...[
            const SizedBox(width: 4),
            Icon(Icons.priority_high, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}
