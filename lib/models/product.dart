/// Product model for pharmaceutical inventory
/// API Structure: https://api.codigocreativo.cloud/api/docs
class Product {
  // Core fields (from API)
  final String? id;
  final int? idProducto; // Primary key from API
  final int? idEmpresa;
  final String? codigo; // max length: 50, required for POST
  final String? codigoBarras; // max length: 50
  final String? nombre; // max length: 200, required for POST
  final String? descripcion;
  final int? idCategoria; // required for POST
  final int? idMarca;
  final int? idPresentacion;
  final int? idUnidad; // required for POST
  final String? tipoProducto; // e.g., "MEDICAMENTO"
  final bool? esMedicamento;
  final bool? requiereReceta;
  final bool? manejaInventario;
  final bool? manejaLotes;
  final bool? permiteVentaSinStock;
  final bool? activo;
  
  // Audit fields
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? deletedAt;
  final int? deletedBy;
  
  // Additional fields (from inventory/relations)
  final int? stock;
  final String? lote;
  final DateTime? fechaCaducidad;
  final String? uriModelo3D;
  final Map<String, dynamic>? metadata;
  
  // Location fields (from estanteria relation)
  final double? estanteriaLat;
  final double? estanteriaLng;
  final String? estanteriaNombre;
  
  // Branch fields (from sucursal relation)
  final String? sucursalId;
  final String? sucursalNombre;
  final String? sucursalDireccion;

