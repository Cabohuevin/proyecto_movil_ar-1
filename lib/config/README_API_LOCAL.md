# Cómo usar una API local en tu app Flutter

## Configuración rápida

1. Abre el archivo `lib/config/api_config.dart`
2. Cambia el valor de `apiBaseUrl` según tu entorno

## Configuraciones según el dispositivo

### 📱 Emulador Android
```dart
static const String apiBaseUrl = 'http://10.0.2.2:3000/api';
```
- `10.0.2.2` es la dirección especial que el emulador Android usa para referirse a `localhost` de tu computadora
- Reemplaza `3000` con el puerto donde corre tu API local

### 🍎 iOS Simulator
```dart
static const String apiBaseUrl = 'http://localhost:3000/api';
```
- iOS Simulator puede usar `localhost` directamente
- Reemplaza `3000` con el puerto donde corre tu API local

### 📲 Dispositivo físico (Android/iOS)
```dart
static const String apiBaseUrl = 'http://192.168.1.100:3000/api';
```
- Necesitas la IP local de tu computadora
- Reemplaza `192.168.1.100` con tu IP local
- Reemplaza `3000` con el puerto donde corre tu API local

### 🔌 PC por cable + Teléfono por Wi-Fi
**¡SÍ, funciona!** Si tu PC está conectada por cable Ethernet y tu teléfono por Wi-Fi:
- ✅ Ambos deben estar conectados al **mismo router** (misma red)
- ✅ Usa la IP de tu PC (la del adaptador Ethernet, no Wi-Fi)
- ✅ Configura tu API para escuchar en `0.0.0.0` (todas las interfaces) en lugar de solo `localhost`

## Cómo obtener tu IP local

### Windows (PC conectada por cable)
1. Abre PowerShell o CMD
2. Ejecuta: `ipconfig`
3. Busca la sección **"Adaptador de Ethernet"** o **"Ethernet adapter"**
4. Busca **"IPv4 Address"** en esa sección (NO en la sección de Wi-Fi)
5. Ejemplo: `192.168.1.100`
6. **Esa es la IP que debes usar en tu app**

**Ejemplo de salida de `ipconfig`:**
```
Adaptador de Ethernet Ethernet:

   Dirección IPv4. . . . . . . . . . . . . . : 192.168.1.100    ← USA ESTA IP
   Máscara de subred . . . . . . . . . . . . : 255.255.255.0
   Puerta de enlace predeterminada . . . . . : 192.168.1.1

Adaptador de LAN inalámbrica Wi-Fi:

   Dirección IPv4. . . . . . . . . . . . . . : 192.168.1.101    ← NO esta (si tu PC no usa Wi-Fi)
```

### macOS/Linux
1. Abre Terminal
2. Ejecuta: `ifconfig` (macOS/Linux) o `ip addr` (Linux)
3. Busca la IP en tu adaptador de red activo

## Asegúrate de que tu API local esté accesible

### 1. Verifica que tu API esté corriendo
- Tu servidor debe estar ejecutándose en el puerto que especificaste
- Ejemplo: Si tu API corre en `http://localhost:3000`, usa el puerto `3000`

### 2. Configura CORS (si es necesario)
Si tu API tiene CORS habilitado, asegúrate de permitir solicitudes desde tu app:
```javascript
// Ejemplo para Express.js
app.use(cors({
  origin: '*', // En desarrollo, en producción usa dominios específicos
}));
```

### 3. Configura tu API para escuchar en todas las interfaces

**IMPORTANTE:** Tu API debe escuchar en `0.0.0.0` (todas las interfaces) y NO solo en `localhost` o `127.0.0.1`

#### Node.js/Express
```javascript
// ❌ NO funciona desde otros dispositivos
app.listen(3000, 'localhost', () => {
  console.log('Server running on localhost:3000');
});

// ✅ SÍ funciona desde otros dispositivos
app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on 0.0.0.0:3000');
});

// O simplemente (por defecto escucha en 0.0.0.0)
app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

#### Python/Flask
```python
# ❌ NO funciona desde otros dispositivos
app.run(host='127.0.0.1', port=5000)

# ✅ SÍ funciona desde otros dispositivos
app.run(host='0.0.0.0', port=5000)
```

#### Python/Django
```python
# En settings.py o al ejecutar
python manage.py runserver 0.0.0.0:8000
```

### 4. Firewall
- Asegúrate de que el firewall de Windows no esté bloqueando el puerto
- Si usas un dispositivo físico, ambos (PC y dispositivo) deben estar en la **misma red** (mismo router)
- **PC por cable + teléfono por Wi-Fi funciona** si ambos están conectados al mismo router

## Ejemplos de URLs comunes

### Node.js/Express (puerto 3000)
```dart
// Emulador Android
static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

// iOS Simulator
static const String apiBaseUrl = 'http://localhost:3000/api';

// Dispositivo físico
static const String apiBaseUrl = 'http://192.168.1.100:3000/api';
```

### Django (puerto 8000)
```dart
// Emulador Android
static const String apiBaseUrl = 'http://10.0.2.2:8000/api';

// iOS Simulator
static const String apiBaseUrl = 'http://localhost:8000/api';

// Dispositivo físico
static const String apiBaseUrl = 'http://192.168.1.100:8000/api';
```

### Flask (puerto 5000)
```dart
// Emulador Android
static const String apiBaseUrl = 'http://10.0.2.2:5000/api';

// iOS Simulator
static const String apiBaseUrl = 'http://localhost:5000/api';

// Dispositivo físico
static const String apiBaseUrl = 'http://192.168.1.100:5000/api';
```

## Volver a producción

Cuando quieras volver a usar la API de producción, simplemente cambia:
```dart
static const String apiBaseUrl = 'https://api.codigocreativo.cloud/api';
```

## Troubleshooting

### ❌ Error: "Connection refused"
- Verifica que tu API esté corriendo
- Verifica que el puerto sea correcto
- Verifica que el firewall no esté bloqueando

### ❌ Error: "Network is unreachable"
- Si usas dispositivo físico, verifica que ambos estén en la **misma red** (mismo router)
- Verifica que la IP sea correcta (usa la IP del adaptador Ethernet si tu PC está por cable)
- Verifica que tu API esté escuchando en `0.0.0.0` y no solo en `localhost`

### ❌ Error: "Connection refused" desde el teléfono (pero funciona en localhost)
- Tu API probablemente está escuchando solo en `localhost` o `127.0.0.1`
- Cambia tu API para que escuche en `0.0.0.0` (ver sección "Configura tu API para escuchar en todas las interfaces")

### ❌ Error: "Timeout"
- Verifica que la URL sea correcta
- Verifica que tu API responda en ese endpoint

