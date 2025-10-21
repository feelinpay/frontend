import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feelin_pay_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_input_widget.dart';

class LoginOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String type; // 'registration' o 'login'

  const LoginOTPVerificationScreen({
    super.key,
    required this.email,
    this.type = 'login',
  });

  @override
  State<LoginOTPVerificationScreen> createState() =>
      _LoginOTPVerificationScreenState();
}

class _LoginOTPVerificationScreenState extends State<LoginOTPVerificationScreen>
    with TickerProviderStateMixin {
  String _otpCode = '';
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      _showError('Por favor ingresa el código OTP completo');
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔐 [OTP VERIFICATION] Verificando OTP para: ${widget.email}');
      print('🔐 [OTP VERIFICATION] Código: $_otpCode');
      print('🔐 [OTP VERIFICATION] Tipo: ${widget.type}');

      bool success;
      if (widget.type == 'registration') {
        success = await authController.verifyRegistrationOtp(email: widget.email, codigo: _otpCode);
      } else {
        success = await authController.verifyLoginOtp(email: widget.email, codigo: _otpCode);
      }

      print('🔐 [OTP VERIFICATION] Resultado: $success');
      print('🔐 [OTP VERIFICATION] Error: ${authController.error}');

      if (success) {
        print('✅ [OTP VERIFICATION] Verificación exitosa, navegando al dashboard...');
        setState(() {
          _successMessage = widget.type == 'registration'
              ? 'Cuenta verificada exitosamente'
              : 'Verificación exitosa';
        });

        // Navegar al dashboard después de un breve delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
      } else {
        print('❌ [OTP VERIFICATION] Error: ${authController.error}');
        _showError(authController.error ?? 'Código OTP inválido');
      }
    } catch (e) {
      _showError('Error de conexión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Para reenvío de OTP, usamos el servicio directo por ahora
      final result = await FeelinPayService.resendOTP(
        widget.email,
        widget.type,
      );

      if (result['success']) {
        setState(() {
          _successMessage = 'Código OTP reenviado exitosamente';
        });
      } else {
        _showError(result['message'] ?? 'Error al reenviar OTP');
      }
    } catch (e) {
      _showError('Error de conexión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Verificación ${widget.type == 'registration' ? 'de Registro' : 'de Login'}',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user,
                      size: 60,
                      color: Colors.blue[600],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Title
                Text(
                  'Verificación OTP',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'Ingresa el código de 6 dígitos enviado a\n${widget.email}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // OTP Input
                OtpInputWidget(
                  onChanged: (value) {
                    setState(() {
                      _otpCode = value;
                    });
                  },
                  onCompleted: (value) {
                    setState(() {
                      _otpCode = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                // Error message
                if (_errorMessage.isNotEmpty)
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Success message
                if (_successMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage,
                            style: TextStyle(color: Colors.green[600]),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Verify button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Verificar Código',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Resend button
                TextButton(
                  onPressed: _isLoading ? null : _resendOTP,
                  child: const Text('Reenviar Código OTP'),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