  Product({
    this.id,
    this.idProducto,
    this.idEmpresa,
    this.codigo,
    this.codigoBarras,
    this.nombre,
    this.descripcion,
    this.idCategoria,
    this.idMarca,
    this.idPresentacion,
    this.idUnidad,
    this.tipoProducto,
    this.esMedicamento,
    this.requiereReceta,
    this.manejaInventario,
    this.manejaLotes,
    this.permiteVentaSinStock,
    this.activo,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.stock,
    this.lote,
    this.fechaCaducidad,
    this.uriModelo3D,
    this.metadata,
    this.estanteriaLat,
    this.estanteriaLng,
    this.estanteriaNombre,
    this.sucursalId,
    this.sucursalNombre,
    this.sucursalDireccion,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? json['idProducto']?.toString(),
      idProducto: json['idProducto'] is int
          ? json['idProducto'] as int
          : (json['idProducto'] is String ? int.tryParse(json['idProducto'].toString()) : null),
      idEmpresa: json['idEmpresa'] is int
          ? json['idEmpresa'] as int
          : (json['idEmpresa'] is String ? int.tryParse(json['idEmpresa'].toString()) : null),
      codigo: json['codigo']?.toString(),
      codigoBarras: json['codigoBarras']?.toString(),
      nombre: json['nombre']?.toString(),
      descripcion: json['descripcion']?.toString(),
      idCategoria: json['idCategoria'] is int
          ? json['idCategoria'] as int
          : (json['idCategoria'] is String
              ? int.tryParse(json['idCategoria'].toString())
              : null),
      idMarca: json['idMarca'] is int
          ? json['idMarca'] as int
          : (json['idMarca'] is String ? int.tryParse(json['idMarca'].toString()) : null),
      idPresentacion: json['idPresentacion'] is int
          ? json['idPresentacion'] as int
          : (json['idPresentacion'] is String ? int.tryParse(json['idPresentacion'].toString()) : null),
      idUnidad: json['idUnidad'] is int
          ? json['idUnidad'] as int
          : (json['idUnidad'] is String
              ? int.tryParse(json['idUnidad'].toString())
              : null),
      tipoProducto: json['tipoProducto']?.toString(),
      esMedicamento: json['esMedicamento'] is bool
          ? json['esMedicamento'] as bool
          : (json['esMedicamento'] == true || json['esMedicamento'] == 1),
      requiereReceta: json['requiereReceta'] is bool
          ? json['requiereReceta'] as bool
          : (json['requiereReceta'] == true || json['requiereReceta'] == 1),
      manejaInventario: json['manejaInventario'] is bool
          ? json['manejaInventario'] as bool
          : (json['manejaInventario'] == true || json['manejaInventario'] == 1),
      manejaLotes: json['manejaLotes'] is bool
          ? json['manejaLotes'] as bool
          : (json['manejaLotes'] == true || json['manejaLotes'] == 1),
      permiteVentaSinStock: json['permiteVentaSinStock'] is bool
          ? json['permiteVentaSinStock'] as bool
          : (json['permiteVentaSinStock'] == true || json['permiteVentaSinStock'] == 1),
      activo: json['activo'] is bool
          ? json['activo'] as bool
          : (json['activo'] == true || json['activo'] == 1 || json['activo'] == 'true'),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      createdBy: json['createdBy'] is int
          ? json['createdBy'] as int
          : (json['createdBy'] is String ? int.tryParse(json['createdBy'].toString()) : null),
      updatedBy: json['updatedBy'] is int
          ? json['updatedBy'] as int
          : (json['updatedBy'] is String ? int.tryParse(json['updatedBy'].toString()) : null),
      deletedAt: json['deletedAt']?.toString(),
      deletedBy: json['deletedBy'] is int
          ? json['deletedBy'] as int
          : (json['deletedBy'] is String ? int.tryParse(json['deletedBy'].toString()) : null),
      // Additional fields from inventory/relations
      stock: json['stock'] is int 
          ? json['stock'] 
          : (json['stock'] is String ? int.tryParse(json['stock']) : null),
      lote: json['lote']?.toString(),
      fechaCaducidad: json['fechaCaducidad'] != null
          ? DateTime.tryParse(json['fechaCaducidad'].toString())
          : null,
      uriModelo3D: json['uriModelo3D']?.toString() ?? 
                   json['uri_modelo_3d']?.toString() ??
                   json['modelo3d']?.toString(),
      metadata: json['metadata'] is Map 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      estanteriaLat: json['estanteriaLat'] != null
          ? (json['estanteriaLat'] is num 
              ? json['estanteriaLat'].toDouble() 
              : double.tryParse(json['estanteriaLat'].toString()))
          : (json['estanteria'] != null && json['estanteria'] is Map
              ? (json['estanteria']['lat'] is num
                  ? json['estanteria']['lat'].toDouble()
                  : double.tryParse(json['estanteria']['lat'].toString()))
              : null),
      estanteriaLng: json['estanteriaLng'] != null
          ? (json['estanteriaLng'] is num 
              ? json['estanteriaLng'].toDouble() 
              : double.tryParse(json['estanteriaLng'].toString()))
          : (json['estanteria'] != null && json['estanteria'] is Map
              ? (json['estanteria']['lng'] is num
                  ? json['estanteria']['lng'].toDouble()
                  : double.tryParse(json['estanteria']['lng'].toString()))
              : null),
      estanteriaNombre: json['estanteriaNombre']?.toString() ??
                       (json['estanteria'] != null && json['estanteria'] is Map
                           ? json['estanteria']['nombre']?.toString()
                           : null),
      sucursalId: json['sucursalId']?.toString() ??
                  (json['sucursal'] != null && json['sucursal'] is Map
                      ? json['sucursal']['id']?.toString()
                      : (json['sucursal'] is String ? json['sucursal'] : null)),
      sucursalNombre: json['sucursalNombre']?.toString() ??
                     (json['sucursal'] != null && json['sucursal'] is Map
                         ? json['sucursal']['nombre']?.toString()
                         : null),
      sucursalDireccion: json['sucursalDireccion']?.toString() ??
                        (json['sucursal'] != null && json['sucursal'] is Map
                            ? json['sucursal']['direccion']?.toString()
                            : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idProducto != null) 'idProducto': idProducto,
      if (idEmpresa != null) 'idEmpresa': idEmpresa,
      if (codigo != null) 'codigo': codigo,
      if (codigoBarras != null) 'codigoBarras': codigoBarras,
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (idCategoria != null) 'idCategoria': idCategoria,
      if (idMarca != null) 'idMarca': idMarca,
      if (idPresentacion != null) 'idPresentacion': idPresentacion,
      if (idUnidad != null) 'idUnidad': idUnidad,
      if (tipoProducto != null) 'tipoProducto': tipoProducto,
      if (esMedicamento != null) 'esMedicamento': esMedicamento,
      if (requiereReceta != null) 'requiereReceta': requiereReceta,
      if (manejaInventario != null) 'manejaInventario': manejaInventario,
      if (manejaLotes != null) 'manejaLotes': manejaLotes,
      if (permiteVentaSinStock != null) 'permiteVentaSinStock': permiteVentaSinStock,
      if (activo != null) 'activo': activo,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (deletedBy != null) 'deletedBy': deletedBy,
      // Additional fields (from inventory/relations)
      if (stock != null) 'stock': stock,
      if (lote != null) 'lote': lote,
      if (fechaCaducidad != null) 
        'fechaCaducidad': fechaCaducidad!.toIso8601String(),
      if (uriModelo3D != null) 'uriModelo3D': uriModelo3D,
      if (metadata != null) 'metadata': metadata,
      // Location fields
      if (estanteriaLat != null) 'estanteriaLat': estanteriaLat,
      if (estanteriaLng != null) 'estanteriaLng': estanteriaLng,
      if (estanteriaNombre != null) 'estanteriaNombre': estanteriaNombre,
      // Branch fields
      if (sucursalId != null) 'sucursalId': sucursalId,
      if (sucursalNombre != null) 'sucursalNombre': sucursalNombre,
      if (sucursalDireccion != null) 'sucursalDireccion': sucursalDireccion,
    };
  }

  /// Check if product is expired
  bool get isExpired {
    if (fechaCaducidad == null) return false;
    final fecha = fechaCaducidad;
    if (fecha == null) return false;
    return DateTime.now().isAfter(fecha);
  }

  /// Check if product is about to expire (within 30 days)
  bool get isExpiringSoon {
    if (fechaCaducidad == null) return false;
    final fecha = fechaCaducidad;
    if (fecha == null) return false;
    final daysUntilExpiry = fecha.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Check if stock is low (less than 5 units)
  bool get isLowStock {
    if (stock == null) return false;
    final stockValue = stock;
    if (stockValue == null) return false;
    return stockValue < 5;
  }

  /// Check if product has shelf location
  bool get hasShelfLocation {
    return estanteriaLat != null && estanteriaLng != null;
  }

  /// Check if product has branch/sucursal
  bool get hasSucursal {
    return sucursalId != null || sucursalNombre != null;
  }
}

