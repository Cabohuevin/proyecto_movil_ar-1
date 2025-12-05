import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/estanteria.dart';
import '../services/inventario_api_service.dart';
import 'ar_location_shelf_screen.dart';

class EstanteriasScreen extends StatefulWidget {
  final int idAlmacenErp;
  final String? nombreAlmacen;
  
  const EstanteriasScreen({
    super.key, 
    required this.idAlmacenErp,
    this.nombreAlmacen,
  });

  @override
  State<EstanteriasScreen> createState() => _EstanteriasScreenState();
}

class _EstanteriasScreenState extends State<EstanteriasScreen> {
  final InventarioApiService _inventarioApiService = InventarioApiService();
  List<Estanteria> _estanterias = [];
  List<Map<String, dynamic>> _zonas = []; // Zonas del almacén para mantener orden
  Map<int, List<Map<String, dynamic>>> _productosPorEstanteria = {}; // idUbicacion -> productos
  Estanteria? _selectedEstanteria;
  String? _selectedZona;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEstanterias();
  }

  Future<void> _loadEstanterias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate idAlmacenErp matches the almacén we're accessing
      if (widget.idAlmacenErp < 1) {
        throw Exception('idAlmacenErp inválido: ${widget.idAlmacenErp}');
      }
      
      print('🔍 [EstanteriasScreen] Loading layout completo for almacén');
      print('   idAlmacenErp: ${widget.idAlmacenErp}');
      print('   nombreAlmacen: ${widget.nombreAlmacen ?? "N/A"}');
      
      // Use layout-completo endpoint which returns zonas and estanterías in order
      // POST /api/inventario/layout-completo/:idAlmacenErp
      final layoutResponse = await _inventarioApiService.getLayoutCompleto(
        widget.idAlmacenErp,
      );
      
      // Parse response structure: { success, message, data: { zonas: [], id_almacen_erp } }
      final data = layoutResponse['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('No se recibió data en la respuesta del layout');
      }
      
      // Extract zonas from layout (already ordered)
      final zonasList = data['zonas'] as List<dynamic>? ?? [];
      final zonas = zonasList
          .whereType<Map<String, dynamic>>()
          .toList();
      
      // Extract estanterías (ubicaciones) from each zona and extract productos
      final List<Estanteria> estanterias = [];
      final Map<int, List<Map<String, dynamic>>> productosPorEstanteria = {};
      
      for (var zona in zonas) {
        final ubicaciones = zona['ubicaciones'] as List<dynamic>? ?? [];
        for (var ubicacion in ubicaciones) {
          if (ubicacion is Map<String, dynamic>) {
            // Convert ubicacion to Estanteria
            try {
              final idUbicacion = ubicacion['id_ubicacion'] is int
                  ? ubicacion['id_ubicacion'] as int
                  : int.tryParse(ubicacion['id_ubicacion']?.toString() ?? '');
              
              // Extract productos from celdas
              final celdas = ubicacion['celdas'] as List<dynamic>? ?? [];
              final List<Map<String, dynamic>> productos = [];
              
              for (var celda in celdas) {
                if (celda is Map<String, dynamic>) {
                  final productosAsignados = celda['productos_asignados'] as List<dynamic>? ?? [];
                  for (var producto in productosAsignados) {
                    if (producto is Map<String, dynamic>) {
                      // Add celda info to producto for context
                      productos.add({
                        ...producto,
                        'celda_codigo': celda['codigo'],
                        'celda_fila': celda['fila'],
                        'celda_columna': celda['columna'],
                        'celda_nivel': celda['nivel'],
                        'celda_id': celda['id_celda'],
                      });
                    }
                  }
                }
              }
              
              if (idUbicacion != null) {
                productosPorEstanteria[idUbicacion] = productos;
              }
              
              final estanteria = Estanteria.fromJson({
                ...ubicacion,
                'idZona': zona['id_zona'],
                'zona': zona['nombre'],
                'idAlmacenErp': widget.idAlmacenErp,
                // Map fields from layout format to Estanteria format
                'idUbicacion': idUbicacion,
                'codigo': ubicacion['codigo'],
                'nombre': ubicacion['nombre'],
                'numeroFilas': ubicacion['filas'],
                'numeroColumnas': ubicacion['columnas'],
                'numeroNiveles': ubicacion['niveles'],
                'posicionX': ubicacion['pos_x'],
                'posicionY': ubicacion['pos_y'],
                'idTipoUbicacion': ubicacion['id_tipo_ubicacion'],
                'idPlantilla': ubicacion['id_plantilla'],
                'celdas': ubicacion['celdas'],
              });
              
              // Log coordinates for debugging
              if (estanteria.hasLocation) {
                print('📍 [EstanteriasScreen] Estantería con coordenadas:');
                print('   Código: ${estanteria.codigo}');
                print('   idUbicacion: ${estanteria.idUbicacion}');
                final rawPosX = ubicacion['pos_x'];
                final rawPosY = ubicacion['pos_y'];
                print('   pos_x (raw from API): $rawPosX (${rawPosX?.toString() ?? "null"})');
                print('   pos_y (raw from API): $rawPosY (${rawPosY?.toString() ?? "null"})');
                print('   posicionX (parsed): ${estanteria.posicionX} (${estanteria.posicionX?.toStringAsFixed(10) ?? "null"})');
                print('   posicionY (parsed): ${estanteria.posicionY} (${estanteria.posicionY?.toStringAsFixed(10) ?? "null"})');
                print('   lat (from model): ${estanteria.lat} (${estanteria.lat?.toStringAsFixed(10) ?? "null"})');
                print('   lng (from model): ${estanteria.lng} (${estanteria.lng?.toStringAsFixed(10) ?? "null"})');
                print('   latitude (getter): ${estanteria.latitude} (${estanteria.latitude?.toStringAsFixed(10) ?? "null"})');
                print('   longitude (getter): ${estanteria.longitude} (${estanteria.longitude?.toStringAsFixed(10) ?? "null"})');
                print('   hasLocation: ${estanteria.hasLocation}');
              }
              
              estanterias.add(estanteria);
            } catch (e) {
              print('⚠️ Error parsing ubicación: $e');
              print('   Ubicación data: $ubicacion');
            }
          }
        }
      }
      
      print('✅ [EstanteriasScreen] Loaded ${zonas.length} zonas and ${estanterias.length} estanterías');
      
      setState(() {
        _zonas = zonas;
        _estanterias = estanterias;
        _productosPorEstanteria = productosPorEstanteria;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      // Handle unauthorized/forbidden errors
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('401') ||
          e.toString().contains('Forbidden') ||
          e.toString().contains('403')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No tienes permisos para ver estanterías.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Map<String, List<Estanteria>> get _estanteriasPorZona {
    final Map<String, List<Estanteria>> grouped = {};
    
    // First, create entries for all zonas from the almacén (to maintain order)
    for (var zona in _zonas) {
      final zonaId = zona['idZona']?.toString() ?? 
                     zona['id_zona']?.toString() ?? 
                     zona['id']?.toString();
      final zonaNombre = zona['nombre']?.toString() ?? 
                        zona['name']?.toString() ?? 
                        zonaId ?? 'Sin nombre';
      
      // Use zona nombre as key, or idZona if nombre is not available
      final zonaKey = zonaNombre.isNotEmpty ? zonaNombre : (zonaId ?? 'Sin zona');
      grouped[zonaKey] = [];
    }
    
    // Then, assign estanterías to their zonas
    for (var estanteria in _estanterias) {
      // Try to match by idZona first
      String? zonaKey;
      
      if (estanteria.idZona != null) {
        // Find zona by idZona
        for (var zona in _zonas) {
          final zonaId = zona['idZona'] is int 
              ? zona['idZona'] as int
              : (zona['id_zona'] is int
                  ? zona['id_zona'] as int
                  : (zona['id'] is int 
                      ? zona['id'] as int
                      : int.tryParse(zona['idZona']?.toString() ?? 
                                   zona['id_zona']?.toString() ?? 
                                   zona['id']?.toString() ?? '')));
          
          if (zonaId != null && zonaId == estanteria.idZona) {
            zonaKey = zona['nombre']?.toString() ?? 
                     zona['name']?.toString() ?? 
                     zonaId.toString();
            break;
          }
        }
      }
      
      // If not found by idZona, use zona name or idZona as fallback
      if (zonaKey == null) {
        zonaKey = estanteria.zona ?? 
                 estanteria.idZona?.toString() ?? 
                 'Sin zona';
      }
      
      // Add to grouped map, create entry if it doesn't exist
      grouped.putIfAbsent(zonaKey, () => []).add(estanteria);
    }
    
    return grouped;
  }
  
  /// Get zonas list ordered as they come from the almacén API
  List<String> get _zonasOrdenadas {
    final zonasMap = _estanteriasPorZona;
    final List<String> zonasOrdenadas = [];
    
    // First add zonas from _zonas in order (almacenes -> zonas -> estanterias)
    for (var zona in _zonas) {
      final zonaId = zona['idZona']?.toString() ?? 
                     zona['id_zona']?.toString() ?? 
                     zona['id']?.toString();
      final zonaNombre = zona['nombre']?.toString() ?? 
                        zona['name']?.toString() ?? 
                        zonaId ?? 'Sin nombre';
      
      final zonaKey = zonaNombre.isNotEmpty ? zonaNombre : (zonaId ?? 'Sin zona');
      if (zonasMap.containsKey(zonaKey) && !zonasOrdenadas.contains(zonaKey)) {
        zonasOrdenadas.add(zonaKey);
      }
    }
    
    // Then add any remaining zonas that might not be in _zonas (e.g., "Sin zona")
    for (var zonaKey in zonasMap.keys) {
      if (!zonasOrdenadas.contains(zonaKey)) {
        zonasOrdenadas.add(zonaKey);
      }
    }
    
    return zonasOrdenadas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreAlmacen != null
              ? 'Estanterías - ${widget.nombreAlmacen}'
              : 'Estanterías de Almacén #${widget.idAlmacenErp}',
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEstanterias,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildThreePanelLayout(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estanterías',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEstanterias,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreePanelLayout() {
    return Column(
      children: [
        // Top: Zonas horizontal scroll
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Zonas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _buildZonasHorizontalList(),
              ),
            ],
          ),
        ),
        // Bottom: Estanterías de la zona seleccionada
        Expanded(
          child: _buildEstanteriasPanel(),
        ),
      ],
    );
  }

  Widget _buildZonasHorizontalList() {
    final zonasMap = _estanteriasPorZona;
    // Use ordered zonas list to maintain almacenes -> zonas -> estanterias order
    final zonasList = _zonasOrdenadas.isNotEmpty ? _zonasOrdenadas : zonasMap.keys.toList();

    if (zonasList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay zonas disponibles'),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: zonasList.length,
      itemBuilder: (context, index) {
        final zona = zonasList[index];
        final estanterias = zonasMap[zona] ?? [];
        final isSelected = _selectedZona == zona;
        
        return Container(
          margin: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedZona = zona;
                _selectedEstanteria = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : _getZonaColor(zona),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zona,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (estanterias.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${estanterias.length} estante${estanterias.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobiliarioList() {
    // Placeholder for plantillas/templates
    // You might need to fetch these from an API endpoint
    final plantillas = [
      {'nombre': 'Estante 5 Niveles Estándar', 'descripcion': 'Estante de 5 niveles con 4 columnas', 'icon': Icons.inventory_2},
      {'nombre': 'NEVERA/REFRIGERADOR Nevera Vertical 3 Repisas', 'descripcion': 'Nevera vertical con 3 repisas', 'icon': Icons.ac_unit},
      {'nombre': 'ÁREA DE PISO PISO_TARIMA_ESTANDAR', 'descripcion': 'Espacio de 1.2m x 1.0m para una tarima', 'icon': Icons.square},
    ];

    return ListView.builder(
      itemCount: plantillas.length,
      itemBuilder: (context, index) {
        final plantilla = plantillas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(plantilla['icon'] as IconData),
            title: Text(
              plantilla['nombre'] as String,
              style: const TextStyle(fontSize: 12),
            ),
            subtitle: Text(
              plantilla['descripcion'] as String,
              style: const TextStyle(fontSize: 10),
            ),
            dense: true,
          ),
        );
      },
    );
  }

  /// Get estanterías filtered by selected zona
  List<Estanteria> get _estanteriasFiltradas {
    if (_selectedZona == null) {
      return [];
    }
    final zonasMap = _estanteriasPorZona;
    return zonasMap[_selectedZona] ?? [];
  }

  Widget _buildEstanteriasPanel() {
    final estanterias = _estanteriasFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedZona != null
                        ? 'Estanterías - $_selectedZona'
                        : 'Selecciona una zona',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_selectedZona != null)
                    Text(
                      '${estanterias.length} estante${estanterias.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Estanterías list
        Expanded(
          child: _selectedZona == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Selecciona una zona',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Haz clic en una zona del panel izquierdo para ver sus estanterías',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : estanterias.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No hay estanterías en esta zona',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grid de estanterías
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85, // Más altura para evitar overflow
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: estanterias.length,
                            itemBuilder: (context, index) {
                              return _buildEstanteriaCard(estanterias[index]);
                            },
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildZonaSection(String zona, List<Estanteria> estanterias) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getZonaColor(zona),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                zona,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${estanterias.length} estante${estanterias.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (estanterias.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Esta zona no tiene estanterías asignadas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: estanterias.map((estanteria) => _buildEstanteriaCard(estanteria)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEstanteriaCard(Estanteria estanteria) {
    final hasLocation = estanteria.hasLocation;
    
    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasLocation ? Colors.green.shade300 : Colors.orange.shade300,
          width: hasLocation ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicator and location indicator
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: estanteria.activo == true ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estanteria.codigo ?? estanteria.idUbicacion?.toString() ?? 'N/A',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Location indicator
                if (hasLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.green.shade700),
                        const SizedBox(width: 2),
                        Text(
                          'GPS',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.location_off, size: 18, color: Colors.orange.shade700),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _saveCoordinates(estanteria);
                    },
                    tooltip: 'Guardar ubicación GPS',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Nombre
            if (estanteria.nombre != null) ...[
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      estanteria.nombre!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            
            // Botón de productos siempre visible
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                      onPressed: () {
                        _showProductosEstanteria(estanteria);
                      },
                      icon: const Icon(Icons.inventory_2, size: 16),
                      label: const Text('Ver productos', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            
            // Botón desplegable para ubicación GPS o botón para guardar
              SizedBox(
                width: double.infinity,
              child: hasLocation
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'visualizar') {
                          _navigateToAR(estanteria);
                        } else if (value == 'cambiar') {
                          _saveCoordinates(estanteria);
                        }
                      },
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'visualizar',
                          child: Row(
                            children: [
                              Icon(Icons.navigation, size: 20, color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              const Text('Visualizar estantería'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'cambiar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_location_alt, size: 20, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              const Text('Cambiar de ubicación'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Ubicación GPS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 20, color: Colors.green.shade700),
                          ],
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                  onPressed: () {
                    _saveCoordinates(estanteria);
                  },
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Guardar ubicación GPS', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            
            // Dimensiones - más compacto
            if (estanteria.numeroFilas != null || estanteria.numeroColumnas != null || estanteria.numeroNiveles != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (estanteria.numeroFilas != null)
                      _buildInfoItem(Icons.view_agenda, 'F', estanteria.numeroFilas.toString()),
                    if (estanteria.numeroColumnas != null)
                      _buildInfoItem(Icons.view_column, 'C', estanteria.numeroColumnas.toString()),
                    if (estanteria.numeroNiveles != null)
                      _buildInfoItem(Icons.layers, 'N', estanteria.numeroNiveles.toString()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontSize: 16,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  void _showProductosEstanteria(Estanteria estanteria) {
    if (estanteria.idUbicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta estantería no tiene ID válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final productos = _productosPorEstanteria[estanteria.idUbicacion] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estanteria.nombre ?? estanteria.codigo ?? 'Estantería',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (estanteria.codigo != null)
                          Text(
                            'Código: ${estanteria.codigo}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Productos list
            Expanded(
              child: productos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos en esta estantería',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        final producto = productos[index];
                        return _buildProductoCard(producto);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final nombre = producto['producto_nombre']?.toString() ?? 'Sin nombre';
    final codigo = producto['producto_codigo']?.toString() ?? 'N/A';
    final descripcion = producto['producto_descripcion']?.toString();
    final codigoBarras = producto['producto_codigo_barras']?.toString();
    final max = producto['max'];
    final min = producto['min'];
    final optimo = producto['optimo'];
    final primaria = producto['primaria'] == true;
    final celdaCodigo = producto['celda_codigo']?.toString();
    final celdaFila = producto['celda_fila'];
    final celdaColumna = producto['celda_columna'];
    final celdaNivel = producto['celda_nivel'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (primaria)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PRIMARIA',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (primaria) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Código y código de barras
            Row(
              children: [
                if (codigo != 'N/A')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      codigo,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (codigoBarras != null && codigoBarras.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Barras: $codigoBarras',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // Descripción
            if (descripcion != null && descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                descripcion,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Información de celda
            if (celdaCodigo != null) ...[
              Row(
                children: [
                  Icon(Icons.grid_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Celda: $celdaCodigo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  if (celdaFila != null || celdaColumna != null || celdaNivel != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      'F${celdaFila ?? "?"} C${celdaColumna ?? "?"} N${celdaNivel ?? "?"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Configuración de inventario
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (min != null)
                  _buildConfigChip('Mín', min.toString(), Colors.orange),
                if (max != null)
                  _buildConfigChip('Máx', max.toString(), Colors.red),
                if (optimo != null)
                  _buildConfigChip('Óptimo', optimo.toString(), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigChip(String label, String value, Color color) {
    // Get a darker shade of the color
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: darkerColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: darkerColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInspectorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: const Text(
            'Inspector',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _selectedEstanteria == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Sin selección',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Haz clic en una Zona, Estantería o Celda del mapa para ver sus propiedades y gestionar su contenido.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildEstanteriaDetails(_selectedEstanteria!),
                ),
        ),
      ],
    );
  }

  Widget _buildEstanteriaDetails(Estanteria estanteria) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          estanteria.nombre ?? 'Sin nombre',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('ID', estanteria.idUbicacion?.toString() ?? 'N/A'),
        _buildDetailRow('Código', estanteria.codigo ?? 'N/A'),
        _buildDetailRow('Zona', estanteria.zona ?? 'N/A'),
        _buildDetailRow('Estado', estanteria.activo == true ? 'Activa' : 'Inactiva'),
        if (estanteria.descripcion != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow('Descripción', estanteria.descripcion!),
        ],
        if (estanteria.hasLocation) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Ubicación',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Latitud', estanteria.lat!.toStringAsFixed(6)),
          _buildDetailRow('Longitud', estanteria.lng!.toStringAsFixed(6)),
        ],
        if (estanteria.numeroFilas != null || estanteria.numeroColumnas != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Dimensiones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (estanteria.numeroFilas != null)
            _buildDetailRow('Filas', estanteria.numeroFilas.toString()),
          if (estanteria.numeroColumnas != null)
            _buildDetailRow('Columnas', estanteria.numeroColumnas.toString()),
          if (estanteria.numeroNiveles != null)
            _buildDetailRow('Niveles', estanteria.numeroNiveles.toString()),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getZonaColor(String zona) {
    // Simple color assignment based on zona name
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];
    final index = zona.hashCode % colors.length;
    return colors[index.abs()];
  }

  Future<void> _saveCoordinates(Estanteria estanteria) async {
    // Check if estanteria has idUbicacion
    if (estanteria.idUbicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta estantería no tiene ID de ubicación válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Request location permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor activa el servicio de ubicación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de ubicación para guardar coordenadas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El permiso de ubicación está denegado permanentemente. Actívalo en configuración'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Obteniendo ubicación...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Guardar Coordenadas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estantería: ${estanteria.nombre ?? "Sin nombre"}'),
              const SizedBox(height: 8),
              Text('Latitud: ${position.latitude.toStringAsFixed(6)}'),
              Text('Longitud: ${position.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
              const Text('¿Deseas guardar estas coordenadas?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show saving dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando coordenadas...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Update coordinates via API
      // API stores coordinates in posicionX (lat) and posicionY (lng)
      // Use full precision coordinates (no rounding)
      final lat = position.latitude;
      final lng = position.longitude;
      
      print('📍 [EstanteriasScreen] Saving coordinates:');
      print('   Current position (full precision):');
      print('      lat: $lat (${lat.toStringAsFixed(10)})');
      print('      lng: $lng (${lng.toStringAsFixed(10)})');
      print('   Estantería: ${estanteria.codigo ?? estanteria.nombre}');
      print('   idUbicacion: ${estanteria.idUbicacion}');
      
      await _inventarioApiService.updateUbicacionFisicaCoordenadas(
        idUbicacion: estanteria.idUbicacion!,
        lat: lat,
        lng: lng,
        codigo: estanteria.codigo,
        idTipoUbicacion: estanteria.idTipoUbicacion,
        idZona: estanteria.idZona,
        nombre: estanteria.nombre,
        // Don't pass posicionX/posicionY - they will be set from lat/lng in the service
        idPlantilla: estanteria.idPlantilla,
        activo: estanteria.activo,
        capacidadMaxima: estanteria.capacidadMaxima,
        capacidadPorCelda: estanteria.capacidadPorCelda,
        descripcion: estanteria.descripcion,
        numeroFilas: estanteria.numeroFilas,
        numeroColumnas: estanteria.numeroColumnas,
        numeroNiveles: estanteria.numeroNiveles,
      );
      
      print('✅ [EstanteriasScreen] Coordinates saved successfully');

      // Close saving dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Coordenadas guardadas exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Reload estanterías to update location indicators
      if (mounted) {
        _loadEstanterias();
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar coordenadas: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateToAR(Estanteria estanteria) {
    if (!estanteria.hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta estantería no tiene coordenadas guardadas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get coordinates from lat/lng or posicionX/posicionY
    final lat = estanteria.latitude ?? estanteria.posicionX;
    final lng = estanteria.longitude ?? estanteria.posicionY;
    
    print('🧭 [EstanteriasScreen] Navigating to AR:');
    print('   Estantería: ${estanteria.codigo ?? estanteria.nombre}');
    print('   idUbicacion: ${estanteria.idUbicacion}');
    print('   lat field: ${estanteria.lat} (${estanteria.lat?.toStringAsFixed(10) ?? "null"})');
    print('   lng field: ${estanteria.lng} (${estanteria.lng?.toStringAsFixed(10) ?? "null"})');
    print('   posicionX: ${estanteria.posicionX} (${estanteria.posicionX != null ? estanteria.posicionX!.toStringAsFixed(10) : "null"})');
    print('   posicionY: ${estanteria.posicionY} (${estanteria.posicionY != null ? estanteria.posicionY!.toStringAsFixed(10) : "null"})');
    print('   Using coordinates (full precision):');
    print('      lat: $lat (${lat != null ? lat.toStringAsFixed(10) : "null"})');
    print('      lng: $lng (${lng != null ? lng.toStringAsFixed(10) : "null"})');
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron obtener las coordenadas de la estantería'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Preparar los datos de la estantería para la pantalla AR
    final shelfData = {
      'name': estanteria.nombre ?? estanteria.codigo ?? 'Estantería ${estanteria.idUbicacion}',
      'lat': lat,
      'lng': lng,
    };
    
    print('   📍 Shelf data for AR: $shelfData');

    // Navegar a la pantalla AR con la estantería seleccionada
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARLocationShelfScreen(
          initialShelf: shelfData,
        ),
      ),
    );
  }

  void _viewLocation(Estanteria estanteria) {
    if (!estanteria.hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta estantería no tiene coordenadas guardadas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estanteria.nombre ?? 'Ubicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estanteria.codigo != null)
              Text('Código: ${estanteria.codigo}'),
            const SizedBox(height: 12),
            const Text(
              'Coordenadas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Latitud: ${estanteria.lat!.toStringAsFixed(6)}'),
            Text('Longitud: ${estanteria.lng!.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Show coordinates
                final lat = estanteria.lat!;
                final lng = estanteria.lng!;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coordenadas: $lat, $lng'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Abrir en Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}


