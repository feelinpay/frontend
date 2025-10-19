import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../views/android_permissions_screen.dart';

class PermissionGuard extends StatefulWidget {
  final Widget child;

  const PermissionGuard({super.key, required this.child});

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  bool _isCheckingPermissions = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final areGranted = await PermissionService.areAllPermissionsGranted();

    setState(() {
      _permissionsGranted = areGranted;
      _isCheckingPermissions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando permisos...'),
            ],
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      return AndroidPermissionsScreen(
        onPermissionsGranted: () {
          setState(() {
            _permissionsGranted = true;
          });
        },
      );
    }

    return widget.child;
  }
}
