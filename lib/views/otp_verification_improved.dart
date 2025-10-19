import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/feelin_pay_service.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';
import 'dashboard_improved.dart';

class LoginOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String type;

  const LoginOTPVerificationScreen({
    Key? key,
    required this.email,
    required this.type,
  }) : super(key: key);

  @override
  State<LoginOTPVerificationScreen> createState() =>
      _LoginOTPVerificationScreenState();
}

class _LoginOTPVerificationScreenState extends State<LoginOTPVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  String? _errorMessage;

  AnimationController? _animationController;
  AnimationController? _shakeController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startResendCountdown();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignSystem.animationSlow,
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: DesignSystem.curveEaseOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: DesignSystem.curveEaseOut,
          ),
        );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.elasticIn),
    );

    _animationController?.forward();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _animationController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showError('Por favor ingresa el código completo');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FeelinPayService.verifyOTP(
        widget.email,
        otp,
        widget.type,
      );

      if (result['success'] == true) {
        if (widget.type == 'login') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showError(result['message'] ?? 'Código inválido');
        _shakeController?.forward().then((_) {
          _shakeController?.reset();
        });
      }
    } catch (e) {
      _showError('Error de conexión. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final result = await FeelinPayService.resendOTP(
        widget.email,
        widget.type,
      );

      if (result['success'] == true) {
        _showSuccess('Código reenviado exitosamente');
        _startResendCountdown();
      } else {
        _showError(result['message'] ?? 'Error al reenviar código');
      }
    } catch (e) {
      _showError('Error de conexión. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignSystem.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        ),
      ),
    );
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      appBar: ResponsiveAppBar(
        title: 'Verificación',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveContainer(
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: SlideTransition(
            position: _slideAnimation!,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: DesignSystem.getResponsivePadding(context)),
                  _buildHeader(context),
                  SizedBox(height: DesignSystem.getResponsivePadding(context)),
                  _buildOTPForm(context),
                  SizedBox(height: DesignSystem.getResponsivePadding(context)),
                  _buildResendSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            decoration: BoxDecoration(
              gradient: DesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.white,
              size: DesignSystem.iconSizeXL,
            ),
          ),
          SizedBox(height: DesignSystem.spacingM),
          ResponsiveText('Verificación de Código', type: TextType.headline),
          SizedBox(height: DesignSystem.spacingS),
          ResponsiveText(
            'Hemos enviado un código de verificación a',
            type: TextType.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignSystem.textSecondary),
          ),
          SizedBox(height: DesignSystem.spacingS),
          ResponsiveText(
            widget.email,
            type: TextType.title,
            style: const TextStyle(
              color: DesignSystem.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          ResponsiveText(
            'Ingresa el código de 6 dígitos',
            type: TextType.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignSystem.spacingL),

          // OTP Input Fields
          AnimatedBuilder(
            animation: _shakeAnimation!,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation!.value, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 55,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: DesignSystem.fontSizeXL,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignSystem.radiusM,
                            ),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? DesignSystem.errorColor
                                  : DesignSystem.textTertiary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignSystem.radiusM,
                            ),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? DesignSystem.errorColor
                                  : DesignSystem.textTertiary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignSystem.radiusM,
                            ),
                            borderSide: const BorderSide(
                              color: DesignSystem.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: DesignSystem.surfaceColor,
                        ),
                        onChanged: (value) => _onOTPChanged(index, value),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          if (_errorMessage != null) ...[
            SizedBox(height: DesignSystem.spacingM),
            Container(
              padding: const EdgeInsets.all(DesignSystem.spacingM),
              decoration: BoxDecoration(
                color: DesignSystem.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                border: Border.all(
                  color: DesignSystem.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: DesignSystem.errorColor,
                    size: DesignSystem.iconSizeS,
                  ),
                  SizedBox(width: DesignSystem.spacingS),
                  Expanded(
                    child: ResponsiveText(
                      _errorMessage!,
                      type: TextType.caption,
                      style: const TextStyle(color: DesignSystem.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: DesignSystem.spacingL),

          // Verify Button
          ResponsiveButton(
            text: 'Verificar Código',
            onPressed: _isLoading ? null : _verifyOTP,
            isLoading: _isLoading,
            icon: Icons.check,
            type: ButtonType.primary,
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          ResponsiveText(
            '¿No recibiste el código?',
            type: TextType.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignSystem.textSecondary),
          ),
          SizedBox(height: DesignSystem.spacingM),

          if (_resendCountdown > 0) ...[
            ResponsiveText(
              'Reenviar en ${_resendCountdown}s',
              type: TextType.caption,
              style: const TextStyle(color: DesignSystem.textTertiary),
            ),
          ] else ...[
            ResponsiveButton(
              text: 'Reenviar Código',
              onPressed: _isResending ? null : _resendOTP,
              isLoading: _isResending,
              icon: Icons.refresh,
              type: ButtonType.secondary,
              size: ButtonSize.medium,
            ),
          ],

          SizedBox(height: DesignSystem.spacingM),

          ResponsiveButton(
            text: 'Cambiar email',
            onPressed: () => Navigator.pop(context),
            type: ButtonType.text,
            size: ButtonSize.small,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}
