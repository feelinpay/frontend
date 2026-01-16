import 'package:flutter/material.dart';
import '../core/design/design_system.dart';
import '../widgets/app_header.dart';
import '../widgets/snackbar_helper.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';

class ScheduleManagementScreen extends StatefulWidget {
  final EmployeeModel employee;

  const ScheduleManagementScreen({super.key, required this.employee});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  String? _error;

  // Estructura: 'Lunes': [ { 'id': '...', 'startTime': TimeOfDay(...), 'endTime': TimeOfDay(...), 'enabled': true } ]
  Map<String, List<Map<String, dynamic>>> _schedules = {};

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadSchedules();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSchedules() async {
    final response = await _employeeService.getWorkSchedules(
      widget.employee.id,
    );

    // Inicializar mapa con lista vacía
    final newSchedules = {
      for (var day in _daysOfWeek) day: <Map<String, dynamic>>[],
    };

    if (response.isSuccess && response.data != null) {
      final jsonSchedule = response.data!;

      for (var day in _daysOfWeek) {
        if (jsonSchedule.containsKey(day) && jsonSchedule[day] is List) {
          final items = jsonSchedule[day] as List;
          for (var item in items) {
            newSchedules[day]!.add({
              'enabled': item['activo'] ?? true,

              'startTime': _parseTime(item['horaInicio']),
              'endTime': _parseTime(item['horaFin']),
            });
          }
        }
      }
    }

    _schedules = newSchedules;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveAllSchedules() async {
    setState(() => _isLoading = true);

    // Preparar el JSON para enviar
    final Map<String, dynamic> scheduleJson = {};

    _schedules.forEach((day, turns) {
      if (turns.isNotEmpty) {
        scheduleJson[day] = turns
            .map(
              (t) => {
                'horaInicio': _formatTime(t['startTime'] as TimeOfDay),

                'horaFin': _formatTime(t['endTime'] as TimeOfDay),
                'activo': t['enabled'] as bool,
              },
            )
            .toList();
      }
    });

    try {
      final response = await _employeeService.updateWorkSchedule(
        employeeId: widget.employee.id,
        horarioLaboral: scheduleJson,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        SnackBarHelper.showSuccess(context, 'Horarios guardados correctamente');
        // Recargar para sincronizar (aunque ahora es local-first)
        await _loadSchedules();
      } else {
        SnackBarHelper.showError(
          context,
          'Error al guardar: ${response.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DesignSystem.backgroundColor,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(DesignSystem.spacingM),
        decoration: BoxDecoration(color: Colors.white, boxShadow: const []),
        child: SafeArea(child: _buildSaveButton()),
      ),
      body: Column(
        children: [
          AppHeader(
            title: 'Gestión de Horario',
            subtitle: widget.employee.nombre,
            showBackButton: true,
            showMenu: false,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DesignSystem.primaryColor,
                    ),
                  )
                : _error != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignSystem.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          'Días Laborales',
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: DesignSystem.spacingM),
                        ..._daysOfWeek.map((day) => _buildDaySchedule(day)),

                        const SizedBox(height: 80), // Padding for bottom bar
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DesignSystem.primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Error desconocido'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final daySchedules = _schedules[day];
    if (daySchedules == null) return const SizedBox.shrink();

    final hasSchedules = daySchedules.isNotEmpty;
    final hasActiveSchedules = daySchedules.any((s) => s['enabled'] == true);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        boxShadow: const [],
        border: hasActiveSchedules
            ? Border.all(
                color: DesignSystem.primaryColor.withValues(alpha: 0.3),
                width: 1,
              )
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSystem.spacingM,
              vertical: DesignSystem.spacingS,
            ),
            decoration: BoxDecoration(
              color: hasActiveSchedules
                  ? DesignSystem.primaryColor.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignSystem.radiusL),
                topRight: Radius.circular(DesignSystem.radiusL),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: hasActiveSchedules
                          ? DesignSystem.primaryColor
                          : DesignSystem.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasActiveSchedules
                            ? DesignSystem.primaryColor
                            : DesignSystem.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: DesignSystem.textSecondary,
                  ),
                  tooltip: 'Agregar turno extra',
                  onPressed: () {
                    setState(() {
                      _schedules[day]!.add({
                        'enabled': true,

                        'startTime': const TimeOfDay(hour: 9, minute: 0),
                        'endTime': const TimeOfDay(hour: 18, minute: 0),
                      });
                    });
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(DesignSystem.spacingM),
            child: Column(
              children: [
                if (!hasSchedules)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Día Libre (Sin horarios configurados)',
                      style: TextStyle(
                        color: DesignSystem.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ...daySchedules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final schedule = entry.value;
                  return _buildScheduleRow(day, index, schedule);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    String day,
    int index,
    Map<String, dynamic> schedule,
  ) {
    final isEnabled = schedule['enabled'] as bool;
    final startTime = schedule['startTime'] as TimeOfDay;
    final endTime = schedule['endTime'] as TimeOfDay;

    bool isTimeValid(TimeOfDay start, TimeOfDay end) {
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      return startMinutes < endMinutes;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.backgroundColor,
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        border: Border.all(
          color: DesignSystem.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch(
                value: isEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: DesignSystem.successColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: DesignSystem.textTertiary.withValues(
                  alpha: 0.3,
                ),
                onChanged: (val) {
                  setState(() {
                    _schedules[day]![index]['enabled'] = val;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                isEnabled ? 'Turno Activo' : 'Turno Inactivo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                      ? DesignSystem.successColor
                      : DesignSystem.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: DesignSystem.errorColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _schedules[day]!.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  label: 'Hora Inicio',
                  time: startTime,
                  icon: Icons.wb_sunny_outlined,
                  onChanged: (newTime) {
                    if (!isTimeValid(newTime, endTime)) {
                      SnackBarHelper.showError(
                        context,
                        'La hora de inicio debe ser menor a la hora de fin',
                      );
                      return;
                    }
                    setState(() {
                      _schedules[day]![index]['startTime'] = newTime;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePicker(
                  label: 'Hora Fin',
                  time: endTime,
                  icon: Icons.nightlight_round_outlined,
                  onChanged: (newTime) {
                    if (!isTimeValid(startTime, newTime)) {
                      SnackBarHelper.showError(
                        context,
                        'La hora de fin debe ser mayor a la hora de inicio',
                      );
                      return;
                    }
                    setState(() {
                      _schedules[day]![index]['endTime'] = newTime;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required Function(TimeOfDay) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: DesignSystem.primaryColor,
                  onPrimary: Colors.white,
                  onSurface: DesignSystem.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (newTime != null) {
          onChanged(newTime);
        }
      },
      borderRadius: BorderRadius.circular(DesignSystem.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: DesignSystem.textTertiary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: DesignSystem.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DesignSystem.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAllSchedules,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Guardar Configuración',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
