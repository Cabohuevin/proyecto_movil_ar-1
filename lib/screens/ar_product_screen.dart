import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';

class ARProductScreen extends StatefulWidget {
  const ARProductScreen({super.key});

  @override
  State<ARProductScreen> createState() => _ARProductScreenState();
}

class _ARProductScreenState extends State<ARProductScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  ARNode? _productNode;
  String? selectedHotspotInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar, size: 24),
            const SizedBox(width: 8),
            const Text("Visualización AR 3D"),
          ],
        ),
      ),
      body: Stack(
        children: [
          ARView(onARViewCreated: _onARViewCreated),

          // Información del producto mejorada
          if (selectedHotspotInfo != null)
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
                        Icons.medication_liquid,
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
                            selectedHotspotInfo ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00695C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Toca el modelo para más información",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          selectedHotspotInfo = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Instrucciones en la parte inferior
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

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    if (arSessionManager == null || arObjectManager == null) return;

    arSessionManager!.onInitialize(
      handleTaps: true,
      showPlanes: true,
    );

    arObjectManager!.onInitialize();

    arObjectManager!.onNodeTap = _onNodeTap;

    _addProductModel();
  }

  Future<void> _addProductModel() async {
    if (arObjectManager == null) return;
    
    _productNode = ARNode(
      type: NodeType.webGLB,
      uri: "https://nypecsyxpwpvwlboguut.supabase.co/storage/v1/object/public/models/model1.glb",
      scale: vector.Vector3(0.05, 0.05, 0.05),
      position: vector.Vector3(0.0, 0.0, -1.0),
    );

    if (_productNode != null) {
      await arObjectManager!.addNode(_productNode!);
    }
  }

  void _onNodeTap(List<String> nodeNames) {
    debugPrint("Nodo tocado: $nodeNames");

    setState(() {
      selectedHotspotInfo = "PARACETAMOL 500MG";
    });
    
    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Producto seleccionado"),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}
