import 'package:flutter/material.dart';
import '../core/design/design_system.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
    // Simular carga de notificaciones - aquí se conectaría con el backend
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _notifications = [
        NotificationItem(
          id: '1',
          title: 'Nuevo pago recibido',
          message: 'Se recibió un pago de S/ 50.00 de Juan Pérez',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          type: NotificationType.payment,
        ),
        NotificationItem(
          id: '2',
          title: 'Empleado agregado',
          message: 'Carlos fue agregado a la lista de empleados',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
          type: NotificationType.employee,
        ),
        NotificationItem(
          id: '3',
          title: 'Sistema actualizado',
          message: 'La aplicación se ha actualizado a la versión 1.2.0',
          time: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          type: NotificationType.system,
        ),
      ];
      _isLoading = false;
    });
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar notificaciones'),
        content: const Text('¿Estás seguro de que deseas eliminar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: DesignSystem.errorColor,
            ),
            child: const Text('Limpiar'),
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
              if (!_isLoading && _notifications.isNotEmpty) _buildActions(),
              Expanded(child: _buildNotificationsList()),
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
            'Notificaciones',
            style: TextStyle(
              fontSize: DesignSystem.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textPrimary,
            ),
          ),
          const Spacer(),
          if (!_isLoading && _notifications.isNotEmpty)
            IconButton(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.clear_all),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    if (unreadCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
      child: Row(
        children: [
          Text(
            '$unreadCount notificaciones no leídas',
            style: const TextStyle(
              color: DesignSystem.textSecondary,
              fontSize: DesignSystem.fontSizeS,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Marcar todas como leídas'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DesignSystem.primaryColor,
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: DesignSystem.textTertiary,
            ),
            SizedBox(height: DesignSystem.spacingM),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: DesignSystem.fontSizeM,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignSystem.spacingM),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? DesignSystem.surfaceColor 
            : DesignSystem.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        border: Border.all(
          color: notification.isRead 
              ? DesignSystem.textTertiary.withOpacity(0.2)
              : DesignSystem.primaryColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(DesignSystem.spacingS),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignSystem.radiusS),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: DesignSystem.iconSizeM,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
            color: DesignSystem.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: const TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: DesignSystem.fontSizeS,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.time),
              style: const TextStyle(
                color: DesignSystem.textTertiary,
                fontSize: DesignSystem.fontSizeXS,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: DesignSystem.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
        },
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return DesignSystem.successColor;
      case NotificationType.employee:
        return DesignSystem.primaryColor;
      case NotificationType.system:
        return DesignSystem.warningColor;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.employee:
        return Icons.person;
      case NotificationType.system:
        return Icons.system_update;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

enum NotificationType {
  payment,
  employee,
  system,
}

