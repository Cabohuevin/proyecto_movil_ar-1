import '../models/product.dart';
import '../models/inventory_alert.dart';
import 'api_service.dart';

/// Product API Service - Extends base API service with product-specific methods
class ProductApiService {
  final ApiService _apiService;

  ProductApiService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get product by code (código)
  Future<Product?> getProductByCode(String codigo) async {
    try {
      final response = await _apiService.get(
        '/productos',
        queryParameters: {'codigo': codigo},
      );

      if (response['data'] != null) {
        final data = response['data'];
        if (data is List && data.isNotEmpty) {
          final firstItem = data.first;
          if (firstItem is Map) {
            return Product.fromJson(firstItem as Map<String, dynamic>);
          }
        } else if (data is Map) {
          return Product.fromJson(data as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching product by code: $e');
      return null;
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _apiService.get('/productos/$id');

      final data = response['data'];
      if (data != null && data is Map) {
        return Product.fromJson(data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  /// Get all products
  /// API uses 'limite' (not 'limit') and 'offset' as query parameters
  /// Example: /api/productos?limite=10&offset=0
  Future<List<Product>> getAllProducts({
    int? limite,
    int? offset,
  }) async {
    try {
      // API requires limite and offset - use defaults if not provided
      final limiteValue = limite ?? 10;
      final offsetValue = offset ?? 0;
      
      final queryParams = <String, dynamic>{
        'limite': limiteValue.toString(),
        'offset': offsetValue.toString(),
      };

      print('🔍 [ProductApiService] Getting all products...');
      print('   Endpoint: /productos');
      print('   Query params: $queryParams');
      print('   limite: $limiteValue');
      print('   offset: $offsetValue');
      
      final response = await _apiService.get(
        '/productos',
        queryParameters: queryParams,
      );
      
      print('✅ [ProductApiService] Response received');
      print('   Response keys: ${response.keys.toList()}');
      print('   Response type: ${response.runtimeType}');

      // Handle different response formats
      List<dynamic>? productsList;
      
      print('   Checking response structure...');
      print('   Has "data" key: ${response.containsKey('data')}');
      print('   Has "results" key: ${response.containsKey('results')}');
      print('   Has "idProducto" key: ${response.containsKey('idProducto')}');
      print('   Has "codigo" key: ${response.containsKey('codigo')}');
      
      if (response['data'] != null) {
        print('   Found "data" field, type: ${response['data'].runtimeType}');
      }
      
      if (response['data'] is List) {
        productsList = response['data'] as List;
        print('   ✅ Found products list in "data" field (${productsList.length} items)');
      } else if (response['results'] is List) {
        productsList = response['results'] as List;
        print('   ✅ Found products list in "results" field (${productsList.length} items)');
      } else if (response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          productsList = data;
          print('   ✅ Found products list in "data" (${productsList.length} items)');
        } else if (data is Map<String, dynamic>) {
          // If data is a single object, wrap it in a list
          productsList = [data];
          print('   ✅ Found single product in "data", wrapped in list');
        }
      } else if (response.containsKey('idProducto') || response.containsKey('codigo')) {
        // If response itself looks like a product, wrap it
        productsList = [response];
        print('   ✅ Response itself is a product, wrapped in list');
      }

      if (productsList != null && productsList.isNotEmpty) {
        print('   📦 Parsing ${productsList.length} products...');
        final parsedProducts = productsList
            .map((item) {
              try {
                if (item is Map) {
                  return Product.fromJson(item as Map<String, dynamic>);
                }
                print('   ⚠️ Item is not a Map: ${item.runtimeType}');
                return null;
              } catch (e) {
                print('   ❌ Error parsing product: $e');
                print('   Item: $item');
                return null;
              }
            })
            .whereType<Product>()
            .toList();
        print('   ✅ Successfully parsed ${parsedProducts.length} products');
        return parsedProducts;
      }

      print('   ⚠️ No products found in response');
      print('   Full response: $response');
      return [];
    } on ApiException catch (e) {
      print('❌ [ProductApiService] ApiException caught');
      print('   Status code: ${e.statusCode}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      
      if (e.isUnauthorized) {
        print('   🔒 Unauthorized - Token inválido o expirado');
        // Token might be invalid, but don't throw to allow UI to handle gracefully
      } else if (e.isNotFound) {
        print('   🔍 Not Found - Endpoint no existe');
      } else if (e.isServerError) {
        print('   🖥️ Server Error - Error en el servidor');
      }
      rethrow; // Re-throw to allow UI to handle
    } catch (e, stackTrace) {
      print('❌ [ProductApiService] Unexpected error');
      print('   Error type: ${e.runtimeType}');
      print('   Error message: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Search products by name or barcode
  Future<List<Product>> searchProducts(String query) async {
    try {
      // Try single parameter search - API might only accept one at a time
      final response = await _apiService.get(
        '/productos',
        queryParameters: {'buscar': query},
      );

      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
  
  /// Get product by barcode (codigoBarras)
  Future<Product?> getProductByBarcode(String codigoBarras) async {
    try {
      final response = await _apiService.get(
        '/productos',
        queryParameters: {'codigoBarras': codigoBarras},
      );

      if (response['data'] != null) {
        final data = response['data'];
        if (data is List && data.isNotEmpty) {
          final firstItem = data.first;
          if (firstItem is Map) {
            return Product.fromJson(firstItem as Map<String, dynamic>);
          }
        } else if (data is Map) {
          return Product.fromJson(data as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching product by barcode: $e');
      return null;
    }
  }

  /// Get inventory alerts
  Future<List<InventoryAlert>> getInventoryAlerts() async {
    try {
      final response = await _apiService.get('/alertas');

      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => InventoryAlert.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // If alerts endpoint doesn't exist, generate from products
      return await _generateAlertsFromProducts();
    } catch (e) {
      print('Error fetching alerts: $e');
      // Fallback: generate alerts from products
      return await _generateAlertsFromProducts();
    }
  }

  /// Generate alerts from products (fallback method)
  Future<List<InventoryAlert>> _generateAlertsFromProducts() async {
    try {
      final products = await getAllProducts();
      final alerts = <InventoryAlert>[];

      for (final product in products) {
        if (product.isExpired || product.isExpiringSoon || product.isLowStock) {
          alerts.add(InventoryAlert.fromProduct(product));
        }
      }

      return alerts;
    } catch (e) {
      print('Error generating alerts: $e');
      return [];
    }
  }

  /// Update product stock
  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      await _apiService.put(
        '/productos/$productId',
        body: {'stock': newStock},
      );
      return true;
    } catch (e) {
      print('Error updating product stock: $e');
      return false;
    }
  }

  /// Create new product
  Future<Product?> createProduct(Product product) async {
    try {
      final response = await _apiService.post(
        '/productos',
        body: product.toJson(),
      );

      if (response['data'] != null) {
        return Product.fromJson(response['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.delete('/productos/$productId');
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  /// Get products by sucursal (branch)
  Future<List<Product>> getProductsBySucursal(String sucursalId) async {
    try {
      final response = await _apiService.get(
        '/productos',
        queryParameters: {'sucursalId': sucursalId},
      );

      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching products by sucursal: $e');
      return [];
    }
  }

  /// Get all sucursales (branches) from products
  Future<Map<String, List<Product>>> getProductsBySucursalGrouped() async {
    try {
      final products = await getAllProducts();
      final grouped = <String, List<Product>>{};

      for (final product in products) {
        final sucursalKey = product.sucursalNombre ?? 
                           product.sucursalId ?? 
                           'Sin Sucursal';
        
        if (!grouped.containsKey(sucursalKey)) {
          grouped[sucursalKey] = [];
        }
        final productList = grouped[sucursalKey];
        if (productList != null) {
          productList.add(product);
        }
      }

      return grouped;
    } catch (e) {
      print('Error grouping products by sucursal: $e');
      return {};
    }
  }
}

