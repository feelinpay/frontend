import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_validator/form_validator.dart';
import '../services/feelin_pay_service.dart';
import 'country_picker.dart';
import 'dashboard_improved.dart';
import 'password_recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true;
  Country? _selectedCountry;

  // Focus control
  FocusNode? _passwordFocusNode;
  bool _passwordFieldHasFocus = false;

  AnimationController? _animationController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Inicializar FocusNode
    _passwordFocusNode = FocusNode();

    // Inicializar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
        );

    _isInitialized = true;

    // Establecer Perú como país por defecto
    _selectedCountry = Country(
      name: 'Perú',
      code: 'PE',
      dialCode: '+51',
      flag: '🇵🇪',
    );

    // Iniciar animaciones
    _animationController!.forward();
    _slideController!.forward();

    // Listener para limpiar automáticamente el email mientras se escribe
    _emailController.addListener(() {
      final currentText = _emailController.text;
      final cleanText = currentText.trim().toLowerCase();
      if (currentText != cleanText) {
        _emailController.value = _emailController.value.copyWith(
          text: cleanText,
          selection: TextSelection.collapsed(offset: cleanText.length),
        );
      }
    });

    // Listener para actualizar los requisitos de contraseña en tiempo real
    _passwordController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Listener para controlar el foco del campo de contraseña
    _passwordFocusNode?.addListener(() {
      if (mounted) {
        setState(() {
          _passwordFieldHasFocus = _passwordFocusNode?.hasFocus ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _slideController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _passwordFocusNode?.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _obscurePassword = true;
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar elegante
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header simple
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  // Icono con gradiente
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Título simple
                  const Expanded(
                    child: Text(
                      'Seleccionar País',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Botón de cierre
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Country picker sin header
            Expanded(
              child: CountryPicker(
                showHeader: false,
                onCountrySelected: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await FeelinPayService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('🔍 [LOGIN SCREEN] Resultado del login: $result');
      print('🔍 [LOGIN SCREEN] Tipo de resultado: ${result.runtimeType}');
      print('🔍 [LOGIN SCREEN] Claves disponibles: ${result.keys.toList()}');

      if (result['success'] == true) {
        print('🔍 [LOGIN SCREEN] Login exitoso, verificando OTP...');
        print('🔍 [LOGIN SCREEN] requiresOTP: ${result['requiresOTP']}');
        print(
          '🔍 [LOGIN SCREEN] requiresOTP tipo: ${result['requiresOTP'].runtimeType}',
        );

        if (result['requiresOTP'] == true) {
          print('🔍 [LOGIN SCREEN] Redirigiendo a verificación OTP...');
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/otp-verification',
              arguments: {
                'email': _emailController.text.trim(),
                'type': 'login',
              },
            );
          }
        } else {
          print('🔍 [LOGIN SCREEN] Redirigiendo al dashboard...');
          if (mounted) {
            print('🔍 [LOGIN SCREEN] Context mounted, navegando...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
            print('🔍 [LOGIN SCREEN] Navegación ejecutada');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error al iniciar sesión'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Formatear el teléfono con código de país
      String telefonoCompleto = _telefonoController.text.trim();

      // Si el teléfono ya tiene código de país, usarlo tal como está
      if (telefonoCompleto.startsWith('+')) {
        // Ya tiene código de país
      } else if (_selectedCountry != null) {
        // Agregar código de país si no lo tiene
        telefonoCompleto = '${_selectedCountry!.dialCode}$telefonoCompleto';
      }

      final result = await FeelinPayService.register(
        nombre: _nombreController.text.trim(),
        telefono: telefonoCompleto,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('🔍 [REGISTER] Resultado del registro: $result');
      print('🔍 [REGISTER] success: ${result['success']}');
      print('🔍 [REGISTER] message: ${result['message']}');
      print('🔍 [REGISTER] mounted: $mounted');

      if (result['success'] == true) {
        print('🔍 [REGISTER] Navegando a OTP verification...');
        if (mounted) {
          // Navegar a la pantalla de verificación OTP
          Navigator.pushNamed(
            context,
            '/otp-verification',
            arguments: {
              'email': _emailController.text.trim(),
              'type': 'registration',
            },
          );
          print('🔍 [REGISTER] Navegación ejecutada');
        }
      } else {
        print('🔍 [REGISTER] Mostrando error: ${result['message']}');
        if (mounted) {
          print('🔍 [REGISTER] Context mounted, mostrando SnackBar...');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al registrarse'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          print('🔍 [REGISTER] SnackBar mostrado');
        } else {
          print(
            '🔍 [REGISTER] Context no mounted, no se puede mostrar SnackBar',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? 32.0 : 20.0,
                      vertical: isVerySmallScreen ? 16.0 : 24.0,
                    ),
                    child:
                        _isInitialized &&
                            _fadeAnimation != null &&
                            _slideAnimation != null
                        ? FadeTransition(
                            opacity: _fadeAnimation!,
                            child: SlideTransition(
                              position: _slideAnimation!,
                              child: _buildResponsiveContent(
                                isSmallScreen,
                                isVerySmallScreen,
                              ),
                            ),
                          )
                        : _buildResponsiveContent(
                            isSmallScreen,
                            isVerySmallScreen,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(bool isSmallScreen, bool isVerySmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Espaciado superior adaptativo
        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),

        // Logo y título moderno
        _buildHeader(isSmallScreen, isVerySmallScreen),

        SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 48)),

        // Card principal con formulario
        _buildMainCard(isSmallScreen, isVerySmallScreen),

        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32)),

        // Enlaces adicionales
        _buildAdditionalLinks(),

        // Espaciado inferior adaptativo
        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
      ],
    );
  }

  Widget _buildHeader(bool isSmallScreen, bool isVerySmallScreen) {
    final logoSize = isVerySmallScreen ? 60.0 : (isSmallScreen ? 70.0 : 80.0);
    final iconSize = isVerySmallScreen ? 30.0 : (isSmallScreen ? 35.0 : 40.0);
    final titleFontSize = isVerySmallScreen
        ? 24.0
        : (isSmallScreen ? 28.0 : 32.0);
    final subtitleFontSize = isVerySmallScreen
        ? 14.0
        : (isSmallScreen ? 16.0 : 18.0);

    return Column(
      children: [
        // Logo con gradiente
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(logoSize * 0.25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.payment, color: Colors.white, size: iconSize),
        ),

        SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),

        Text(
          'Feelin Pay',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            letterSpacing: -1.0,
          ),
        ),

        SizedBox(height: isVerySmallScreen ? 4 : 8),

        Text(
          _isLoginMode ? 'Bienvenido de vuelta' : 'Crea tu cuenta',
          style: TextStyle(
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(bool isSmallScreen, bool isVerySmallScreen) {
    final padding = isVerySmallScreen ? 20.0 : (isSmallScreen ? 24.0 : 32.0);
    final borderRadius = isVerySmallScreen
        ? 16.0
        : (isSmallScreen ? 20.0 : 24.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle entre Login y Registro
            _buildModeToggle(isSmallScreen, isVerySmallScreen),

            SizedBox(
              height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32),
            ),

            // Campos del formulario
            if (!_isLoginMode) ...[
              _buildNameField(isSmallScreen, isVerySmallScreen),
              SizedBox(height: isVerySmallScreen ? 16 : 20),
              _buildPhoneField(isSmallScreen, isVerySmallScreen),
              SizedBox(height: isVerySmallScreen ? 16 : 20),
            ],

            _buildEmailField(isSmallScreen, isVerySmallScreen),
            SizedBox(height: isVerySmallScreen ? 16 : 20),

            _buildPasswordField(isSmallScreen, isVerySmallScreen),

            // Indicador de requisitos de contraseña (solo en registro, enfocado, con texto y si no cumple todos los requisitos)
            if (!_isLoginMode &&
                _passwordFieldHasFocus &&
                _passwordController.text.isNotEmpty &&
                !_allPasswordRequirementsMet()) ...[
              // Debug logs
              Builder(
                builder: (context) {
                  print('🔍 [LOGIN] Mostrando validaciones');
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: isVerySmallScreen ? 12 : 16),
              _buildPasswordRequirements(isSmallScreen, isVerySmallScreen),
            ],

            SizedBox(
              height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32),
            ),

            // Botón principal
            _buildMainButton(isSmallScreen, isVerySmallScreen),

            SizedBox(
              height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
            ),

            // Botón de cambio de modo
            _buildToggleButton(isSmallScreen, isVerySmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final verticalPadding = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isLoginMode) _toggleMode();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: _isLoginMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isLoginMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Iniciar Sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: _isLoginMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isLoginMode) _toggleMode();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: !_isLoginMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isLoginMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Registrarse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: !_isLoginMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final borderRadius = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);
    final contentPadding = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre completo',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        TextFormField(
          controller: _nombreController,
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            hintText: 'Ingresa tu nombre completo',
            hintStyle: TextStyle(fontSize: fontSize),
            prefixIcon: Icon(
              Icons.person_outline,
              color: const Color(0xFF9CA3AF),
              size: isVerySmallScreen ? 18 : 20,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: contentPadding,
              vertical: contentPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: ValidationBuilder()
              .required('El nombre es requerido')
              .regExp(
                RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$'),
                'El nombre solo puede contener letras y espacios',
              )
              .build(),
        ),
      ],
    );
  }

  Widget _buildPhoneField(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final borderRadius = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);
    final contentPadding = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);
    final fieldHeight = isVerySmallScreen
        ? 48.0
        : (isSmallScreen ? 52.0 : 56.0);
    final countryWidth = isVerySmallScreen
        ? 80.0
        : (isSmallScreen ? 90.0 : 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teléfono',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        Row(
          children: [
            // Selector de país simple
            GestureDetector(
              onTap: () {
                _showCountryPicker();
              },
              child: Container(
                width: countryWidth,
                height: fieldHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: contentPadding * 0.75,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Código de país
                    Text(
                      _selectedCountry?.dialCode ?? '+51',
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Icono dropdown
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF9CA3AF),
                      size: isVerySmallScreen ? 14 : 16,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: isVerySmallScreen ? 8 : 12),
            // Campo de número
            Expanded(
              child: TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  hintText: 'Número de teléfono',
                  hintStyle: TextStyle(fontSize: fontSize),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: isVerySmallScreen ? 18 : 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: contentPadding,
                    vertical: contentPadding,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(
                      color: Color(0xFF667EEA),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  if (_selectedCountry == null) {
                    return 'Selecciona un país';
                  }
                  if (value.length < 7) {
                    return 'El teléfono debe tener al menos 7 dígitos';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final borderRadius = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);
    final contentPadding = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo electrónico',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            hintText: 'Ingresa tu correo electrónico',
            hintStyle: TextStyle(fontSize: fontSize),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: const Color(0xFF9CA3AF),
              size: isVerySmallScreen ? 18 : 20,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: contentPadding,
              vertical: contentPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: ValidationBuilder()
              .required('El correo es requerido')
              .email('Ingresa un correo válido')
              .build(),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final borderRadius = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);
    final contentPadding = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 6 : 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode ?? FocusNode(),
          obscureText: _obscurePassword,
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            hintText: 'Ingresa tu contraseña',
            hintStyle: TextStyle(fontSize: fontSize),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: const Color(0xFF9CA3AF),
              size: isVerySmallScreen ? 18 : 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
                size: isVerySmallScreen ? 18 : 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: contentPadding,
              vertical: contentPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La contraseña es requerida';
            }
            // Solo aplicar validaciones estrictas en modo registro
            if (!_isLoginMode) {
              if (value.length < 8) {
                return 'La contraseña debe tener al menos 8 caracteres';
              }
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                return 'La contraseña debe contener al menos:\n• Una letra minúscula\n• Una letra mayúscula\n• Un número';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(
    bool isSmallScreen,
    bool isVerySmallScreen,
  ) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);
    final padding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);
    final borderRadius = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0369A1),
              fontSize: fontSize,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 6 : 8),
          _buildPasswordRequirement(
            'Al menos 8 caracteres',
            _passwordController.text.length >= 8,
            isSmallScreen,
            isVerySmallScreen,
          ),
          _buildPasswordRequirement(
            'Una letra minúscula',
            RegExp(r'[a-z]').hasMatch(_passwordController.text),
            isSmallScreen,
            isVerySmallScreen,
          ),
          _buildPasswordRequirement(
            'Una letra mayúscula',
            RegExp(r'[A-Z]').hasMatch(_passwordController.text),
            isSmallScreen,
            isVerySmallScreen,
          ),
          _buildPasswordRequirement(
            'Un número',
            RegExp(r'\d').hasMatch(_passwordController.text),
            isSmallScreen,
            isVerySmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(
    String text,
    bool isMet,
    bool isSmallScreen,
    bool isVerySmallScreen,
  ) {
    final fontSize = isVerySmallScreen ? 10.0 : (isSmallScreen ? 11.0 : 12.0);
    final iconSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 15.0 : 16.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 1 : 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: iconSize,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
          ),
          SizedBox(width: isVerySmallScreen ? 6 : 8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: isMet ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 15.0 : 16.0);
    final buttonHeight = isVerySmallScreen
        ? 48.0
        : (isSmallScreen ? 52.0 : 56.0);
    final borderRadius = isVerySmallScreen
        ? 8.0
        : (isSmallScreen ? 10.0 : 12.0);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isLoginMode ? _login : _register),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: isVerySmallScreen ? 16 : 20,
                height: isVerySmallScreen ? 16 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLoginMode ? 'Iniciar Sesión' : 'Crear Cuenta',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton(bool isSmallScreen, bool isVerySmallScreen) {
    final fontSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);

    return Center(
      child: TextButton(
        onPressed: _toggleMode,
        child: RichText(
          text: TextSpan(
            text: _isLoginMode ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: fontSize,
            ),
            children: [
              TextSpan(
                text: _isLoginMode ? 'Regístrate' : 'Inicia sesión',
                style: const TextStyle(
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalLinks() {
    return Column(
      children: [
        if (_isLoginMode) ...[
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordRecoveryScreen(),
                ),
              );
            },
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: Color(0xFF667EEA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        Text(
          'Al continuar, aceptas nuestros términos de servicio y política de privacidad',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  bool _allPasswordRequirementsMet() {
    final password = _passwordController.text;
    return password.length >= 8 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }
}
