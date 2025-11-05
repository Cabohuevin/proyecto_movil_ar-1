import 'package:flutter/material.dart';
import 'ar_location_shelf_screen.dart';
import 'ar_product_screen.dart';
import 'qr_product_screen.dart'; // <-- importa tu pantalla de QR
import 'test_doble_ar.dart';
class ARSelectorScreen extends StatelessWidget {
  const ARSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona Modo AR")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARLocationShelfScreen()),
              ),
              child: const Text("Buscar Estantería (GPS AR)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARProductScreen()),
              ),
              child: const Text("Buscar Producto (AR 3D)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARQRScannerScreen()),
              ),
              child: const Text("Buscar Producto con QR"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARShelfScreen()),
              ),
              child: const Text("Buscar Producto con QR"),
            ),
          ],
        ),
      ),
    );
  }
}
