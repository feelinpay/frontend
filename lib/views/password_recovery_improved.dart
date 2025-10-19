import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import '../services/feelin_pay_service.dart';
import '../core/design/design_system.dart';
import '../core/widgets/responsive_widgets.dart';
import 'otp_verification_improved.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignSystem.animationSlow,
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

    _animationController?.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FeelinPayService.forgotPassword(
        _emailController.text.trim(),
      );

      if (result['success'] == true) {
        setState(() {
          _emailSent = true;
        });
      } else {
        _showError(result['message'] ?? 'Error al enviar el email');
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

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _goToOTPVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginOTPVerificationScreen(
          email: _emailController.text.trim(),
          type: 'password_recovery',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      appBar: ResponsiveAppBar(
        title: 'Recuperar Contraseña',
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
                  _emailSent
                      ? _buildSuccessSection(context)
                      : _buildForm(context),
                  SizedBox(height: DesignSystem.getResponsivePadding(context)),
                  _buildFooter(context),
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
              gradient: DesignSystem.secondaryGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            ),
            child: const Icon(
              Icons.lock_reset,
              color: Colors.white,
              size: DesignSystem.iconSizeXL,
            ),
          ),
          SizedBox(height: DesignSystem.spacingM),
          ResponsiveText('Recuperar Contraseña', type: TextType.headline),
          SizedBox(height: DesignSystem.spacingS),
          ResponsiveText(
            'Te ayudaremos a recuperar el acceso a tu cuenta',
            type: TextType.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignSystem.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ResponsiveCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText('Ingresa tu email', type: TextType.title),
            SizedBox(height: DesignSystem.spacingM),

            ResponsiveInput(
              label: 'Correo electrónico',
              hint: 'Ingresa el email de tu cuenta',
              controller: _emailController,
              validator: ValidationBuilder().email().required().build(),
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email),
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

            ResponsiveButton(
              text: 'Enviar Código de Recuperación',
              onPressed: _isLoading ? null : _sendRecoveryEmail,
              isLoading: _isLoading,
              icon: Icons.send,
              type: ButtonType.primary,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.spacingL),
            decoration: BoxDecoration(
              gradient: DesignSystem.successGradient,
              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
            ),
            child: const Icon(
              Icons.mark_email_read,
              color: Colors.white,
              size: DesignSystem.iconSizeXL,
            ),
          ),
          SizedBox(height: DesignSystem.spacingM),
          ResponsiveText(
            '¡Email Enviado!',
            type: TextType.headline,
            style: const TextStyle(color: DesignSystem.successColor),
          ),
          SizedBox(height: DesignSystem.spacingS),
          ResponsiveText(
            'Hemos enviado un código de recuperación a',
            type: TextType.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignSystem.textSecondary),
          ),
          SizedBox(height: DesignSystem.spacingS),
          ResponsiveText(
            _emailController.text,
            type: TextType.title,
            style: const TextStyle(
              color: DesignSystem.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DesignSystem.spacingM),
          ResponsiveText(
            'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
            type: TextType.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignSystem.textSecondary),
          ),
          SizedBox(height: DesignSystem.spacingL),
          ResponsiveButton(
            text: 'Verificar Código',
            onPressed: _goToOTPVerification,
            icon: Icons.arrow_forward,
            type: ButtonType.primary,
            size: ButtonSize.large,
          ),
          SizedBox(height: DesignSystem.spacingM),
          ResponsiveButton(
            text: 'Reenviar Email',
            onPressed: () {
              setState(() {
                _emailSent = false;
                _errorMessage = null;
              });
            },
            type: ButtonType.secondary,
            size: ButtonSize.medium,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        ResponsiveText(
          '¿Recordaste tu contraseña?',
          type: TextType.body,
          style: const TextStyle(color: DesignSystem.textSecondary),
        ),
        SizedBox(height: DesignSystem.spacingS),
        ResponsiveButton(
          text: 'Iniciar Sesión',
          onPressed: () => Navigator.pop(context),
          type: ButtonType.text,
          size: ButtonSize.medium,
          isFullWidth: false,
        ),
      ],
    );
  }
}
