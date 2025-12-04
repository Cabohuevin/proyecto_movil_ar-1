import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/product_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/inventory_alert.dart';
import 'barcode_product_flow_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductApiService _apiService = ProductApiService();
  List<InventoryAlert> alerts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedAlerts = await _apiService.getInventoryAlerts();
      setState(() {
        alerts = fetchedAlerts;
        isLoading = false;
      });
    } on ApiException catch (e) {
      if (e.isUnauthorized && mounted) {
        // Token expired or invalid, redirect to login
        final authService = AuthService();
        await authService.logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      setState(() {
        errorMessage = 'Error al cargar alertas: ${e.message}';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar alertas: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_pharmacy, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Farmacia",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                  const Text(
                    "Sistema de Inventario",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Gestión inteligente con AR",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Alertas del Inventario",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00695C),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Revisa los productos que requieren atención",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Lista de alertas mejorada ---
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage ?? 'Error desconocido',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadAlerts,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  else if (alerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No hay alertas por ahora",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Todo está en orden",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: alerts.map((alert) {
                        final color = _getAlertColor(alert.tipo);
                        final icon = _getAlertIcon(alert.tipo);
                        final bgColor = color.withOpacity(0.1);
                        final product = alert.product;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (product?.codigo != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            product?.codigo ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      if (product?.codigo != null) const SizedBox(height: 8),
                                      Text(
                                        product?.nombre ?? 'Producto desconocido',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          alert.mensaje,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (product?.lote != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Lote: ${product?.lote ?? ''}",
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // --- Sección inferior: resumen general mejorada ---
                  _buildSummarySection(context),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          "Buscar Producto",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BarcodeProductFlowScreen()),
        ).then((_) => _loadAlerts()), // Refresh alerts after returning
      ),
    );
  }

  Color _getAlertColor(String tipo) {
    switch (tipo) {
      case 'caducidad':
        return Colors.redAccent;
      case 'stock':
        return Colors.orange;
      case 'vencido':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getAlertIcon(String tipo) {
    switch (tipo) {
      case 'caducidad':
        return Icons.access_time_filled;
      case 'stock':
        return Icons.warning_amber_rounded;
      case 'vencido':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildSummarySection(BuildContext context) {
    // Calculate counts from alerts
    final expiringCount = alerts.where((a) => a.tipo == 'caducidad').length;
    final lowStockCount = alerts.where((a) => a.tipo == 'stock').length;
    final expiredCount = alerts.where((a) => a.tipo == 'vencido').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "Resumen del Inventario",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryItem(
            context,
            Icons.access_time_filled,
            "$expiringCount ${expiringCount == 1 ? 'producto' : 'productos'}",
            "Próximos a caducar",
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            context,
            Icons.warning_amber_rounded,
            "$lowStockCount ${lowStockCount == 1 ? 'producto' : 'productos'}",
            "Con bajo stock",
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            context,
            Icons.cancel_outlined,
            "$expiredCount ${expiredCount == 1 ? 'producto' : 'productos'}",
            "Vencidos",
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: " "),
                TextSpan(
                  text: label,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
