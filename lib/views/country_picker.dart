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
      Country(name: 'Bolivia', code: 'BO', dialCode: '+591', flag: '🇧🇴'),
      Country(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
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
            .where(
              (country) =>
                  country.name.toLowerCase().contains(query.toLowerCase()) ||
                  country.code.toLowerCase().contains(query.toLowerCase()) ||
                  country.dialCode.contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            if (widget.showHeader) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'Seleccionar País',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Ensure text is visible
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                onChanged: _filterCountries,
                decoration: InputDecoration(
                  hintText: 'Buscar país...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCountries.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  final country = filteredCountries[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      country.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      country.dialCode,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    onTap: () {
                      widget.onCountrySelected(country);
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
  Country(name: 'Bolivia', code: 'BO', dialCode: '+591', flag: '🇧🇴'),
  Country(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
];
