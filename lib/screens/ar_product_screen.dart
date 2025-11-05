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
      appBar: AppBar(title: const Text("Buscar Producto")),
      body: Stack(
        children: [
          ARView(onARViewCreated: _onARViewCreated),

          if (selectedHotspotInfo != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedHotspotInfo!,
                  style: const TextStyle(color: Colors.white),
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

    arSessionManager!.onInitialize(
      handleTaps: true,
      showPlanes: true,
    );

    arObjectManager!.onInitialize();

    arObjectManager!.onNodeTap = _onNodeTap;

    _addProductModel();
  }

  Future<void> _addProductModel() async {
    _productNode = ARNode(
  type: NodeType.webGLB,
  uri: "https://nypecsyxpwpvwlboguut.supabase.co/storage/v1/object/public/models/model1.glb",
  scale: vector.Vector3(0.05, 0.05, 0.05),
  position: vector.Vector3(0.0, 0.0, -1.0),
);

    await arObjectManager!.addNode(_productNode!);
  }

  void _onNodeTap(List<String> nodeNames) {
    debugPrint("Nodo tocado: $nodeNames");

    setState(() {
      selectedHotspotInfo = "PARACETAMOL 500MG";
    });
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}
