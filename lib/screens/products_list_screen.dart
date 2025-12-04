import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ProductApiService _productApiService = ProductApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterType = 'nombre'; // 'nombre' or 'codigoBarras'

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productApiService.getAllProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (e.isUnauthorized && mounted) {
        final authService = AuthService();
        await authService.logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar productos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
      return;
    }

    setState(() {
      if (_filterType == 'nombre') {
        _filteredProducts = _allProducts.where((product) {
          final nombre = product.nombre?.toLowerCase() ?? '';
          return nombre.contains(query);
        }).toList();
      } else {
        // Filter by codigoBarras
        _filteredProducts = _allProducts.where((product) {
          final codigoBarras = product.codigoBarras?.toLowerCase() ?? '';
          final codigo = product.codigo?.toLowerCase() ?? '';
          return codigoBarras.contains(query) || codigo.contains(query);
        }).toList();
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(Product product) {
    if (product.isExpired) return Colors.red;
    if (product.isExpiringSoon) return Colors.orange;
    if (product.isLowStock) return Colors.amber;
    return Colors.green;
  }

  IconData _getStatusIcon(Product product) {
    if (product.isExpired) return Icons.cancel;
    if (product.isExpiringSoon) return Icons.warning;
    if (product.isLowStock) return Icons.inventory_2;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filter
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
            child: Column(
              children: [
                // Filter type selector
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'nombre',
                            label: Text('Nombre'),
                            icon: Icon(Icons.text_fields, size: 18),
                          ),
                          ButtonSegment(
                            value: 'codigoBarras',
                            label: Text('Código'),
                            icon: Icon(Icons.qr_code, size: 18),
                          ),
                        ],
                        selected: {_filterType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _filterType = newSelection.first;
                            _onSearchChanged();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _filterType == 'nombre' 
                        ? 'Buscar por nombre...' 
                        : 'Buscar por código de barras...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          
          // Results count
          if (_filteredProducts.isNotEmpty || _searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Text(
                    '${_filteredProducts.length} producto${_filteredProducts.length != 1 ? 's' : ''} encontrado${_filteredProducts.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? 'Error desconocido',
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.inventory_2_outlined
                                      : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No hay productos disponibles'
                                      : 'No se encontraron productos',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final statusColor = _getStatusColor(product);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () {
                                      // Show product details in a dialog or navigate
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(product.nombre ?? 'Producto'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (product.codigo != null)
                                                  Text('Código: ${product.codigo}'),
                                                if (product.codigoBarras != null)
                                                  Text('Código de Barras: ${product.codigoBarras}'),
                                                if (product.descripcion != null)
                                                  Text('Descripción: ${product.descripcion}'),
                                                if (product.stock != null)
                                                  Text('Stock: ${product.stock}'),
                                                if (product.lote != null)
                                                  Text('Lote: ${product.lote}'),
                                                if (product.fechaCaducidad != null)
                                                  Text('Caducidad: ${_formatDate(product.fechaCaducidad)}'),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cerrar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header with name and status
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.nombre ?? 'Sin nombre',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: statusColor.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _getStatusIcon(product),
                                                      size: 16,
                                                      color: statusColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      product.isExpired
                                                          ? 'Vencido'
                                                          : product.isExpiringSoon
                                                              ? 'Por vencer'
                                                              : product.isLowStock
                                                                  ? 'Bajo stock'
                                                                  : 'OK',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: statusColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Code and barcode
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              if (product.codigo != null)
                                                _buildInfoChip(
                                                  Icons.tag,
                                                  'Código: ${product.codigo}',
                                                  Colors.blue,
                                                ),
                                              if (product.codigoBarras != null)
                                                _buildInfoChip(
                                                  Icons.qr_code,
                                                  'Barras: ${product.codigoBarras}',
                                                  Colors.purple,
                                                ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Stock and description
                                          Row(
                                            children: [
                                              if (product.stock != null)
                                                _buildInfoChip(
                                                  Icons.inventory_2,
                                                  'Stock: ${product.stock}',
                                                  Colors.green,
                                                ),
                                              if (product.lote != null)
                                                _buildInfoChip(
                                                  Icons.label,
                                                  'Lote: ${product.lote}',
                                                  Colors.grey,
                                                ),
                                            ],
                                          ),
                                          
                                          if (product.fechaCaducidad != null) ...[
                                            const SizedBox(height: 8),
                                            _buildInfoChip(
                                              product.isExpired
                                                  ? Icons.cancel
                                                  : product.isExpiringSoon
                                                      ? Icons.warning
                                                      : Icons.calendar_today,
                                              'Caducidad: ${_formatDate(product.fechaCaducidad)}',
                                              statusColor,
                                            ),
                                          ],
                                          
                                          if (product.descripcion != null && product.descripcion!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              product.descripcion!,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          
                                          if (product.hasShelfLocation) ...[
                                            const SizedBox(height: 8),
                                            _buildInfoChip(
                                              Icons.location_on,
                                              'Estantería: ${product.estanteriaNombre ?? "Registrada"}',
                                              Colors.teal,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

