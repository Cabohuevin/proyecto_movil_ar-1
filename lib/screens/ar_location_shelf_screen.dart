import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ar_location_viewer/ar_location_viewer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShelfPOI extends ArAnnotation {
  ShelfPOI({required super.uid, required super.position});
}

class ARLocationShelfScreen extends StatefulWidget {
  final Map<String, dynamic>? initialShelf;
  
  const ARLocationShelfScreen({
    super.key,
    this.initialShelf,
  });

  @override
  State<ARLocationShelfScreen> createState() => _ARLocationShelfScreenState();
}

class _ARLocationShelfScreenState extends State<ARLocationShelfScreen> {
  List<Map<String, dynamic>> savedShelves = [];
  List<ArAnnotation> annotations = [];
  double? distanceToTarget;

  bool scanning = false;
  bool locating = false;

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    _loadSavedShelves();
    
    // Si se pasa una estantería inicial, localizarla automáticamente
    if (widget.initialShelf != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _locateShelf(widget.initialShelf!);
      });
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedShelves() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList("shelves");
    if (saved == null) return;

    savedShelves = saved.map<Map<String, dynamic>>(
      (e) => Map<String, dynamic>.from(jsonDecode(e)),
    ).toList();

    setState(() {});
  }

  void _startDistanceUpdates() {
    positionStream?.cancel();

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      if (!mounted || annotations.isEmpty) return;

      final target = annotations.first.position;

      setState(() {
        distanceToTarget = Geolocator.distanceBetween(
          pos.latitude, pos.longitude,
          target.latitude, target.longitude,
        );
      });
    });
  }

  Future<void> _registerShelfAtAR(Position user) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("shelves") ?? [];

    String name = "📦 Estantería ${saved.length + 1}";

    final shelf = {
      "name": name,
      "lat": user.latitude,
      "lng": user.longitude,
    };

    saved.add(jsonEncode(shelf));
    await prefs.setStringList("shelves", saved);
    _loadSavedShelves();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Guardado: $name")),
    );

    setState(() {
      annotations = [
        ShelfPOI(
          uid: name,
          position: user,
        )
      ];
      locating = true;
      scanning = false;
    });

    _startDistanceUpdates();
  }

  void _locateShelf(Map<String, dynamic> shelf) async {
    Position user = await Geolocator.getCurrentPosition();

    setState(() {
      scanning = false;
      locating = true;
      annotations = [
        ShelfPOI(
          uid: shelf["name"],
          position: Position(
            latitude: shelf["lat"],
            longitude: shelf["lng"],
            altitude: user.altitude,
            accuracy: 1,
            heading: 0,
            speed: 0,
            timestamp: DateTime.now(), altitudeAccuracy: 5, headingAccuracy: 5, speedAccuracy: 5,
          ),
        ),
      ];
    });

    _startDistanceUpdates();
  }

  void _processQR(String data) {
    String decoded = Uri.decodeFull(data).trim();
    final match = RegExp(
      r'lat:\s*(-?\d+\.\d+)\s*,\s*lng:\s*(-?\d+\.\d+)'
    ).firstMatch(decoded);

    if (match == null) return;

    final latStr = match.group(1);
    final lngStr = match.group(2);
    
    if (latStr == null || lngStr == null) return;

    double lat = double.parse(latStr);
    double lng = double.parse(lngStr);

    _locateShelf({
      "name": "📍 Estantería (QR)",
      "lat": lat,
      "lng": lng,
    });
  }

  void _showShelfList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.warehouse_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Estanterías Guardadas",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: savedShelves.length,
                itemBuilder: (context, i) {
                  final shelf = savedShelves[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.warehouse_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        shelf["name"],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Lat: ${shelf["lat"].toStringAsFixed(6)}\nLng: ${shelf["lng"].toStringAsFixed(6)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _locateShelf(shelf);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? color.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: enabled
                        ? color.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? color : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: enabled ? Colors.black87 : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: enabled
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: enabled ? color : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!scanning && !locating) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 24),
              const SizedBox(width: 8),
              const Text("Gestión de Estanterías"),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header informativo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warehouse_rounded,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Localización GPS con AR",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Registra y localiza estanterías en tu farmacia",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón registrar
              _buildActionButton(
                context,
                icon: Icons.add_location_alt_rounded,
                title: "Registrar Estantería",
                subtitle: "Guarda la ubicación actual con GPS",
                color: Theme.of(context).primaryColor,
                onPressed: () async {
                  Position user = await Geolocator.getCurrentPosition();
                  _registerShelfAtAR(user);
                },
              ),
              const SizedBox(height: 16),

              // Botón ver lista
              _buildActionButton(
                context,
                icon: Icons.list_alt_rounded,
                title: "Ver Estanterías Guardadas",
                subtitle: "${savedShelves.length} estanterías registradas",
                color: Colors.blue,
                enabled: savedShelves.isNotEmpty,
                onPressed: savedShelves.isEmpty ? null : _showShelfList,
              ),
              const SizedBox(height: 16),

              // Botón escanear QR
              _buildActionButton(
                context,
                icon: Icons.qr_code_scanner_rounded,
                title: "Escanear Código QR",
                subtitle: "Localiza estantería desde QR",
                color: Colors.green,
                onPressed: () => setState(() => scanning = true),
              ),
            ],
          ),
        ),
      );
    }

    if (scanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Escaneando QR"),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => scanning = false),
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (barcodeCapture) {
                final code = barcodeCapture.barcodes.first.rawValue;
                if (code != null) _processQR(code);
              },
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
                        "Apunta la cámara al código QR de la estantería",
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
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista AR - Navegación"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              locating = false;
              annotations = [];
              distanceToTarget = null;
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          ArLocationWidget(
            annotations: annotations,
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
          ),
        ],
      ),
    );
  }
}
