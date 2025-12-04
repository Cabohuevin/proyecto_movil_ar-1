import '../models/almacen.dart';
import 'api_service.dart';

/// API Service for managing almacenes (warehouses)
class AlmacenApiService {
  final ApiService _apiService;

  AlmacenApiService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all almacenes
  /// GET /api/almacenes
  Future<List<Almacen>> getAllAlmacenes() async {
    try {
      print('🔍 [AlmacenApiService] Getting all almacenes...');
      print('   Endpoint: /almacenes');
      print('   Method: GET');

      final response = await _apiService.get('/almacenes');
      print('   ✅ GET successful - parsing response...');

      final almacenes = _parseAlmacenesFromResponse(response);
      print('   ✅ Successfully retrieved ${almacenes.length} almacenes');
      return almacenes;
    } catch (e) {
      print('❌ [AlmacenApiService] Error fetching almacenes: $e');
      rethrow;
    }
  }

  /// Get almacén by ID
  /// GET /api/almacenes/:id
  Future<Almacen> getAlmacenById(int id) async {
    try {
      print('🔍 [AlmacenApiService] Getting almacén by ID...');
      print('   Endpoint: /almacenes/$id');
      print('   Method: GET');

      final response = await _apiService.get('/almacenes/$id');
      print('   ✅ GET successful - parsing response...');

      final almacen = Almacen.fromJson(response);
      print('   ✅ Successfully retrieved almacén: ${almacen.nombre}');
      return almacen;
    } catch (e) {
      print('❌ [AlmacenApiService] Error fetching almacén: $e');
      rethrow;
    }
  }

  /// Get almacenes by sucursal ID
  /// GET /api/almacenes/sucursal/:id
  Future<List<Almacen>> getAlmacenesBySucursal(int idSucursal) async {
    try {
      print('🔍 [AlmacenApiService] Getting almacenes by sucursal...');
      print('   Endpoint: /almacenes/sucursal/$idSucursal');
      print('   Method: GET');

      final response = await _apiService.get('/almacenes/sucursal/$idSucursal');
      print('   ✅ GET successful - parsing response...');

      final almacenes = _parseAlmacenesFromResponse(response);
      print('   ✅ Successfully retrieved ${almacenes.length} almacenes for sucursal $idSucursal');
      return almacenes;
    } catch (e) {
      print('❌ [AlmacenApiService] Error fetching almacenes by sucursal: $e');
      rethrow;
    }
  }

  /// Create almacén
  /// POST /api/almacenes
  Future<Almacen> createAlmacen({
    required String codigo,
    required String nombre,
    int? idSucursal,
    String? descripcion,
    String? direccion,
    String? telefono,
    String? email,
    bool? activo,
  }) async {
    try {
      print('🔍 [AlmacenApiService] Creating almacén...');
      print('   Endpoint: /almacenes');
      print('   Method: POST');

      final body = {
        'codigo': codigo,
        'nombre': nombre,
        if (idSucursal != null) 'idSucursal': idSucursal,
        if (descripcion != null) 'descripcion': descripcion,
        if (direccion != null) 'direccion': direccion,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (activo != null) 'activo': activo,
      };

      print('   📋 Body: $body');

      final response = await _apiService.post('/almacenes', body: body);
      print('   ✅ POST successful - parsing response...');

      final almacen = Almacen.fromJson(response);
      print('   ✅ Successfully created almacén: ${almacen.nombre}');
      return almacen;
    } catch (e) {
      print('❌ [AlmacenApiService] Error creating almacén: $e');
      rethrow;
    }
  }

  /// Update almacén
  /// PATCH /api/almacenes/:id
  Future<Almacen> updateAlmacen({
    required int id,
    String? codigo,
    String? nombre,
    int? idSucursal,
    String? descripcion,
    String? direccion,
    String? telefono,
    String? email,
    bool? activo,
  }) async {
    try {
      print('🔍 [AlmacenApiService] Updating almacén...');
      print('   Endpoint: /almacenes/$id');
      print('   Method: PATCH');

      final body = <String, dynamic>{};
      if (codigo != null) body['codigo'] = codigo;
      if (nombre != null) body['nombre'] = nombre;
      if (idSucursal != null) body['idSucursal'] = idSucursal;
      if (descripcion != null) body['descripcion'] = descripcion;
      if (direccion != null) body['direccion'] = direccion;
      if (telefono != null) body['telefono'] = telefono;
      if (email != null) body['email'] = email;
      if (activo != null) body['activo'] = activo;

      print('   📋 Body: $body');

      final response = await _apiService.patch('/almacenes/$id', body: body);
      print('   ✅ PATCH successful - parsing response...');

      final almacen = Almacen.fromJson(response);
      print('   ✅ Successfully updated almacén: ${almacen.nombre}');
      return almacen;
    } catch (e) {
      print('❌ [AlmacenApiService] Error updating almacén: $e');
      rethrow;
    }
  }

  /// Delete almacén
  /// DELETE /api/almacenes/:id
  Future<void> deleteAlmacen(int id) async {
    try {
      print('🔍 [AlmacenApiService] Deleting almacén...');
      print('   Endpoint: /almacenes/$id');
      print('   Method: DELETE');

      await _apiService.delete('/almacenes/$id');
      print('   ✅ DELETE successful');
    } catch (e) {
      print('❌ [AlmacenApiService] Error deleting almacén: $e');
      rethrow;
    }
  }

  /// Parse almacenes from API response
  List<Almacen> _parseAlmacenesFromResponse(dynamic response) {
    if (response == null) {
      print('   ⚠️ Response is null');
      return [];
    }

    List<dynamic> almacenesList;

    if (response is List) {
      almacenesList = response;
    } else if (response is Map<String, dynamic>) {
      if (response['data'] != null && response['data'] is List) {
        almacenesList = response['data'] as List;
      } else if (response['results'] != null && response['results'] is List) {
        almacenesList = response['results'] as List;
      } else if (response['almacenes'] != null && response['almacenes'] is List) {
        almacenesList = response['almacenes'] as List;
      } else {
        // Single almacén object
        return [Almacen.fromJson(response)];
      }
    } else {
      print('   ⚠️ Unexpected response type: ${response.runtimeType}');
      return [];
    }

    print('   📦 Found ${almacenesList.length} almacenes');

    final almacenes = almacenesList
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return Almacen.fromJson(item);
            }
            return null;
          } catch (e) {
            print('   ⚠️ Error parsing almacén: $e');
            print('   📋 Item: $item');
            return null;
          }
        })
        .whereType<Almacen>()
        .toList();

    print('   ✅ Successfully parsed ${almacenes.length} almacenes');
    return almacenes;
  }
}

