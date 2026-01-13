import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design/design_system.dart';
import '../widgets/three_dots_menu_widget.dart';
import '../widgets/app_header.dart';
import '../services/membresia_service.dart';
import '../models/membresia_model.dart';
import '../widgets/admin_drawer.dart';
import '../controllers/auth_controller.dart';

class MembershipManagementScreen extends StatefulWidget {
  const MembershipManagementScreen({super.key});

  @override
  State<MembershipManagementScreen> createState() =>
      _MembershipManagementScreenState();
}

class _MembershipManagementScreenState
    extends State<MembershipManagementScreen> {
  final MembresiaService _membresiaService = MembresiaService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<MembresiaModel> _membresias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembresias();
  }

  Future<void> _loadMembresias() async {
    setState(() => _isLoading = true);

    try {
      final response = await _membresiaService.getAllMembresias();

      if (response.isSuccess && response.data != null) {
        setState(() {
          _membresias = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackBar(response.message, isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    int mesesSeleccionados = 1;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Membresía'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Membresía Premium',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Duración'),
                  initialValue: mesesSeleccionados,
                  items: List.generate(12, (index) => index + 1)
                      .map(
                        (mes) => DropdownMenuItem(
                          value: mes,
                          child: Text('$mes ${mes == 1 ? "mes" : "meses"}'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => mesesSeleccionados = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: precioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    hintText: 'Ej: 299.99',
                    prefixText: 'S/ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete todos los campos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final precio = double.tryParse(precioCtrl.text);
                if (precio == null || precio <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Precio inválido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);

                final response = await _membresiaService.createMembresia(
                  nombre: nombreCtrl.text,
                  meses: mesesSeleccionados,
                  precio: precio,
                );

                if (mounted) {
                  if (response.isSuccess) {
                    _showSnackBar('Membresía creada');
                    _loadMembresias();
                  } else {
                    _showSnackBar(response.message, isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(MembresiaModel membresia) async {
    final nombreCtrl = TextEditingController(text: membresia.nombre);
    final precioCtrl = TextEditingController(text: membresia.precio.toString());
    int mesesSeleccionados = membresia.meses;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Membresía'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Duración'),
                  initialValue: mesesSeleccionados,
                  items: List.generate(12, (index) => index + 1)
                      .map(
                        (mes) => DropdownMenuItem(
                          value: mes,
                          child: Text('$mes ${mes == 1 ? "mes" : "meses"}'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => mesesSeleccionados = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: precioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: 'S/ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final precio = double.tryParse(precioCtrl.text);
                if (precio == null || precio <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Precio inválido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final response = await _membresiaService.updateMembresia(
                  membresia.id,
                  nombre: nombreCtrl.text,
                  meses: mesesSeleccionados,
                  precio: precio,
                );

                if (mounted) {
                  if (response.isSuccess) {
                    _showSnackBar('Membresía actualizada');
                    _loadMembresias();
                  } else {
                    _showSnackBar(response.message, isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(MembresiaModel membresia) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${membresia.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _membresiaService.deleteMembresia(membresia.id);

      if (mounted) {
        if (response.isSuccess) {
          _showSnackBar('Membresía eliminada');
          _loadMembresias();
        } else {
          _showSnackBar(response.message, isError: true);
        }
      }
    }
  }

  Future<void> _toggleActiva(MembresiaModel membresia) async {
    final response = await _membresiaService.toggleActiva(
      membresia.id,
      !membresia.activa,
    );

    if (mounted) {
      if (response.isSuccess) {
        _showSnackBar(
          membresia.activa ? 'Membresía desactivada' : 'Membresía activada',
        );
        _loadMembresias();
      } else {
        _showSnackBar(response.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthController>(context);

    // FIX: PopScope to prevent black screen/app exit
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      child: Scaffold(
        key: _scaffoldKey, // Add key for drawer access
        backgroundColor: DesignSystem.backgroundColor,
        drawer: AdminDrawer(
          user: authProvider.currentUser,
          authController: authProvider,
        ),
        body: Column(
          children: [
            // Custom Header
            AppHeader(
              title: 'Gestión de Membresías',
              subtitle: '${_membresias.length} planes disponibles',
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              menuItems: [
                ThreeDotsMenuItem(
                  icon: Icons.refresh,
                  title: 'Actualizar',
                  onTap: _loadMembresias,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _membresias.isEmpty
                  ? _buildEmptyState()
                  : _buildMembershipList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: DesignSystem.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership,
            size: 64,
            color: DesignSystem.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No hay membresías',
            style: TextStyle(fontSize: 18, color: DesignSystem.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Crea una nueva membresía con el botón +',
            style: TextStyle(color: DesignSystem.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _membresias.length,
      itemBuilder: (context, index) {
        final membresia = _membresias[index];
        return _buildMembershipCard(membresia);
      },
    );
  }

  Widget _buildMembershipCard(MembresiaModel membresia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: membresia.activa
              ? DesignSystem.primaryColor.withValues(alpha: 0.1)
              : DesignSystem.textTertiary.withValues(alpha: 0.1),
          child: Icon(
            Icons.card_membership,
            color: membresia.activa
                ? DesignSystem.primaryColor
                : DesignSystem.textTertiary,
          ),
        ),
        title: Text(
          membresia.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Duración: ${membresia.duracionTexto}'),
            Text('Precio: ${membresia.precioFormateado}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: membresia.activa
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                membresia.activa ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  fontSize: 12,
                  color: membresia.activa ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ThreeDotsMenuWidget(
              items: [
                ThreeDotsMenuItem(
                  icon: Icons.edit,
                  title: 'Editar',
                  onTap: () => _showEditDialog(membresia),
                ),
                ThreeDotsMenuItem(
                  icon: membresia.activa ? Icons.toggle_on : Icons.toggle_off,
                  title: membresia.activa ? 'Desactivar' : 'Activar',
                  onTap: () => _toggleActiva(membresia),
                ),
                ThreeDotsMenuItem(
                  icon: Icons.delete,
                  title: 'Eliminar',
                  onTap: () => _confirmDelete(membresia),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
