import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ar_location_viewer/ar_location_viewer.dart';
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../models/product.dart';
import '../services/product_api_service.dart';

enum FlowState {
  scanning,
  productInfo,
  navigating,
  viewingAR,
}

class ShelfPOI extends ArAnnotation {
  ShelfPOI({required super.uid, required super.position});
}

class BarcodeProductFlowScreen extends StatefulWidget {
  const BarcodeProductFlowScreen({super.key});

  @override
  State<BarcodeProductFlowScreen> createState() => _BarcodeProductFlowScreenState();
}

class _BarcodeProductFlowScreenState extends State<BarcodeProductFlowScreen> {
  final ProductApiService _apiService = ProductApiService();
  
  FlowState _currentState = FlowState.scanning;
  Product? _scannedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  
  // AR Navigation
  List<ArAnnotation> _annotations = [];
  double? _distanceToTarget;
  StreamSubscription<Position>? _positionStream;
  
  // AR Product View
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;

  @override
  void dispose() {
    _positionStream?.cancel();
    _arSessionManager?.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _apiService.getProductByCode(barcode);
      
      if (product != null) {
        setState(() {
          _scannedProduct = product;
          _currentState = FlowState.productInfo;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Producto no encontrado con código: $barcode';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar producto: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startNavigation() {
    final product = _scannedProduct;
    if (product == null || !product.hasShelfLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto no tiene ubicación de estantería registrada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _initializeNavigation();
  }

  void _initializeNavigation() async {
    final product = _scannedProduct;
    if (product == null) return;
    
    final estanteriaLat = product.estanteriaLat;
    final estanteriaLng = product.estanteriaLng;
    if (estanteriaLat == null || estanteriaLng == null) {
      return;
    }
    
    final userPosition = await Geolocator.getCurrentPosition();

    setState(() {
      _annotations = [
        ShelfPOI(
          uid: product.estanteriaNombre ?? 'Estantería del Producto',
          position: Position(
            latitude: estanteriaLat,
            longitude: estanteriaLng,
            altitude: userPosition.altitude,
            accuracy: 1,
            heading: 0,
            speed: 0,
            timestamp: DateTime.now(),
            altitudeAccuracy: 5,
            headingAccuracy: 5,
            speedAccuracy: 5,
          ),
        ),
      ];
      _currentState = FlowState.navigating;
    });

    _startDistanceUpdates();
  }

  void _startDistanceUpdates() {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      if (!mounted || _annotations.isEmpty) return;

      final target = _annotations.first.position;

      setState(() {
        _distanceToTarget = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          target.latitude,
          target.longitude,
        );
      });
    });
  }

  void _onArrived() {
    _positionStream?.cancel();
    setState(() {
      _currentState = FlowState.viewingAR;
    });
  }

  void _resetFlow() {
    _positionStream?.cancel();
    setState(() {
      _currentState = FlowState.scanning;
      _scannedProduct = null;
      _annotations = [];
      _distanceToTarget = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case FlowState.scanning:
        return _buildScanningView();
      case FlowState.productInfo:
        return _buildProductInfoView();
      case FlowState.navigating:
        return _buildNavigationView();
      case FlowState.viewingAR:
        return _buildARProductView();
    }
  }

  Widget _buildScanningView() {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 24),
            SizedBox(width: 8),
            Text("Escanear Código de Barras"),
          ],
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (barcodeCapture) {
              if (barcodeCapture.barcodes.isEmpty) return;
              final barcode = barcodeCapture.barcodes.first;
              final rawValue = barcode.rawValue;
              if (rawValue != null && !_isLoading) {
                _scanBarcode(rawValue);
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Buscando producto...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage ?? 'Error desconocido',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          // Overlay con instrucciones
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Apunta la cámara al código de barras del producto",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoView() {
    final product = _scannedProduct;
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Producto no disponible')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Información del Producto"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFlow,
            tooltip: "Escanear otro producto",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal del producto
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication_liquid,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nombre ?? 'Producto sin nombre',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00695C),
                              ),
                            ),
                            if (product.codigo != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Código: ${product.codigo}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (product.descripcion != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      product.descripcion ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Información detallada
            _buildInfoCard(
              icon: Icons.inventory_2,
              title: 'Stock',
              value: '${product.stock ?? 'N/A'} unidades',
              color: product.isLowStock ? Colors.orange : Colors.green,
            ),
            
            if (product.lote != null) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.label,
                title: 'Lote',
                value: product.lote ?? '',
                color: Colors.blue,
              ),
            ],
            
            if (product.fechaCaducidad != null) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: product.isExpired
                    ? Icons.cancel
                    : product.isExpiringSoon
                        ? Icons.warning
                        : Icons.calendar_today,
                title: 'Fecha de Caducidad',
                value: product.fechaCaducidad != null 
                    ? _formatDate(product.fechaCaducidad!)
                    : 'N/A',
                color: product.isExpired
                    ? Colors.red
                    : product.isExpiringSoon
                        ? Colors.orange
                        : Colors.green,
              ),
            ],
            
            if (product.hasShelfLocation) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.warehouse,
                title: 'Ubicación',
                value: product.estanteriaNombre ?? 'Estantería registrada',
                color: Theme.of(context).primaryColor,
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Botón para guiar a estantería
            if (product.hasShelfLocation)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNavigation,
                  icon: const Icon(Icons.navigation, size: 28),
                  label: const Text(
                    "Guíame a la Estantería",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este producto no tiene ubicación de estantería registrada',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navegación AR"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _positionStream?.cancel();
              setState(() {
                _currentState = FlowState.productInfo;
                _annotations = [];
                _distanceToTarget = null;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ArLocationWidget(
            annotations: _annotations,
            annotationViewerBuilder: (context, annotation) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warehouse_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    annotation.uid,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            onLocationChange: (Position position) {},
          ),
          
          // Indicador de distancia
          if (_distanceToTarget != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.navigation_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Distancia a la estantería",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(_distanceToTarget ?? 0.0).toStringAsFixed(1)} metros",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00695C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Botón "Llegué"
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _onArrived,
                    icon: const Icon(Icons.check_circle, size: 28),
                    label: const Text(
                      "Llegué a la Estantería",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mueve tu dispositivo para ver la dirección de la estantería",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARProductView() {
    final product = _scannedProduct;
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Producto no disponible')),
      );
    }
    final modelUri = product.uriModelo3D;

    if (modelUri == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Visualización AR"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Este producto no tiene modelo 3D disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _resetFlow,
                icon: const Icon(Icons.refresh),
                label: const Text("Escanear otro producto"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visualización AR del Producto"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFlow,
            tooltip: "Escanear otro producto",
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) async {
              _arSessionManager = sessionManager;
              _arObjectManager = objectManager;

              if (_arSessionManager == null || _arObjectManager == null) return;

              _arSessionManager!.onInitialize(
                showPlanes: false,
                showWorldOrigin: false,
                handleTaps: true,
              );

              _arObjectManager!.onInitialize();

              final node = ARNode(
                type: NodeType.webGLB,
                uri: modelUri,
                position: vector.Vector3(0.0, 0.0, -1.0),
                scale: vector.Vector3(0.05, 0.05, 0.05),
              );

              await _arObjectManager!.addNode(node);
            },
          ),
          
          // Información del producto
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nombre ?? 'Producto',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Modelo 3D visible en AR",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrucciones
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Apunta la cámara a una superficie plana para visualizar el producto",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
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

