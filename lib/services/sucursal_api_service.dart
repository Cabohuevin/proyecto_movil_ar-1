import 'api_service.dart';

/// Sucursal (Branch) model
class Sucursal {
  final String id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final Map<String, dynamic>? metadata;

  Sucursal({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.metadata,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Sucursal API Service
class SucursalApiService {
  final ApiService _apiService;

  SucursalApiService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all sucursales
  Future<List<Sucursal>> getAllSucursales() async {
    try {
      final response = await _apiService.get('/sucursales');

      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Sucursal.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching sucursales: $e');
      return [];
    }
  }

  /// Get sucursal by ID
  Future<Sucursal?> getSucursalById(String id) async {
    try {
      final response = await _apiService.get('/sucursales/$id');

      if (response['data'] != null) {
        return Sucursal.fromJson(response['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error fetching sucursal by ID: $e');
      return null;
    }
  }

  /// Create new sucursal
  Future<Sucursal?> createSucursal(Sucursal sucursal) async {
    try {
      final response = await _apiService.post(
        '/sucursales',
        body: sucursal.toJson(),
      );

      if (response['data'] != null) {
        return Sucursal.fromJson(response['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error creating sucursal: $e');
      return null;
    }
  }

  /// Update sucursal
  Future<bool> updateSucursal(String id, Sucursal sucursal) async {
    try {
      await _apiService.put(
        '/sucursales/$id',
        body: sucursal.toJson(),
      );
      return true;
    } catch (e) {
      print('Error updating sucursal: $e');
      return false;
    }
  }

  /// Delete sucursal
  Future<bool> deleteSucursal(String id) async {
    try {
      await _apiService.delete('/sucursales/$id');
      return true;
    } catch (e) {
      print('Error deleting sucursal: $e');
      return false;
    }
  }
}

