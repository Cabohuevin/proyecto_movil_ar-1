import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';

class ARQRScannerScreen extends StatefulWidget {
  const ARQRScannerScreen({super.key});

  @override
  State<ARQRScannerScreen> createState() => _ARQRScannerScreenState();
}

class _ARQRScannerScreenState extends State<ARQRScannerScreen> {
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear QR")),
      body: scannedData == null
          ? MobileScanner(
              onDetect: (barcodeCapture) {
                final barcode = barcodeCapture.barcodes.first;
                if (barcode.rawValue == null) return;
                final decoded = Uri.decodeFull(barcode.rawValue!);
                debugPrint("QR escaneado: $decoded");

                if (decoded.contains('uri:')) {
                  setState(() {
                    scannedData = decoded;
                  });
                }
              },
            )
          : ARModelViewer(data: scannedData!),
    );
  }
}

class ARModelViewer extends StatefulWidget {
  final String data;
  const ARModelViewer({required this.data, super.key});

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
      appBar: AppBar(title: const Text("AR Producto")),
      body: ARView(
        onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) async {
          arSessionManager = sessionManager;
          arObjectManager = objectManager;

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
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}
