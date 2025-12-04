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
    if (arObjectManager != null && node != null) {
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
      targetShelf?.lat ?? 0.0,
      targetShelf?.lng ?? 0.0,
    );
    setState(() {
      distanceToTarget = distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 24),
            const SizedBox(width: 8),
            const Text("Modo Test AR"),
          ],
        ),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (ARSessionManager sessionManager,
                ARObjectManager objectManager,
                ARAnchorManager anchorManager,
                ARLocationManager locationManager) {
              arSessionManager = sessionManager;
              arObjectManager = objectManager;

              if (arSessionManager == null || arObjectManager == null) return;

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

                if (arObjectManager != null) {
                  await arObjectManager!.addNode(marker);
                }
              };
            },
          ),

          // Indicador de distancia mejorado
          if (distanceToTarget != null)
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
                        Icons.straighten_rounded,
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
                            "${(distanceToTarget ?? 0.0).toStringAsFixed(1)} metros",
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

          // Panel de controles mejorado
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Instrucciones
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Toca un plano para registrar una estantería",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de actualizar
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Position user = await Geolocator.getCurrentPosition();
                        _updateDistance(user);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.refresh, color: Colors.white),
                                SizedBox(width: 8),
                                Text("Distancia actualizada"),
                              ],
                            ),
                            backgroundColor: Theme.of(context).primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Actualizar Distancia",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
