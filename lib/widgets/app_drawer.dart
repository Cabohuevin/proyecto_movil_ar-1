import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/ar_location_shelf_screen.dart';
import '../screens/ar_product_screen.dart';
import '../screens/qr_product_screen.dart';
import '../screens/test_doble_ar.dart';
import '../screens/barcode_product_flow_screen.dart';
import '../screens/products_by_sucursal_screen.dart';
import '../screens/products_list_screen.dart';
import '../screens/almacenes_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header mejorado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sistema de Inventario",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Farmacia AR",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_rounded,
                  title: "Inicio",
                  subtitle: "Panel principal",
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2,
                  title: "Lista de Productos",
                  subtitle: "Ver y buscar productos",
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductsListScreen(),
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.store,
                  title: "Productos por Sucursal",
                  subtitle: "Ver inventario por sucursal",
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductsBySucursalScreen(),
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.warehouse,
                  title: "Almacenes",
                  subtitle: "Gestionar almacenes",
                  color: Colors.brown,
                  onTap: () {
                    // Navigate to almacenes screen - user must select an almacén first
                    // Import needed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AlmacenesScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    "Realidad Aumentada",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.location_on_rounded,
                  title: "Estantería (GPS AR)",
                  subtitle: "Ubicar estanterías guardadas",
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ARLocationShelfScreen(),
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: "Producto (AR 3D)",
                  subtitle: "Visualización 3D en AR",
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ARProductScreen()),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  title: "Producto con QR",
                  subtitle: "Escanear para localizar",
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ARQRScannerScreen(),
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: "Buscar Producto",
                  subtitle: "Escanear código de barras y guiar",
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeProductFlowScreen(),
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  icon: Icons.construction_rounded,
                  title: "Modo Test AR",
                  subtitle: "Guardar y ubicar en AR",
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ARShelfScreen()),
                  ),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                _buildDrawerItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: "Cerrar Sesión",
                  subtitle: "Salir de la aplicación",
                  color: Colors.red,
                  onTap: () async {
                    final authService = AuthService();
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Theme.of(context).primaryColor;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: itemColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: itemColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
