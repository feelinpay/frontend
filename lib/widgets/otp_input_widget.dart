import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget personalizado para input de OTP de 6 dígitos
class OtpInputWidget extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool autoFocus;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final Color? borderColor;
  final Color? focusColor;
  final Color? fillColor;
  final double? borderRadius;
  final double? width;
  final double? height;

  const OtpInputWidget({
    Key? key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autoFocus = true,
    this.textStyle,
    this.cursorColor,
    this.borderColor,
    this.focusColor,
    this.fillColor,
    this.borderRadius,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _otp;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _otp = List.generate(widget.length, (index) => '');

    // Configurar listeners
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() {
        _onTextChanged(i);
      });
    }

    // Auto focus en el primer campo
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  void _onTextChanged(int index) {
    String text = _controllers[index].text;

    // Si se ingresó más de un carácter, tomar solo el último
    if (text.length > 1) {
      _controllers[index].text = text.substring(text.length - 1);
      text = _controllers[index].text;
    }

    // Actualizar el OTP
    _otp[index] = text;

    // Si se ingresó un carácter y no es el último campo, mover al siguiente
    if (text.isNotEmpty && index < widget.length - 1) {
      Future.microtask(() {
        _focusNodes[index + 1].requestFocus();
      });
    }

    // Si se borró y no es el primer campo, mover al anterior
    if (text.isEmpty && index > 0) {
      Future.microtask(() {
        _focusNodes[index - 1].requestFocus();
      });
    }

    // Notificar cambios
    String currentOtp = _otp.join('');
    widget.onChanged?.call(currentOtp);

    // Si se completó el OTP, notificar
    if (currentOtp.length == widget.length && !currentOtp.contains('')) {
      widget.onCompleted(currentOtp);
    }
  }

  void _onKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          Future.microtask(() {
            _focusNodes[index - 1].requestFocus();
          });
        }
      }
    }
  }

  /// Limpia todos los campos del OTP
  void clearOtp() {
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].clear();
      _otp[i] = '';
    }
    _focusNodes[0].requestFocus();
  }

  /// Obtiene el OTP actual
  String getCurrentOtp() {
    return _otp.join('');
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    // Calcular dimensiones responsivas
    final itemWidth =
        widget.width ??
        (isDesktop
            ? 60.0
            : isTablet
            ? 50.0
            : 45.0);
    final itemHeight =
        widget.height ??
        (isDesktop
            ? 60.0
            : isTablet
            ? 50.0
            : 45.0);
    final spacing = isDesktop
        ? 12.0
        : isTablet
        ? 10.0
        : 8.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Container(
          width: itemWidth,
          height: itemHeight,
          margin: EdgeInsets.only(
            right: index < widget.length - 1 ? spacing : 0,
          ),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyEvent(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style:
                  widget.textStyle ??
                  TextStyle(
                    fontSize: isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
              cursorColor: widget.cursorColor ?? Theme.of(context).primaryColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: widget.fillColor ?? Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? (isDesktop ? 12 : 10),
                  ),
                  borderSide: BorderSide(
                    color: widget.borderColor ?? Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? (isDesktop ? 12 : 10),
                  ),
                  borderSide: BorderSide(
                    color: widget.borderColor ?? Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? (isDesktop ? 12 : 10),
                  ),
                  borderSide: BorderSide(
                    color: widget.focusColor ?? Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : 12,
                  horizontal: 8,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
