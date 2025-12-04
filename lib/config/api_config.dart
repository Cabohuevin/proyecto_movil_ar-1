/// API Configuration
/// 
/// Configuración para diferentes entornos de la API.
/// Cambia el valor de `apiBaseUrl` según tu entorno:
/// 
/// - Producción: 'https://api.codigocreativo.cloud/api'
/// - Local (Emulador Android): 'http://10.0.2.2:PUERTO/api'
/// - Local (iOS Simulator): 'http://localhost:PUERTO/api'
/// - Local (Dispositivo físico): 'http://TU_IP_LOCAL:PUERTO/api'
/// 
/// Para obtener tu IP local en Windows:
/// - Abre PowerShell y ejecuta: ipconfig
/// - Si tu PC está por cable: busca "IPv4 Address" en "Adaptador de Ethernet"
/// - Si tu PC está por Wi-Fi: busca "IPv4 Address" en "Adaptador de LAN inalámbrica Wi-Fi"
/// - Ejemplo: 192.168.1.100
/// 
/// IMPORTANTE: Si usas dispositivo físico, asegúrate de que tu API escuche en 0.0.0.0
/// y no solo en localhost. Ver README_API_LOCAL.md para más detalles.
class ApiConfig {
  // Cambia este valor según tu entorno
  // Por defecto: producción
  static const String apiBaseUrl = 'https://api.codigocreativo.cloud/api';
  
  // Configuraciones predefinidas para desarrollo local (comentadas)
  // Descomenta la que necesites si cambias de entorno
  
  // Para emulador Android (usa 10.0.2.2 para referirse a localhost de tu PC)
  // static const String apiBaseUrl = 'http://10.0.2.2:3000/api';
  
  // Para iOS Simulator (usa localhost directamente)
  // static const String apiBaseUrl = 'http://localhost:3000/api';
  
  // Para dispositivo físico Android/iOS (usa la IP local de tu computadora)
  // Reemplaza 192.168.1.71 con tu IP local y 3000 con el puerto de tu API
  // static const String apiBaseUrl = 'http://192.168.1.71:3000/api';
  
  // Otras IPs disponibles (comentadas):
  // - VirtualBox Host-Only: http://192.168.56.1:3000/api
  
}

