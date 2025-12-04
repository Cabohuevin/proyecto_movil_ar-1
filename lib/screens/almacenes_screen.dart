import 'package:flutter/material.dart';
import '../models/almacen.dart';
import '../services/almacen_api_service.dart';
import 'estanterias_screen.dart';

/// Screen for managing almacenes (warehouses)
class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final AlmacenApiService _almacenApiService = AlmacenApiService();
  List<Almacen> _almacenes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAlmacenes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlmacenes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final almacenes = await _almacenApiService.getAllAlmacenes();
      setState(() {
        _almacenes = almacenes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar almacenes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Almacen> get _filteredAlmacenes {
    if (_searchQuery.isEmpty) return _almacenes;
    final query = _searchQuery.toLowerCase();
    return _almacenes.where((almacen) {
      return almacen.nombre?.toLowerCase().contains(query) == true ||
          almacen.codigo?.toLowerCase().contains(query) == true;
    }).toList();
  }

  int get _totalAlmacenes => _almacenes.length;
  int get _almacenesActivos => _almacenes.where((a) => a.activo == true).length;
  int get _tiposAlmacen {
    // Count unique types - for now, we'll use a placeholder
    // You might need to add a tipo field to the Almacen model
    return 1;
  }

  void _showAlmacenMenu(BuildContext context, Almacen almacen) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Almacén'),
              onTap: () {
                Navigator.pop(context);
                _showEditAlmacenDialog(almacen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar Almacén', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(almacen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Ver estanterías'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEstanterias(almacen);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEstanterias(Almacen almacen) {
    // Get the correct idAlmacenErp - prefer idAlmacenErp, fallback to idAlmacen
    final idAlmacenErp = almacen.idAlmacenErp ?? almacen.idAlmacen;
    
    if (idAlmacenErp == null || idAlmacenErp < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El almacén seleccionado no tiene un ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('🔍 [AlmacenesScreen] Navigating to EstanteriasScreen');
    print('   Almacén: ${almacen.nombre}');
    print('   idAlmacen: ${almacen.idAlmacen}');
    print('   idAlmacenErp: ${almacen.idAlmacenErp}');
    print('   Sending idAlmacenErp: $idAlmacenErp');
    print('   Sending nombreAlmacen: ${almacen.nombre}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EstanteriasScreen(
          idAlmacenErp: idAlmacenErp,
          nombreAlmacen: almacen.nombre,
        ),
      ),
    );
  }

  void _showAddAlmacenDialog() {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final direccionController = TextEditingController();
    final telefonoController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Nuevo Almacén'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El código es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _almacenApiService.createAlmacen(
                    codigo: codigoController.text,
                    nombre: nombreController.text,
                    descripcion: descripcionController.text.isEmpty 
                        ? null 
                        : descripcionController.text,
                    direccion: direccionController.text.isEmpty 
                        ? null 
                        : direccionController.text,
                    telefono: telefonoController.text.isEmpty 
                        ? null 
                        : telefonoController.text,
                    email: emailController.text.isEmpty 
                        ? null 
                        : emailController.text,
                    activo: true,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadAlmacenes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Almacén creado exitosamente')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear almacén: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditAlmacenDialog(Almacen almacen) {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController(text: almacen.codigo ?? '');
    final nombreController = TextEditingController(text: almacen.nombre ?? '');
    final descripcionController = TextEditingController(text: almacen.descripcion ?? '');
    final direccionController = TextEditingController(text: almacen.direccion ?? '');
    final telefonoController = TextEditingController(text: almacen.telefono ?? '');
    final emailController = TextEditingController(text: almacen.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Almacén'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final id = almacen.idAlmacen ?? almacen.idAlmacenErp;
                  if (id != null) {
                    await _almacenApiService.updateAlmacen(
                      id: id,
                      codigo: codigoController.text.isEmpty 
                          ? null 
                          : codigoController.text,
                      nombre: nombreController.text.isEmpty 
                          ? null 
                          : nombreController.text,
                      descripcion: descripcionController.text.isEmpty 
                          ? null 
                          : descripcionController.text,
                      direccion: direccionController.text.isEmpty 
                          ? null 
                          : direccionController.text,
                      telefono: telefonoController.text.isEmpty 
                          ? null 
                          : telefonoController.text,
                      email: emailController.text.isEmpty 
                          ? null 
                          : emailController.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadAlmacenes();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Almacén actualizado exitosamente')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar almacén: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Almacen almacen) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Almacén'),
        content: Text('¿Estás seguro de que deseas eliminar el almacén "${almacen.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final id = almacen.idAlmacen ?? almacen.idAlmacenErp;
                if (id != null) {
                  await _almacenApiService.deleteAlmacen(id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadAlmacenes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Almacén eliminado exitosamente')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar almacén: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Almacenes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlmacenes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAlmacenes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlmacenes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle
                        Text(
                          'Administra los almacenes registrados en cada sucursal.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'Total de Almacenes',
                                value: _totalAlmacenes.toString(),
                                icon: Icons.warehouse,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Almacenes Activos',
                                value: _almacenesActivos.toString(),
                                icon: Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Tipos de Almacén',
                                value: _tiposAlmacen.toString(),
                                icon: Icons.category,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Header with Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historial de Almacenes',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Un registro detallado de todos los almacenes registrados.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddAlmacenDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir Nuevo Almacén'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, código...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Almacenes Table
                        _AlmacenesTable(
                          almacenes: _filteredAlmacenes,
                          onMenuTap: _showAlmacenMenu,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlmacenesTable extends StatelessWidget {
  final List<Almacen> almacenes;
  final Function(BuildContext, Almacen) onMenuTap;

  const _AlmacenesTable({
    required this.almacenes,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    if (almacenes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No hay almacenes disponibles',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SUCURSAL', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('TIPO', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: almacenes.map((almacen) {
            return DataRow(
              cells: [
                DataCell(Text('${almacen.idAlmacen ?? almacen.idAlmacenErp ?? almacen.id ?? '-'}')),
                DataCell(Text(almacen.nombre ?? '-')),
                DataCell(Text(almacen.codigo ?? '-')),
                DataCell(Text('Mérida Centro')), // Placeholder - you might need to fetch sucursal name
                DataCell(Text('GENERAL')), // Placeholder - you might need to add tipo to model
                DataCell(
                  Chip(
                    label: Text(
                      almacen.activo == true ? 'Activo' : 'Inactivo',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: almacen.activo == true ? Colors.green : Colors.grey,
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => onMenuTap(context, almacen),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

