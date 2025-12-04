import 'product.dart';

/// Inventory alert model
class InventoryAlert {
  final String? id;
  final Product? product;
  final String tipo; // 'caducidad', 'stock', 'vencido'
  final String mensaje;
  final DateTime? fechaCreacion;
  final bool resuelto;

  InventoryAlert({
    this.id,
    this.product,
    required this.tipo,
    required this.mensaje,
    this.fechaCreacion,
    this.resuelto = false,
  });

  factory InventoryAlert.fromJson(Map<String, dynamic> json) {
    return InventoryAlert(
      id: json['id']?.toString(),
      product: json['producto'] != null 
          ? Product.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
      tipo: json['tipo']?.toString() ?? 'unknown',
      mensaje: json['mensaje']?.toString() ?? '',
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      resuelto: json['resuelto'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (product != null) 'producto': product!.toJson(),
      'tipo': tipo,
      'mensaje': mensaje,
      if (fechaCreacion != null) 
        'fechaCreacion': fechaCreacion!.toIso8601String(),
      'resuelto': resuelto,
    };
  }

  /// Create alert from product
  factory InventoryAlert.fromProduct(Product product) {
    String tipo = 'info';
    String mensaje = '';

    if (product.isExpired) {
      tipo = 'vencido';
      mensaje = 'PRODUCTO VENCIDO: ${product.stock ?? 0} UNIDADES';
    } else if (product.isExpiringSoon) {
      tipo = 'caducidad';
      final fechaCaducidad = product.fechaCaducidad;
      if (fechaCaducidad != null) {
        final days = fechaCaducidad.difference(DateTime.now()).inDays;
        mensaje = 'PRONTO A CADUCAR (${days} días): ${product.stock ?? 0} UNIDADES';
      } else {
        mensaje = 'PRONTO A CADUCAR: ${product.stock ?? 0} UNIDADES';
      }
    } else if (product.isLowStock) {
      tipo = 'stock';
      mensaje = 'BAJO STOCK: ${product.stock ?? 0} UNIDADES RESTANTES';
    }

    return InventoryAlert(
      product: product,
      tipo: tipo,
      mensaje: mensaje,
      fechaCreacion: DateTime.now(),
    );
  }
}

