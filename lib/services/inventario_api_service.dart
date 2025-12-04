import '../models/estanteria.dart';
import 'api_service.dart';
import 'almacen_api_service.dart';

/// Inventario API Service - Handles inventory-related endpoints (estanterías, zonas, etc.)
class InventarioApiService {
  final ApiService _apiService;
  final AlmacenApiService _almacenApiService;

  InventarioApiService({
    ApiService? apiService,
    AlmacenApiService? almacenApiService,
  })  : _apiService = apiService ?? ApiService(),
        _almacenApiService = almacenApiService ?? AlmacenApiService();

  /// Get all estanterías from ubicacion-fisica endpoint
  /// POST /api/inventario/ubicacion-fisica
  /// Requires idAlmacenErp to get zonas first, then search estanterías for each zona
  /// Returns all estanterías from all zonas of the almacén
  Future<List<Estanteria>> getAllEstanterias({
    required int idAlmacenErp,
    String? nombreAlmacen,
  }) async {
    try {
      print('🔍 [InventarioApiService] Getting all estanterías from ubicacion-fisica...');
      print('   Endpoint: /inventario/ubicacion-fisica');
      print('   Method: POST');
      print('   Purpose: Get all estanterías for almacén $idAlmacenErp');
      if (nombreAlmacen != null) {
        print('   Almacén: $nombreAlmacen');
      }
      
      // Validate idAlmacenErp
      if (idAlmacenErp < 1) {
        throw Exception('idAlmacenErp debe ser mayor a 0');
      }
      
      print('   ✅ Using idAlmacenErp: $idAlmacenErp');
      if (nombreAlmacen != null) {
        print('   ✅ Using nombreAlmacen: $nombreAlmacen');
      }
      
      // Step 1: Get all zonas for this almacén
      print('   📋 Step 1: Obtaining zonas for almacén $idAlmacenErp${nombreAlmacen != null ? " ($nombreAlmacen)" : ""}...');
      List<Map<String, dynamic>> zonas;
      try {
        zonas = await getZonas(
          idAlmacenErp: idAlmacenErp,
          nombre: nombreAlmacen ?? '', // Use almacén name if available, otherwise empty string
          nombreAlmacen: nombreAlmacen, // Pass almacén name for reference
        );
        print('   ✅ Found ${zonas.length} zonas for almacén $idAlmacenErp');
        if (zonas.isEmpty) {
          print('   ⚠️ No zonas found for this almacén, returning empty list');
          return [];
        }
      } catch (e) {
        print('   ❌ Could not fetch zonas: $e');
        throw Exception('No se pudieron obtener las zonas del almacén: $e');
      }
      
      // Step 2: Extract idZona values from zonas
      List<int> idZonas = [];
      for (var zona in zonas) {
        int? idZona = zona['idZona'] is int 
            ? zona['idZona'] as int
            : (zona['id_zona'] is int
                ? zona['id_zona'] as int
                : (zona['id'] is int 
                    ? zona['id'] as int
                    : int.tryParse(zona['idZona']?.toString() ?? 
                                  zona['id_zona']?.toString() ?? 
                                  zona['id']?.toString() ?? '')));
        if (idZona != null && idZona >= 1) {
          idZonas.add(idZona);
        }
      }
      
      if (idZonas.isEmpty) {
        print('   ⚠️ No valid idZona values found in zonas, returning empty list');
        return [];
      }
      
      print('   ✅ Extracted ${idZonas.length} valid idZona values: $idZonas');
      
      // Step 3: Get estanterías for each zona
      print('   📋 Step 2: Searching estanterías for each zona...');
      List<Estanteria> allEstanterias = [];
      
      // Try to get sample estantería to extract valid idTipoUbicacion and idPlantilla
      int? validIdTipoUbicacion;
      int? validIdPlantilla;
      
      // Try with first zona to get sample values
      for (int idZona in idZonas) {
        try {
          final sampleBody = {
            'idUbicacion': 0,
            'idZona': idZona,
            'idTipoUbicacion': 1,
            'idPlantilla': 1,
            'codigo': '',
            'nombre': '',
            'posicionX': 0,
            'posicionY': 0,
            'numeroFilas': 1,
            'numeroColumnas': 1,
            'numeroNiveles': 1,
          };
          
          final sampleResponse = await _apiService.post(
            '/inventario/ubicacion-fisica',
            body: sampleBody,
          );
          
          final sampleEstanterias = _parseEstanteriasFromResponse(sampleResponse);
          if (sampleEstanterias.isNotEmpty) {
            final firstEstanteria = sampleEstanterias.first;
            validIdTipoUbicacion = firstEstanteria.idTipoUbicacion ?? 1;
            validIdPlantilla = firstEstanteria.idPlantilla ?? 1;
            print('   ✅ Extracted valid values from zona $idZona:');
            print('      idTipoUbicacion: $validIdTipoUbicacion');
            print('      idPlantilla: $validIdPlantilla');
            // Add the estanterías found
            allEstanterias.addAll(sampleEstanterias);
            break; // We got sample values, continue with other zonas
          }
        } catch (e) {
          print('   ⚠️ Could not get sample estanterías from zona $idZona: $e');
          // Continue with next zona
        }
      }
      
      // If we didn't get sample values, use defaults
      if (validIdTipoUbicacion == null) {
        validIdTipoUbicacion = 1;
        validIdPlantilla = 1;
        print('   ⚠️ Using default values: idTipoUbicacion=1, idPlantilla=1');
      }
      
      // Step 4: Search estanterías for all zonas (if we haven't already)
      // We already got estanterías from the first zona, now get from remaining zonas
      for (int idZona in idZonas) {
        // Skip if we already processed this zona
        if (allEstanterias.any((e) => e.idZona == idZona)) {
          continue;
        }
        
        try {
          print('   🔍 Searching estanterías for zona $idZona...');
          final body = {
            'idUbicacion': 0, // 0 = get all (no ID filter)
            'idZona': idZona,
            'idTipoUbicacion': validIdTipoUbicacion,
            'idPlantilla': validIdPlantilla,
            'codigo': '', // Empty string for querying all
            'nombre': '', // Empty string for querying all
            'posicionX': 0,
            'posicionY': 0,
            'numeroFilas': 1,
            'numeroColumnas': 1,
            'numeroNiveles': 1,
            'capacidadMaxima': 0,
            'capacidadPorCelda': 0,
            'activo': true,
            'descripcion': '',
          };
          
          final response = await _apiService.post(
            '/inventario/ubicacion-fisica',
            body: body,
          );
          
          final estanterias = _parseEstanteriasFromResponse(response);
          print('   ✅ Found ${estanterias.length} estanterías in zona $idZona');
          allEstanterias.addAll(estanterias);
        } catch (e) {
          print('   ⚠️ Error getting estanterías for zona $idZona: $e');
          // Continue with next zona
        }
      }
      
      // Remove duplicates based on idUbicacion
      final uniqueEstanterias = <int, Estanteria>{};
      for (var estanteria in allEstanterias) {
        if (estanteria.idUbicacion != null) {
          uniqueEstanterias[estanteria.idUbicacion!] = estanteria;
        }
      }
      
      final finalEstanterias = uniqueEstanterias.values.toList();
      print('   ✅ Successfully retrieved ${finalEstanterias.length} unique estanterías from ${idZonas.length} zonas');
      return finalEstanterias;
    } catch (e) {
      print('❌ [InventarioApiService] Error fetching estanterías: $e');
      print('   Error type: ${e.runtimeType}');
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        print('   🔒 Authentication error detected - token may be missing or invalid');
      }
      if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        print('   🚫 Authorization error detected - token may not have required permissions');
      }
      rethrow;
    }
  }

  /// Parse estanterías from API response
  List<Estanteria> _parseEstanteriasFromResponse(Map<String, dynamic> response) {
    print('✅ [InventarioApiService] Response received');
    print('   Response keys: ${response.keys.toList()}');
    print('   Response type: ${response.runtimeType}');

    // Handle different response formats
    // ApiService always returns Map<String, dynamic>
    List<dynamic>? estanteriasList;
    
    // Try common response formats
    if (response['data'] != null) {
      if (response['data'] is List) {
        estanteriasList = response['data'] as List<dynamic>;
      } else if (response['data'] is Map) {
        // Single object wrapped in data
        estanteriasList = [response['data']];
      }
    } else if (response['results'] != null && response['results'] is List) {
      estanteriasList = response['results'] as List<dynamic>;
    } else if (response['estanterias'] != null && response['estanterias'] is List) {
      estanteriasList = response['estanterias'] as List<dynamic>;
    } else if (response['ubicaciones'] != null && response['ubicaciones'] is List) {
      estanteriasList = response['ubicaciones'] as List<dynamic>;
    } else if (response['items'] != null && response['items'] is List) {
      estanteriasList = response['items'] as List<dynamic>;
    } else {
      // Try to parse as single object or array at root
      // Check if response itself looks like a list structure
      final firstKey = response.keys.isNotEmpty ? response.keys.first : null;
      if (firstKey != null && firstKey == '0') {
        // Might be a list-like structure
        estanteriasList = response.values.toList();
      } else {
        // Single object
        estanteriasList = [response];
      }
    }

    if (estanteriasList == null) {
      print('   ⚠️ Could not parse estanterías list from response');
      print('   📋 Full response: $response');
      return [];
    }

    print('   📦 Found ${estanteriasList.length} estanterías');
    
    final estanterias = estanteriasList
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return Estanteria.fromJson(item);
            }
            return null;
          } catch (e) {
            print('   ⚠️ Error parsing estantería: $e');
            print('   📋 Item: $item');
            return null;
          }
        })
        .whereType<Estanteria>()
        .toList();

    print('   ✅ Successfully parsed ${estanterias.length} estanterías');
    return estanterias;
  }

  /// Update ubicación física with coordinates
  /// POST /api/inventario/ubicacion-fisica (with idUbicacion > 0 to update)
  /// Coordinates are stored in posicionX (lat) and posicionY (lng)
  Future<Map<String, dynamic>> updateUbicacionFisicaCoordenadas({
    required int idUbicacion,
    required double lat,
    required double lng,
    String? codigo,
    int? idTipoUbicacion,
    int? idZona,
    String? nombre,
    double? posicionX,
    double? posicionY,
    int? idPlantilla,
    bool? activo,
    int? capacidadMaxima,
    int? capacidadPorCelda,
    String? descripcion,
    int? numeroFilas,
    int? numeroColumnas,
    int? numeroNiveles,
  }) async {
    try {
      print('🔍 [InventarioApiService] Updating ubicación física coordinates...');
      print('   Endpoint: /inventario/ubicacion-fisica');
      print('   idUbicacion: $idUbicacion');
      print('   Coordinates (full precision):');
      print('      lat: $lat (${lat.toStringAsFixed(10)})');
      print('      lng: $lng (${lng.toStringAsFixed(10)})');
      print('   Storing in:');
      print('      posicionX (lat): $lat (${lat.toStringAsFixed(10)})');
      print('      posicionY (lng): $lng (${lng.toStringAsFixed(10)})');
      
      // Validate required fields for update
      if (idUbicacion <= 0) {
        throw ArgumentError('idUbicacion must be greater than 0 for update');
      }
      
      // Prepare body with required fields
      // According to API validation, these fields are required when updating:
      // - idUbicacion (must be > 0)
      // - codigo (must be string, length >= 1)
      // - nombre (must be string, length >= 1)
      // - idZona (must be integer >= 1)
      // - idTipoUbicacion (must be integer >= 1)
      // - posicionX (must be number) - stores latitude
      // - posicionY (must be number) - stores longitude
      // NOTE: API expects coordinates in posicionX and posicionY, NOT lat/lng
      final body = <String, dynamic>{
        'idUbicacion': idUbicacion,
        // Store coordinates in posicionX (lat) and posicionY (lng)
        // Use provided posicionX/posicionY if given, otherwise use lat/lng
        'posicionX': posicionX ?? lat,
        'posicionY': posicionY ?? lng,
        // Required fields - use provided values or defaults
        'codigo': codigo ?? 'SIN-CODIGO',
        'nombre': nombre ?? 'Sin nombre',
        'idZona': idZona ?? 1,
        'idTipoUbicacion': idTipoUbicacion ?? 1,
        // Optional fields
        if (idPlantilla != null) 'idPlantilla': idPlantilla,
        if (activo != null) 'activo': activo,
        if (capacidadMaxima != null) 'capacidadMaxima': capacidadMaxima,
        if (capacidadPorCelda != null) 'capacidadPorCelda': capacidadPorCelda,
        if (descripcion != null) 'descripcion': descripcion,
        if (numeroFilas != null) 'numeroFilas': numeroFilas,
        if (numeroColumnas != null) 'numeroColumnas': numeroColumnas,
        if (numeroNiveles != null) 'numeroNiveles': numeroNiveles,
      };
      
      print('   📋 Request body:');
      print('      idUbicacion: ${body['idUbicacion']}');
      print('      codigo: ${body['codigo']}');
      print('      nombre: ${body['nombre']}');
      print('      idZona: ${body['idZona']}');
      print('      idTipoUbicacion: ${body['idTipoUbicacion']}');
      final posX = body['posicionX'] as double;
      final posY = body['posicionY'] as double;
      print('      posicionX (lat): $posX (${posX.toStringAsFixed(10)})');
      print('      posicionY (lng): $posY (${posY.toStringAsFixed(10)})');
      
      final response = await _apiService.post(
        '/inventario/ubicacion-fisica',
        body: body,
      );
      
      print('✅ [InventarioApiService] Ubicación física coordinates updated');
      print('   📋 Response received:');
      print('      Response keys: ${response.keys}');
      if (response['data'] != null) {
        print('      Response data: ${response['data']}');
        if (response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          print('      Saved posicionX: ${data['posicionX'] ?? data['posicion_x']}');
          print('      Saved posicionY: ${data['posicionY'] ?? data['posicion_y']}');
        }
      }
      return response;
    } catch (e) {
      print('❌ [InventarioApiService] Error updating ubicación física coordinates: $e');
      rethrow;
    }
  }

  /// Create or update ubicación completa
  /// POST /api/inventario/ubicacion-completa
  Future<Map<String, dynamic>> createOrUpdateUbicacionCompleta({
    required String codigoUbicacion,
    required int idTipoUbicacion,
    required int idZona,
    required String nombreUbicacion,
    required int numeroColumnas,
    required int numeroFilas,
    required int numeroNiveles,
    required double posicionX,
    required double posicionY,
    required List<Map<String, dynamic>> configCeldas,
    int? idPlantilla,
  }) async {
    try {
      print('🔍 [InventarioApiService] Creating/updating ubicación completa...');
      print('   Endpoint: /inventario/ubicacion-completa');
      
      final body = <String, dynamic>{
        'codigoUbicacion': codigoUbicacion,
        'idTipoUbicacion': idTipoUbicacion,
        'idZona': idZona,
        'nombreUbicacion': nombreUbicacion,
        'numeroColumnas': numeroColumnas,
        'numeroFilas': numeroFilas,
        'numeroNiveles': numeroNiveles,
        'posicionX': posicionX,
        'posicionY': posicionY,
        'configCeldas': configCeldas,
        if (idPlantilla != null) 'idPlantilla': idPlantilla,
      };
      
      final response = await _apiService.post(
        '/inventario/ubicacion-completa',
        body: body,
      );
      
      print('✅ [InventarioApiService] Ubicación completa created/updated');
      return response;
    } catch (e) {
      print('❌ [InventarioApiService] Error creating/updating ubicación completa: $e');
      rethrow;
    }
  }

  /// Create or update ubicación física
  /// POST /api/inventario/ubicacion-fisica
  Future<Map<String, dynamic>> createOrUpdateUbicacionFisica({
    required String codigo,
    required int idTipoUbicacion,
    required int idZona,
    required String nombre,
    required double posicionX,
    required double posicionY,
    int? idUbicacion, // 0 para crear, >0 para actualizar
    int? idPlantilla,
    bool? activo,
    int? capacidadMaxima,
    int? capacidadPorCelda,
    String? descripcion,
    int? numeroFilas,
    int? numeroColumnas,
    int? numeroNiveles,
  }) async {
    try {
      print('🔍 [InventarioApiService] Creating/updating ubicación física...');
      print('   Endpoint: /inventario/ubicacion-fisica');
      
      final body = <String, dynamic>{
        'codigo': codigo,
        'idTipoUbicacion': idTipoUbicacion,
        'idZona': idZona,
        'nombre': nombre,
        'posicionX': posicionX,
        'posicionY': posicionY,
        'idUbicacion': idUbicacion ?? 0,
        if (idPlantilla != null) 'idPlantilla': idPlantilla,
        if (activo != null) 'activo': activo,
        if (capacidadMaxima != null) 'capacidadMaxima': capacidadMaxima,
        if (capacidadPorCelda != null) 'capacidadPorCelda': capacidadPorCelda,
        if (descripcion != null) 'descripcion': descripcion,
        if (numeroFilas != null) 'numeroFilas': numeroFilas,
        if (numeroColumnas != null) 'numeroColumnas': numeroColumnas,
        if (numeroNiveles != null) 'numeroNiveles': numeroNiveles,
      };
      
      final response = await _apiService.post(
        '/inventario/ubicacion-fisica',
        body: body,
      );
      
      print('✅ [InventarioApiService] Ubicación física created/updated');
      return response;
    } catch (e) {
      print('❌ [InventarioApiService] Error creating/updating ubicación física: $e');
      rethrow;
    }
  }

  /// Generate celdas for a ubicación
  /// POST /api/inventario/generar-celdas
  Future<Map<String, dynamic>> generarCeldas(int idUbicacion) async {
    try {
      print('🔍 [InventarioApiService] Generating celdas...');
      print('   Endpoint: /inventario/generar-celdas');
      
      final response = await _apiService.post(
        '/inventario/generar-celdas',
        body: {'idUbicacion': idUbicacion},
      );
      
      print('✅ [InventarioApiService] Celdas generated');
      return response;
    } catch (e) {
      print('❌ [InventarioApiService] Error generating celdas: $e');
      rethrow;
    }
  }

  /// Configure producto in celda
  /// POST /api/inventario/configurar-producto-celda
  Future<Map<String, dynamic>> configurarProductoCelda({
    required int idCelda,
    required int idProductoErp,
    bool? activo,
    int? cantidadMaxima,
    int? cantidadMinima,
    int? cantidadOptima,
    bool? esUbicacionPrimaria,
    int? prioridad,
  }) async {
    try {
      print('🔍 [InventarioApiService] Configuring producto in celda...');
      print('   Endpoint: /inventario/configurar-producto-celda');
      
      final body = <String, dynamic>{
        'idCelda': idCelda,
        'idProductoErp': idProductoErp,
        if (activo != null) 'activo': activo,
        if (cantidadMaxima != null) 'cantidadMaxima': cantidadMaxima,
        if (cantidadMinima != null) 'cantidadMinima': cantidadMinima,
        if (cantidadOptima != null) 'cantidadOptima': cantidadOptima,
        if (esUbicacionPrimaria != null) 'esUbicacionPrimaria': esUbicacionPrimaria,
        if (prioridad != null) 'prioridad': prioridad,
      };
      
      final response = await _apiService.post(
        '/inventario/configurar-producto-celda',
        body: body,
      );
      
      print('✅ [InventarioApiService] Producto configured in celda');
      return response;
    } catch (e) {
      print('❌ [InventarioApiService] Error configuring producto in celda: $e');
      rethrow;
    }
  }

  /// Get layout completo for a specific almacen
  /// POST /api/inventario/layout-completo/:idAlmacenErp
  Future<Map<String, dynamic>> getLayoutCompleto(int idAlmacenErp) async {
    try {
      print('🔍 [InventarioApiService] Getting layout completo...');
      print('   Endpoint: /inventario/layout-completo/$idAlmacenErp');
      
      final response = await _apiService.post(
        '/inventario/layout-completo/$idAlmacenErp',
        body: {},
      );
      
      print('✅ [InventarioApiService] Layout completo received');
      return response;
    } catch (e) {
      print('❌ [InventarioApiService] Error fetching layout completo: $e');
      rethrow;
    }
  }

  /// Get zonas
  /// POST /api/inventario/zonas
  /// Body format: { "idAlmacenErp": int, "nombre": string, "codigo": string?, "descripcion": string?, "posicionX": number?, "posicionY": number?, "color": string? }
  /// To get all zonas, send idAlmacenErp with nombre (can be empty string or zona name to filter)
  Future<List<Map<String, dynamic>>> getZonas({
    required int idAlmacenErp,
    String? nombre,
    String? nombreAlmacen,
    String? codigo,
    String? descripcion,
    double? posicionX,
    double? posicionY,
    String? color,
  }) async {
    try {
      print('🔍 [InventarioApiService] Getting zonas...');
      print('   Endpoint: /inventario/zonas');
      print('   Method: POST');
      print('   idAlmacenErp: $idAlmacenErp');
      print('   nombre (zona filter): ${nombre ?? "(null - will use empty string)"}');
      if (nombreAlmacen != null) {
        print('   nombreAlmacen: $nombreAlmacen');
      }
      
      // Validate idAlmacenErp
      if (idAlmacenErp < 1) {
        throw Exception('idAlmacenErp debe ser mayor a 0. Recibido: $idAlmacenErp');
      }
      
      // Build body according to API format from curl example
      // curl shows: { "idAlmacenErp": 1, "nombre": "Zona A", "posicionX": 0, "posicionY": 0, ... }
      // nombre is the ZONA name (for filtering), not almacén name
      // To get all zonas, send idAlmacenErp with nombre as empty string
      // Include posicionX and posicionY with default 0 (as shown in curl)
      final body = <String, dynamic>{
        'idAlmacenErp': idAlmacenErp,
        'nombre': nombre ?? '', // Zona name filter (empty string to get all zonas)
        'posicionX': posicionX ?? 0, // Include default 0 (matching curl format)
        'posicionY': posicionY ?? 0, // Include default 0 (matching curl format)
      };
      
      print('   📋 Body being sent: $body');
      print('   Body structure:');
      print('      idAlmacenErp: ${body['idAlmacenErp']} (${body['idAlmacenErp'].runtimeType})');
      print('      nombre: "${body['nombre']}" (${body['nombre'].runtimeType}, length: ${(body['nombre'] as String).length})');
      print('      posicionX: ${body['posicionX']}');
      print('      posicionY: ${body['posicionY']}');
      
      // Add optional fields if provided
      if (codigo != null && codigo.isNotEmpty) {
        body['codigo'] = codigo;
      }
      if (descripcion != null && descripcion.isNotEmpty) {
        body['descripcion'] = descripcion;
      }
      if (color != null && color.isNotEmpty) {
        body['color'] = color;
      }
      
      print('   📋 Final body: $body');
      
      print('   📋 Final body before sending: $body');
      print('   📋 Body type check:');
      print('      idAlmacenErp type: ${body['idAlmacenErp'].runtimeType}, value: ${body['idAlmacenErp']}');
      print('      nombre type: ${body['nombre'].runtimeType}, value: "${body['nombre']}"');
      print('      nombre isEmpty: ${(body['nombre'] as String).isEmpty}');
      print('      nombre length: ${(body['nombre'] as String).length}');
      
      final response = await _apiService.post(
        '/inventario/zonas',
        body: body,
      );
      
      print('✅ [InventarioApiService] Zonas received');
      print('   Response keys: ${response.keys}');
      
      // Parse response - API might return data in different formats
      List<Map<String, dynamic>> zonas = [];
      
      if (response['data'] != null && response['data'] is List) {
        zonas = (response['data'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
        print('   Found ${zonas.length} zonas in response.data');
      } else if (response['results'] != null && response['results'] is List) {
        zonas = (response['results'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
        print('   Found ${zonas.length} zonas in response.results');
      } else if (response['zonas'] != null && response['zonas'] is List) {
        zonas = (response['zonas'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
        print('   Found ${zonas.length} zonas in response.zonas');
      } else if (response.isNotEmpty) {
        // Single zona object - check if it's actually a zona or a wrapper
        // If it has idZona or id_zona, it's a zona object
        if (response.containsKey('idZona') || 
            response.containsKey('id_zona') || 
            response.containsKey('id')) {
          zonas = [response];
          print('   Found 1 zona in direct object response');
        } else {
          // Might be a wrapper, try to find zonas inside
          print('   ⚠️ Response is a Map but doesn\'t look like a zona, checking for nested data...');
          zonas = [];
        }
      }
      
      print('   ✅ Successfully parsed ${zonas.length} zonas');
      return zonas;
    } catch (e) {
      print('❌ [InventarioApiService] Error fetching zonas: $e');
      print('   Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}


