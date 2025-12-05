import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import '../models/product.dart';

class ARQRScannerScreen extends StatefulWidget {
  const ARQRScannerScreen({super.key});

  @override
  State<ARQRScannerScreen> createState() => _ARQRScannerScreenState();
}

class _ARQRScannerScreenState extends State<ARQRScannerScreen> {
  static const String _defaultModelData =
      'uri: "https://nypecsyxpwpvwlboguut.supabase.co/storage/v1/object/public/models/model1.glb"';

  @override
  Widget build(BuildContext context) {
    return const ARModelViewer(
      data: _defaultModelData,
      product: null,
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
  ARNode? _activeNode;
  String? _activeCategory;

  static const String _fallbackModelUri =
      'https://nypecsyxpwpvwlboguut.supabase.co/storage/v1/object/public/models/model1.glb';

  final List<String> _modelCategories = const [
    'Antibióticos',
    'Solubles',
    'Analgésicos',
    'Vitaminas',
    'Antiinflamatorios',
  ];

  String extractUri(String data) {
    final uriMatch = RegExp(r'uri:\s*"(.+?)"').firstMatch(data);
    return uriMatch?.group(1) ?? '';
  }

  Future<void> _placeModel(String category, {String? uri}) async {
    if (arObjectManager == null) return;

    final resolvedUri = (uri != null && uri.isNotEmpty)
        ? uri
        : (extractUri(widget.data).isNotEmpty
            ? extractUri(widget.data)
            : _fallbackModelUri);

    if (_activeNode != null) {
      await arObjectManager!.removeNode(_activeNode!);
    }

    final node = ARNode(
      name: 'modelo-$category',
      type: NodeType.webGLB,
      uri: resolvedUri,
      position: vector.Vector3(0.0, 0.0, -1.0), // Frente a la cámara
      scale: vector.Vector3(0.05, 0.05, 0.05),
    );

    final added = await arObjectManager!.addNode(node);
    if (added == true) {
      setState(() {
        _activeNode = node;
        _activeCategory = category;
      });
    }
  }

  Widget _buildCategorySelector() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_list, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                "Ordenar estantería",
                style: TextStyle(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modelCategories.map((category) {
              final isActive = _activeCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isActive,
                onSelected: (_) => _placeModel(category, uri: _fallbackModelUri),
                selectedColor: Colors.teal.shade100,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isActive ? Colors.teal.shade800 : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isActive ? Colors.teal : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
          PopupMenuButton<String>(
            tooltip: "Ordenar estantería",
            icon: const Icon(Icons.view_list),
            onSelected: (value) {
              _placeModel(value, uri: _fallbackModelUri);
            },
            itemBuilder: (context) => _modelCategories
                .map(
                  (category) => PopupMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        const Icon(Icons.medication_liquid, size: 20),
                        const SizedBox(width: 10),
                        Text(category),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: "Volver",
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

              final initialUri =
                  extractUri(widget.data).isNotEmpty ? extractUri(widget.data) : _fallbackModelUri;
              await _placeModel(_activeCategory ?? 'Modelo', uri: initialUri);
            },
          ),
          // Selector rápido para tipos de medicamento
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCategorySelector(),
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
                          widget.product?.nombre ??
                              (_activeCategory != null ? "Modelo: $_activeCategory" : "Producto cargado"),
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
                      "Apunta la cámara a una superficie plana para visualizar el modelo",
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
