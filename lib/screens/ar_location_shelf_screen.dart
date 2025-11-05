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
  const ARLocationShelfScreen({super.key});

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

    double lat = double.parse(match.group(1)!);
    double lng = double.parse(match.group(2)!);

    _locateShelf({
      "name": "📍 Estantería (QR)",
      "lat": lat,
      "lng": lng,
    });
  }

  void _showShelfList() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: savedShelves.length,
        itemBuilder: (context, i) {
          final shelf = savedShelves[i];
          return ListTile(
            title: Text(shelf["name"]),
            subtitle: Text("Lat: ${shelf["lat"]} | Lng: ${shelf["lng"]}"),
            trailing: const Icon(Icons.navigation),
            onTap: () {
              Navigator.pop(context);
              _locateShelf(shelf);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!scanning && !locating) {
      return Scaffold(
        appBar: AppBar(title: const Text("Estanterías")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_location),
                label: const Text("Registrar Estantería (AR)"),
                onPressed: () async {
                  Position user = await Geolocator.getCurrentPosition();
                  _registerShelfAtAR(user);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text("Ver Estanterías"),
                onPressed: savedShelves.isEmpty ? null : _showShelfList,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Escanear Estantería"),
                onPressed: () => setState(() => scanning = true),
              ),
            ],
          ),
        ),
      );
    }

    if (scanning) {
      return Scaffold(
        appBar: AppBar(title: const Text("Escaneando QR...")),
        body: MobileScanner(
          onDetect: (barcodeCapture) {
            final code = barcodeCapture.barcodes.first.rawValue;
            if (code != null) _processQR(code);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Vista AR")),
      body: Stack(
        children: [
          ArLocationWidget(
            annotations: annotations,
            annotationViewerBuilder: (context, annotation) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                annotation.uid,
                style: const TextStyle(color: Colors.white),
              ),
            ), onLocationChange: (Position position) {  },
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
        ],
      ),
    );
  }
}
