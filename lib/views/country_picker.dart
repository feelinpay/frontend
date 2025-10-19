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
    ];

    // Ordenar alfabéticamente
    countries.sort((a, b) => a.name.compareTo(b.name));
    filteredCountries = List.from(countries);
  }

  void _filterCountries(String query) {
    setState(() {
      filteredCountries = countries.where((country) {
        return country.name.toLowerCase().contains(query.toLowerCase()) ||
            country.code.toLowerCase().contains(query.toLowerCase()) ||
            country.dialCode.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Título (solo si showHeader es true)
        if (widget.showHeader) ...[
          Row(
            children: [
              const Icon(Icons.public, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Seleccionar País',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Barra de búsqueda
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Buscar país...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _filterCountries,
        ),
        const SizedBox(height: 16),

        // Lista de países
        Expanded(
          child: ListView.builder(
            itemCount: filteredCountries.length,
            itemBuilder: (context, index) {
              final country = filteredCountries[index];
              return ListTile(
                title: Text(country.name),
                subtitle: Text('${country.dialCode} (${country.code})'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    country.dialCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                onTap: () {
                  widget.onCountrySelected(country);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CountrySelector extends StatelessWidget {
  final Country? selectedCountry;
  final Function(Country) onCountrySelected;
  final String hintText;

  const CountrySelector({
    super.key,
    this.selectedCountry,
    required this.onCountrySelected,
    this.hintText = 'País',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) =>
              CountryPicker(onCountrySelected: onCountrySelected),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCountry != null) ...[
              Text(selectedCountry!.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                selectedCountry!.dialCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const Icon(Icons.public, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                hintText,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar el país seleccionado de forma compacta
class CountryDisplay extends StatelessWidget {
  final Country? country;
  final Function()? onTap;

  const CountryDisplay({super.key, this.country, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (country == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country!.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              country!.dialCode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
