/// Almacén (Warehouse) model
class Almacen {
  final String? id;
  final int? idAlmacen;
  final int? idAlmacenErp;
  final int? idSucursal;
  final String? codigo;
  final String? nombre;
  final String? descripcion;
  final String? direccion;
  final String? telefono;
  final String? email;
  final bool? activo;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? deletedAt;
  final int? deletedBy;

  Almacen({
    this.id,
    this.idAlmacen,
    this.idAlmacenErp,
    this.idSucursal,
    this.codigo,
    this.nombre,
    this.descripcion,
    this.direccion,
    this.telefono,
    this.email,
    this.activo,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory Almacen.fromJson(Map<String, dynamic> json) {
    // Helper function to parse int from various formats
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Almacen(
      id: json['id']?.toString() ?? 
          json['idAlmacen']?.toString() ??
          json['id_almacen']?.toString(),
      idAlmacen: _parseInt(json['idAlmacen'] ?? json['id_almacen']),
      idAlmacenErp: _parseInt(json['idAlmacenErp'] ?? json['id_almacen_erp']),
      idSucursal: _parseInt(json['idSucursal'] ?? json['id_sucursal']),
      codigo: json['codigo']?.toString(),
      nombre: json['nombre']?.toString(),
      descripcion: json['descripcion']?.toString(),
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      activo: json['activo'] is bool
          ? json['activo'] as bool
          : (json['activo'] is String
              ? json['activo'].toString().toLowerCase() == 'true'
              : null),
      createdAt: json['createdAt']?.toString() ?? 
                 json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? 
                 json['updated_at']?.toString(),
      createdBy: _parseInt(json['created_by'] ?? json['createdBy']),
      updatedBy: _parseInt(json['updated_by'] ?? json['updatedBy']),
      deletedAt: json['deletedAt']?.toString() ?? 
                 json['deleted_at']?.toString(),
      deletedBy: _parseInt(json['deleted_by'] ?? json['deletedBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idAlmacen != null) 'idAlmacen': idAlmacen,
      if (idAlmacenErp != null) 'idAlmacenErp': idAlmacenErp,
      if (idSucursal != null) 'idSucursal': idSucursal,
      if (codigo != null) 'codigo': codigo,
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (activo != null) 'activo': activo,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (deletedBy != null) 'deletedBy': deletedBy,
    };
  }
}

