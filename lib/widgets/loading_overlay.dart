import 'package:flutter/material.dart';
import '../core/design/design_system.dart';

/// Widget de overlay de carga que bloquea toda la interfaz
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de carga animado
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignSystem.primaryColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mensaje de carga
              Text(
                message ?? 'Procesando...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: DesignSystem.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Mensaje secundario
              Text(
                'Por favor espera',
                style: TextStyle(
                  fontSize: 14,
                  color: DesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin para manejar el estado de carga en pantallas
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _loadingMessage;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  /// Mostrar overlay de carga
  void showLoading({String? message}) {
    setState(() {
      _isLoading = true;
      _loadingMessage = message;
    });
  }

  /// Ocultar overlay de carga
  void hideLoading() {
    setState(() {
      _isLoading = false;
      _loadingMessage = null;
    });
  }

  /// Ejecutar operación con overlay de carga
  Future<void> executeWithLoading(
    Future<void> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      showLoading(message: loadingMessage);
      await operation();
      
      // Solo mostrar SnackBar de éxito si se especifica explícitamente
      // y no es una operación que debe ser silenciosa
      if (successMessage != null && mounted && successMessage.isNotEmpty) {
        // Usar un SnackBar más rápido y menos intrusivo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: DesignSystem.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500), // Más corto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 80),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Error: $e'),
            backgroundColor: DesignSystem.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3), // Más tiempo para errores
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 80),
          ),
        );
      }
    } finally {
      hideLoading();
    }
  }

  /// Ejecutar operación silenciosa (solo overlay, sin SnackBars)
  Future<void> executeSilently(
    Future<void> Function() operation, {
    String? loadingMessage,
    String? errorMessage,
  }) async {
    try {
      showLoading(message: loadingMessage);
      await operation();
      // Sin SnackBar de éxito para evitar latencia
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Error: $e'),
            backgroundColor: DesignSystem.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 80),
          ),
        );
      }
    } finally {
      hideLoading();
    }
  }
}
