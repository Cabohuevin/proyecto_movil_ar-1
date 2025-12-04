/// Estantería (Shelf/Ubicación Física) model for inventory management
class Estanteria {
  final String? id;
  final int? idUbicacion;
  final String? codigo;
  final String? nombre;
  final double? lat;
  final double? lng;
  final String? descripcion;
  final int? idAlmacenErp;
  final String? idAlmacenErpString;
  final int? idZona;
  final String? zona;
  final String? ubicacionFisica;
  final int? idTipoUbicacion;
  final int? idPlantilla;
  final double? posicionX;
  final double? posicionY;
  final double? posicionZ;
  final double? rotacion;
  final int? numeroFilas;
  final int? numeroColumnas;
  final int? numeroNiveles;
  final int? capacidadMaxima;
  final double? capacidadMaximaUnidades;
  final int? capacidadPorCelda;
  final bool? permiteLlenadoAuto;
  final String? estrategiaLlenado;
  final int? idCodigoQr;
  final String? imagenUrl;
  final String? modelo3D;
  final String? modelo3DUrl;
  final Map<String, dynamic>? layout;
  final List<dynamic>? celdas;
  final Map<String, dynamic>? metadata;
  final bool? activo;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;

  Estanteria({
    this.id,
    this.idUbicacion,
    this.codigo,
    this.nombre,
    this.lat,
    this.lng,
    this.descripcion,
    this.idAlmacenErp,
    this.idAlmacenErpString,
    this.idZona,
    this.zona,
    this.ubicacionFisica,
    this.idTipoUbicacion,
    this.idPlantilla,
    this.posicionX,
    this.posicionY,
    this.posicionZ,
    this.rotacion,
    this.numeroFilas,
    this.numeroColumnas,
    this.numeroNiveles,
    this.capacidadMaxima,
    this.capacidadMaximaUnidades,
    this.capacidadPorCelda,
    this.permiteLlenadoAuto,
    this.estrategiaLlenado,
    this.idCodigoQr,
    this.imagenUrl,
    this.modelo3D,
    this.modelo3DUrl,
    this.layout,
    this.celdas,
    this.metadata,
    this.activo,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory Estanteria.fromJson(Map<String, dynamic> json) {
    // Helper function to parse int from various formats
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // Helper function to parse double from various formats
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    return Estanteria(
      id: json['id']?.toString() ?? 
          json['id_ubicacion']?.toString() ??
          json['idEstanteria']?.toString() ?? 
          json['_id']?.toString(),
      idUbicacion: _parseInt(json['id_ubicacion'] ?? json['idUbicacion']),
      codigo: json['codigo']?.toString() ?? 
              json['codigoUbicacion']?.toString(),
      nombre: json['nombre']?.toString() ?? 
              json['nombreUbicacion']?.toString() ??
              json['name']?.toString(),
      // Position fields - handle both camelCase and snake_case
      posicionX: _parseDouble(json['posicion_x'] ?? json['posicionX']),
      posicionY: _parseDouble(json['posicion_y'] ?? json['posicionY']),
      posicionZ: _parseDouble(json['posicion_z'] ?? json['posicionZ']),
      rotacion: _parseDouble(json['rotacion'] ?? json['rotation']),
      numeroFilas: _parseInt(json['numero_filas'] ?? json['numeroFilas']),
      numeroColumnas: _parseInt(json['numero_columnas'] ?? json['numeroColumnas']),
      numeroNiveles: _parseInt(json['numero_niveles'] ?? json['numeroNiveles']),
      // Parse lat/lng - check multiple sources
      // If lat/lng are not provided but posicionX/posicionY are in GPS range, use them
      // Note: 0,0 is considered empty (default value), so we convert it to null
      lat: () {
        double? value;
        if (json['lat'] != null) {
          value = json['lat'] is num 
              ? json['lat'].toDouble() 
              : double.tryParse(json['lat'].toString());
        } else if (json['latitude'] != null) {
          value = json['latitude'] is num
              ? json['latitude'].toDouble()
              : double.tryParse(json['latitude'].toString());
        } else {
          value = _parseDouble(json['posicion_x'] ?? json['posicionX']);
        }
        // Return null if value is 0 (considered empty/default)
        return (value != null && value != 0.0) ? value : null;
      }(),
      lng: () {
        double? value;
        if (json['lng'] != null) {
          value = json['lng'] is num 
              ? json['lng'].toDouble() 
              : double.tryParse(json['lng'].toString());
        } else if (json['longitude'] != null) {
          value = json['longitude'] is num
              ? json['longitude'].toDouble()
              : double.tryParse(json['longitude'].toString());
        } else {
          value = _parseDouble(json['posicion_y'] ?? json['posicionY']);
        }
        // Return null if value is 0 (considered empty/default)
        return (value != null && value != 0.0) ? value : null;
      }(),
      descripcion: json['descripcion']?.toString() ?? 
                   json['description']?.toString(),
      idAlmacenErp: json['idAlmacenErp'] is int
          ? json['idAlmacenErp'] as int
          : (json['idAlmacenErp'] is String 
              ? int.tryParse(json['idAlmacenErp'].toString()) 
              : null),
      idAlmacenErpString: json['idAlmacenErp']?.toString(),
      idZona: _parseInt(json['id_zona'] ?? json['idZona']),
      zona: json['zona']?.toString() ?? 
            json['zone']?.toString() ??
            json['nombreZona']?.toString(),
      ubicacionFisica: json['ubicacionFisica']?.toString() ?? 
                      json['ubicacion_fisica']?.toString() ??
                      json['physicalLocation']?.toString(),
      idTipoUbicacion: _parseInt(json['id_tipo_ubicacion'] ?? json['idTipoUbicacion']),
      idPlantilla: _parseInt(json['id_plantilla'] ?? json['idPlantilla']),
      capacidadMaxima: _parseInt(json['capacidad_maxima'] ?? json['capacidadMaxima']),
      capacidadMaximaUnidades: _parseDouble(json['capacidad_maxima_unidades'] ?? json['capacidadMaximaUnidades']),
      capacidadPorCelda: _parseInt(json['capacidad_por_celda'] ?? json['capacidadPorCelda']),
      permiteLlenadoAuto: json['permite_llenado_auto'] is bool
          ? json['permite_llenado_auto'] as bool
          : (json['permiteLlenadoAuto'] is bool
              ? json['permiteLlenadoAuto'] as bool
              : (json['permite_llenado_auto'] is String
                  ? json['permite_llenado_auto'].toString().toLowerCase() == 'true'
                  : null)),
      estrategiaLlenado: json['estrategia_llenado']?.toString() ?? 
                        json['estrategiaLlenado']?.toString(),
      idCodigoQr: _parseInt(json['id_codigo_qr'] ?? json['idCodigoQr']),
      imagenUrl: json['imagen_url']?.toString() ?? 
                json['imagenUrl']?.toString(),
      layout: json['layout'] is Map 
          ? Map<String, dynamic>.from(json['layout'])
          : null,
      celdas: json['celdas'] is List 
          ? List<dynamic>.from(json['celdas'])
          : (json['cells'] is List 
              ? List<dynamic>.from(json['cells'])
              : (json['configCeldas'] is List
                  ? List<dynamic>.from(json['configCeldas'])
                  : null)),
      metadata: json['metadata'] is Map 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      modelo3D: json['modelo3D']?.toString() ?? 
                json['modelo_3d']?.toString() ??
                json['model3D']?.toString(),
      modelo3DUrl: json['modelo_3d_url']?.toString() ?? 
                  json['modelo3DUrl']?.toString() ??
                  json['modelo3D']?.toString(),
      activo: json['activo'] is bool 
          ? json['activo'] as bool
          : (json['activo'] is String 
              ? json['activo'].toString().toLowerCase() == 'true'
              : (json['active'] is bool 
                  ? json['active'] as bool
                  : null)),
      createdAt: json['createdAt']?.toString() ?? 
                 json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? 
                 json['updated_at']?.toString(),
      createdBy: _parseInt(json['created_by'] ?? json['createdBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idUbicacion != null) 'idUbicacion': idUbicacion,
      if (codigo != null) 'codigo': codigo,
      if (codigo != null) 'codigo': codigo,
      if (codigo != null) 'codigoUbicacion': codigo,
      if (nombre != null) 'nombre': nombre,
      if (nombre != null) 'nombreUbicacion': nombre,
      // Required fields for ubicacion-completa
      if (posicionX != null) 'posicionX': posicionX,
      if (posicionY != null) 'posicionY': posicionY,
      if (numeroFilas != null) 'numeroFilas': numeroFilas,
      if (numeroColumnas != null) 'numeroColumnas': numeroColumnas,
      if (numeroNiveles != null) 'numeroNiveles': numeroNiveles,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (descripcion != null) 'descripcion': descripcion,
      if (idAlmacenErp != null) 'idAlmacenErp': idAlmacenErp,
      if (idZona != null) 'idZona': idZona,
      if (zona != null) 'zona': zona,
      if (ubicacionFisica != null) 'ubicacionFisica': ubicacionFisica,
      if (idTipoUbicacion != null) 'idTipoUbicacion': idTipoUbicacion,
      if (idPlantilla != null) 'idPlantilla': idPlantilla,
      if (posicionX != null) 'posicionX': posicionX,
      if (posicionY != null) 'posicionY': posicionY,
      if (numeroFilas != null) 'numeroFilas': numeroFilas,
      if (numeroColumnas != null) 'numeroColumnas': numeroColumnas,
      if (numeroNiveles != null) 'numeroNiveles': numeroNiveles,
      if (capacidadMaxima != null) 'capacidadMaxima': capacidadMaxima,
      if (capacidadPorCelda != null) 'capacidadPorCelda': capacidadPorCelda,
      if (layout != null) 'layout': layout,
      if (celdas != null) 'celdas': celdas,
      if (metadata != null) 'metadata': metadata,
      if (modelo3D != null) 'modelo3D': modelo3D,
      if (activo != null) 'activo': activo,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  /// Check if estantería has location coordinates
  /// Checks both lat/lng and posicionX/posicionY (which may contain GPS coordinates)
  /// Note: 0,0 is considered empty/invalid (default value, not a real GPS coordinate)
  bool get hasLocation {
    // Check if lat/lng are explicitly set
    if (lat != null && lng != null) {
      // Exclude 0,0 as it's a default value, not a real GPS coordinate
      if (lat! == 0.0 && lng! == 0.0) return false;
      // Verify they are in valid GPS range (lat: -90 to 90, lng: -180 to 180)
      if (lat! >= -90 && lat! <= 90 && lng! >= -180 && lng! <= 180) {
        return true;
      }
    }
    // Check if posicionX/posicionY are set and in GPS range (used when API stores GPS in posicionX/posicionY)
    if (posicionX != null && posicionY != null) {
      // Exclude 0,0 as it's a default value, not a real GPS coordinate
      if (posicionX! == 0.0 && posicionY! == 0.0) return false;
      // Verify they are in valid GPS range (lat: -90 to 90, lng: -180 to 180)
      if (posicionX! >= -90 && posicionX! <= 90 && posicionY! >= -180 && posicionY! <= 180) {
        return true;
      }
    }
    return false;
  }
  
  /// Get latitude (from lat or posicionX)
  /// Returns null if value is 0 (considered empty/default)
  double? get latitude {
    if (lat != null && lat! != 0.0 && lat! >= -90 && lat! <= 90) return lat;
    if (posicionX != null && posicionX! != 0.0 && posicionX! >= -90 && posicionX! <= 90) return posicionX;
    return null;
  }
  
  /// Get longitude (from lng or posicionY)
  /// Returns null if value is 0 (considered empty/default)
  double? get longitude {
    if (lng != null && lng! != 0.0 && lng! >= -180 && lng! <= 180) return lng;
    if (posicionY != null && posicionY! != 0.0 && posicionY! >= -180 && posicionY! <= 180) return posicionY;
    return null;
  }

  /// Check if estantería has layout information
  bool get hasLayout {
    return layout != null && layout!.isNotEmpty;
  }

  /// Check if estantería has cells
  bool get hasCells {
    return celdas != null && celdas!.isNotEmpty;
  }
}

