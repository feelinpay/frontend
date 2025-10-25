import 'package:flutter/material.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class CountryPicker extends StatefulWidget {
  final String? initialCountry;
  final Function(Country) onCountrySelected;
  final bool showHeader;

  const CountryPicker({
    super.key,
    this.initialCountry,
    required this.onCountrySelected,
    this.showHeader = true,
  });

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  List<Country> countries = [];
  List<Country> filteredCountries = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCountries();

    // Si hay un país inicial, seleccionarlo
    if (widget.initialCountry != null) {
      final initialCountry = countries.firstWhere(
        (country) => country.code == widget.initialCountry,
        orElse: () => countries.first, // Perú por defecto
      );
      widget.onCountrySelected(initialCountry);
    }
  }

  void _loadCountries() {
    countries = [
      Country(name: 'Perú', code: 'PE', dialCode: '+51', flag: '🇵🇪'),
      Country(name: 'Estados Unidos', code: 'US', dialCode: '+1', flag: '🇺🇸'),
      Country(name: 'México', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
      Country(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
      Country(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
      Country(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
      Country(name: 'Brasil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
      Country(name: 'Ecuador', code: 'EC', dialCode: '+593', flag: '🇪🇨'),
      Country(name: 'Bolivia', code: 'BO', dialCode: '+591', flag: '🇧🇴'),
      Country(name: 'Paraguay', code: 'PY', dialCode: '+595', flag: '🇵🇾'),
      Country(name: 'Uruguay', code: 'UY', dialCode: '+598', flag: '🇺🇾'),
      Country(name: 'Venezuela', code: 'VE', dialCode: '+58', flag: '🇻🇪'),
      Country(name: 'España', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
      Country(name: 'Francia', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
      Country(name: 'Alemania', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
      Country(name: 'Italia', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
      Country(name: 'Reino Unido', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
      Country(name: 'Canadá', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
      Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
      Country(name: 'Japón', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
      Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
      Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
      Country(name: 'Rusia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
      Country(name: 'Sudáfrica', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
      Country(name: 'Egipto', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
      Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
      Country(name: 'Kenia', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
      Country(name: 'Marruecos', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
      Country(name: 'Túnez', code: 'TN', dialCode: '+216', flag: '🇹🇳'),
      Country(name: 'Argelia', code: 'DZ', dialCode: '+213', flag: '🇩🇿'),
    ];

    countries.sort((a, b) => a.name.compareTo(b.name));
    filteredCountries = countries;
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCountries = countries;
      } else {
        filteredCountries = countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()) ||
                country.code.toLowerCase().contains(query.toLowerCase()) ||
                country.dialCode.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: widget.showHeader
          ? const Text(
              'Seleccionar País',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            if (widget.showHeader) ...[
              TextField(
                controller: searchController,
                onChanged: _filterCountries,
                decoration: InputDecoration(
                  hintText: 'Buscar país...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = filteredCountries[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(country.dialCode),
                    onTap: () {
                      widget.onCountrySelected(country);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// Lista global de países para uso en otros widgets
final List<Country> countries = [
  Country(name: 'Perú', code: 'PE', dialCode: '+51', flag: '🇵🇪'),
  Country(name: 'Estados Unidos', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  Country(name: 'México', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
  Country(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
  Country(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
  Country(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
  Country(name: 'Brasil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  Country(name: 'Ecuador', code: 'EC', dialCode: '+593', flag: '🇪🇨'),
  Country(name: 'Bolivia', code: 'BO', dialCode: '+591', flag: '🇧🇴'),
  Country(name: 'Paraguay', code: 'PY', dialCode: '+595', flag: '🇵🇾'),
  Country(name: 'Uruguay', code: 'UY', dialCode: '+598', flag: '🇺🇾'),
  Country(name: 'Venezuela', code: 'VE', dialCode: '+58', flag: '🇻🇪'),
  Country(name: 'España', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  Country(name: 'Francia', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  Country(name: 'Alemania', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  Country(name: 'Italia', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
  Country(name: 'Reino Unido', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  Country(name: 'Canadá', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  Country(name: 'Japón', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
  Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
  Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  Country(name: 'Rusia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
  Country(name: 'Sudáfrica', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  Country(name: 'Egipto', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
  Country(name: 'Kenia', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
  Country(name: 'Marruecos', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
  Country(name: 'Túnez', code: 'TN', dialCode: '+216', flag: '🇹🇳'),
  Country(name: 'Argelia', code: 'DZ', dialCode: '+213', flag: '🇩🇿'),
];