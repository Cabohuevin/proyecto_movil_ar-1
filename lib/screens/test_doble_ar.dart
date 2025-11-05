import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ShelfPOI extends ARNode {
  final double lat;
  final double lng;

  ShelfPOI({
    required String name,
    required this.lat,
    required this.lng,
  }) : super(
          type: NodeType.localGLTF2, // Cambiado según nueva versión
          uri: '../assets/models/sphere.glb', // Necesario
          scale: vector.Vector3(0.1, 0.1, 0.1),
          position: vector.Vector3(0, 0, 0),
        );
}


class ARShelfScreen extends StatefulWidget {
  const ARShelfScreen({super.key});

  @override
  State<ARShelfScreen> createState() => _ARShelfScreenState();
}

class _ARShelfScreenState extends State<ARShelfScreen> {
  List<Map<String, dynamic>> savedShelves = [];
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  double? distanceToTarget;
  ShelfPOI? targetShelf;

  @override
  void initState() {
    super.initState();
    _loadSavedShelves();
  }

  Future<void> _loadSavedShelves() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList("shelves");
    if (saved == null) return;

    savedShelves = saved
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(jsonDecode(e)))
        .toList();
    setState(() {});
  }

  Future<void> _registerShelfAtAR(
      Position user, double deltaX, double deltaZ) async {
    double metersPerLat = 111111;
    double metersPerLng = 111111 * cos(user.latitude * pi / 180);

    double lat = user.latitude + (deltaZ / metersPerLat);
    double lng = user.longitude + (deltaX / metersPerLng);

    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("shelves") ?? [];

    String name = "📦 Estantería ${saved.length + 1}";
    final shelf = {"name": name, "lat": lat, "lng": lng};
    saved.add(jsonEncode(shelf));

    await prefs.setStringList("shelves", saved);

    final node = ShelfPOI(name: name, lat: lat, lng: lng);
    if (arObjectManager != null) {
      await arObjectManager!.addNode(node);
    }

    setState(() {
      savedShelves.add(shelf);
      targetShelf = node;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("✅ Guardado: $name")));
  }

  void _updateDistance(Position user) {
    if (targetShelf == null) return;
    double distance = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      targetShelf!.lat,
      targetShelf!.lng,
    );
    setState(() {
      distanceToTarget = distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AR Estanterías")),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager) {
  arSessionManager = sessionManager;
  arObjectManager = objectManager;

  /// ✅ Tocar el plano para guardar la estantería
  arSessionManager!.onPlaneOrPointTap = (hitResults) async {
  if (hitResults.isEmpty) return;

  final hit = hitResults.first;
  Position user = await Geolocator.getCurrentPosition();

  vector.Vector3 translation = hit.worldTransform.getTranslation();

  await _registerShelfAtAR(user, translation.x, translation.z);

  // Marcador visual simple
  final marker = ARNode(
    type: NodeType.localGLTF2,
    uri: '../assets/models/',
    scale: vector.Vector3(0.1, 0.1, 0.1),
    position: translation,
  );
        
  await arObjectManager!.addNode(marker);
};

    },
          ),

          if (distanceToTarget != null)
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Distancia: ${distanceToTarget!.toStringAsFixed(1)} m",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: ElevatedButton(
              child: const Text("Actualizar distancia"),
              onPressed: () async {
                Position user = await Geolocator.getCurrentPosition();
                _updateDistance(user);
              },
            ),
          ),
        ],
      ),
    );
  }
}
