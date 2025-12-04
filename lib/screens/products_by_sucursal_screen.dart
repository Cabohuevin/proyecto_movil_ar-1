import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

class ProductsBySucursalScreen extends StatefulWidget {
  const ProductsBySucursalScreen({super.key});

  @override
  State<ProductsBySucursalScreen> createState() => _ProductsBySucursalScreenState();
}

class _ProductsBySucursalScreenState extends State<ProductsBySucursalScreen> {
  final ProductApiService _apiService = ProductApiService();
  Map<String, List<Product>> _productsBySucursal = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  Set<String> _expandedSucursales = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final grouped = await _apiService.getProductsBySucursalGrouped();
      setState(() {
        _productsBySucursal = grouped;
        _isLoading = false;
        // Expandir todas las sucursales por defecto
        _expandedSucursales = grouped.keys.toSet();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar productos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _toggleSucursal(String sucursal) {
    setState(() {
      if (_expandedSucursales.contains(sucursal)) {
        _expandedSucursales.remove(sucursal);
      } else {
        _expandedSucursales.add(sucursal);
      }
    });
  }

  Map<String, List<Product>> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _productsBySucursal;
    }

    final filtered = <String, List<Product>>{};
    final query = _searchQuery.toLowerCase();

    _productsBySucursal.forEach((sucursal, products) {
      final matchingProducts = products.where((product) {
        return (product.nombre?.toLowerCase().contains(query) ?? false) ||
               (product.codigo?.toLowerCase().contains(query) ?? false) ||
               (product.descripcion?.toLowerCase().contains(query) ?? false) ||
               (sucursal.toLowerCase().contains(query));
      }).toList();

      if (matchingProducts.isNotEmpty) {
        filtered[sucursal] = matchingProducts;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store, size: 24),
            SizedBox(width: 8),
            Text("Productos por Sucursal"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: "Actualizar",
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar por nombre, código o sucursal...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Cargando productos..."),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage ?? 'Error desconocido',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadProducts,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Reintentar"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? "No hay productos disponibles"
                                      : "No se encontraron productos",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final sucursal = _filteredProducts.keys.elementAt(index);
                              final products = _filteredProducts[sucursal];
                              if (products == null) return const SizedBox.shrink();
                              
                              final isExpanded = _expandedSucursales.contains(sucursal);

                              return _buildSucursalCard(sucursal, products, isExpanded);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalCard(
    String sucursal,
    List<Product> products,
    bool isExpanded,
  ) {
    final totalStock = products.fold<int>(
      0,
      (sum, product) => sum + (product.stock ?? 0),
    );
    final lowStockCount = products.where((p) => p.isLowStock).length;
    final expiredCount = products.where((p) => p.isExpired).length;
    final expiringSoonCount = products.where((p) => p.isExpiringSoon).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header de la sucursal
          InkWell(
            onTap: () => _toggleSucursal(sucursal),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sucursal,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.inventory_2,
                              '${products.length} productos',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              Icons.shopping_cart,
                              '$totalStock unidades',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Alertas de la sucursal
          if (lowStockCount > 0 || expiredCount > 0 || expiringSoonCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  top: BorderSide(color: Colors.orange.shade200),
                  bottom: isExpanded
                      ? BorderSide(color: Colors.grey.shade200)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      children: [
                        if (expiredCount > 0)
                          _buildAlertBadge(
                            '$expiredCount vencidos',
                            Colors.red,
                          ),
                        if (expiringSoonCount > 0)
                          _buildAlertBadge(
                            '$expiringSoonCount por vencer',
                            Colors.orange,
                          ),
                        if (lowStockCount > 0)
                          _buildAlertBadge(
                            '$lowStockCount bajo stock',
                            Colors.orange,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Lista de productos (expandible)
          if (isExpanded)
            Column(
              children: [
                const Divider(height: 1),
                ...products.map((product) => _buildProductItem(product)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle_outline;
    String statusText = 'Disponible';

    if (product.isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Vencido';
    } else if (product.isExpiringSoon) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Por vencer';
    } else if (product.isLowStock) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Bajo stock';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono de estado
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nombre ?? 'Producto sin nombre',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.codigo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Código: ${product.codigo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoBadge(
                      Icons.inventory_2,
                      'Stock: ${product.stock ?? 'N/A'}',
                      Colors.blue,
                    ),
                    if (product.lote != null)
                      _buildInfoBadge(
                        Icons.label,
                        'Lote: ${product.lote}',
                        Colors.grey,
                      ),
                    if (product.fechaCaducidad != null)
                      _buildInfoBadge(
                        Icons.calendar_today,
                        _formatDate(product.fechaCaducidad!),
                        statusColor,
                      ),
                    _buildInfoBadge(
                      statusIcon,
                      statusText,
                      statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

