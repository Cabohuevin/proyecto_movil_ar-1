import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import '../services/product_api_service.dart';
import '../models/product.dart';

class ARQRScannerScreen extends StatefulWidget {
  const ARQRScannerScreen({super.key});

  @override
  State<ARQRScannerScreen> createState() => _ARQRScannerScreenState();
}

class _ARQRScannerScreenState extends State<ARQRScannerScreen> {
  String? scannedData;
  Product? scannedProduct;
  bool isLoadingProduct = false;
  final ProductApiService _apiService = ProductApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 24),
            const SizedBox(width: 8),
            const Text("Escanear QR de Producto"),
          ],
        ),
      ),
      body: scannedData == null
          ? Stack(
              children: [
                MobileScanner(
                  onDetect: (barcodeCapture) async {
                    final barcode = barcodeCapture.barcodes.first;
                    final rawValue = barcode.rawValue;
                    if (rawValue == null) return;
                    final decoded = Uri.decodeFull(rawValue);
                    debugPrint("QR escaneado: $decoded");

                    // If QR contains uri:, use it directly
                    if (decoded.contains('uri:')) {
                      setState(() {
                        scannedData = decoded;
                        scannedProduct = null;
                      });
                    } else {
                      // Try to fetch product by code from API
                      setState(() {
                        isLoadingProduct = true;
                      });

                      try {
                        final product = await _apiService.getProductByCode(decoded);
                        
                        if (product != null && product.uriModelo3D != null) {
                          setState(() {
                            scannedProduct = product;
                            scannedData = 'uri: "${product.uriModelo3D}"';
                            isLoadingProduct = false;
                          });
                        } else if (product != null) {
                          // Product found but no 3D model
                          setState(() {
                            isLoadingProduct = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Producto encontrado: ${product.nombre ?? decoded}\nNo tiene modelo 3D disponible",
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } else {
                          // Product not found
                          setState(() {
                            isLoadingProduct = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Producto no encontrado. El QR debe contener 'uri:' o un código de producto válido.",
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setState(() {
                          isLoadingProduct = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Error al buscar producto: ${e.toString()}",
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                if (isLoadingProduct)
                  Container(
                    color: Colors.black.withOpacity(0.5),
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
                // Overlay con instrucciones
                Positioned(
                  top: 20,
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
                        const Icon(Icons.qr_code_scanner, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Apunta la cámara al código QR del producto",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Marco de escaneo visual
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Esquinas decorativas
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                                left: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                                right: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                                left: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                                right: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : scannedData != null
              ? ARModelViewer(
                  data: scannedData!,
                  product: scannedProduct,
                )
              : const Center(child: Text('Error: Datos no disponibles')),
    );
  }
}

class ARModelViewer extends StatefulWidget {
  final String data;
  final Product? product;
  const ARModelViewer({
    required this.data,
    this.product,
    super.key,
  });

  @override
  State<ARModelViewer> createState() => _ARModelViewerState();
}

class _ARModelViewerState extends State<ARModelViewer> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  String extractUri(String data) {
    final uriMatch = RegExp(r'uri:\s*"(.+?)"').firstMatch(data);
    return uriMatch?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar, size: 24),
            const SizedBox(width: 8),
            const Text("Visualización AR"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: "Escanear otro QR",
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) async {
              arSessionManager = sessionManager;
              arObjectManager = objectManager;

              if (arSessionManager == null || arObjectManager == null) return;

              arSessionManager!.onInitialize(
                showPlanes: false,
                showWorldOrigin: false,
                handleTaps: true,
              );

              arObjectManager!.onInitialize();

              final node = ARNode(
                type: NodeType.webGLB,
                uri: extractUri(widget.data),
                position: vector.Vector3(0.0, 0.0, -1.0), // Fijo frente a cámara
                scale: vector.Vector3(0.05, 0.05, 0.05),
              );

              await arObjectManager!.addNode(node);
            },
          ),
          // Indicador de carga/éxito
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
                          widget.product?.nombre ?? "Producto cargado",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product != null
                              ? "Stock: ${widget.product?.stock ?? 'N/A'} | Lote: ${widget.product?.lote ?? 'N/A'}"
                              : "Modelo 3D visible en AR",
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

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}
