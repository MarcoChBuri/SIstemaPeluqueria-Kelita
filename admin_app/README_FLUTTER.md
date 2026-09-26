# Peluquería Raquel Admin - App Móvil en Flutter 📱

Aplicación móvil nativa creada en **Flutter** para la administración completa del salón de belleza **Peluquería Raquel**. Lista para generar el archivo instalable **APK** para Android.

---

## 🚀 Características Implementadas

1. **Dashboard & KPIs**:
   - Resumen financiero en tiempo real (Ingresos por servicios, Total ingresos, Total gastos, Balance neto).
   - Indicador dinámico de estado del backend (*Online / Offline*).
   - Citas del día, citas confirmadas y próximas clientas agendadas.

2. **Agenda de Citas & WhatsApp Directo**:
   - Visualización y filtrado por estado (*Pendientes, Confirmadas, Completadas, Canceladas*) y por fecha.
   - Cambio de estado de citas en un toque.
   - Control del estado de pago (*Pagado / Pendiente*).
   - Botón directo para enviar mensaje de confirmación por **WhatsApp** a la clienta con formato personalizado.

3. **Nueva Cita Modal**:
   - Formulario completo con selector de clienta, teléfono, servicio del catálogo, promociones opcionales, selector de fecha, selector de hora y notas especiales.
   - Redirección y confirmación automática con WhatsApp.

4. **Catálogo de Servicios & Paquetes de Boda**:
   - Filtrado por categorías (*Colorimetría, Cortes, Tratamientos, Peinado & Maquillaje, Paquetes de Boda, Quinceañeras, Pestañas & Cejas*).
   - Creación de nuevos servicios con tarifas y tiempos asignados.

5. **Motor Químico de Colorimetría (Calculadora de Precios)**:
   - Controles deslizantes para porciones de decolorante, tubos de tinte/matizador, mezclas de peróxido y horas de trabajo.
   - Desglose transparente del costo de materiales, multiplicador de margen comercial (2.5x), mano de obra y **precio final sugerido**.
   - Botón para agendar cita directa con el presupuesto calculado.

6. **Flujo de Caja (Gastos & Venta de Productos)**:
   - Registro y categorización de egresos operativos (*Productos, Arriendo, Servicios, Comida, Transporte, Otros*).
   - Registro de venta de productos retail con costo, precio al público y cálculo automático de ganancia neta.

7. **Promociones del Mes**:
   - Listado de ofertas vigentes y creación de nuevas promociones con porcentajes o montos fijos de descuento y fechas límite.

8. **Galería & Cursos Online**:
   - Portafolio fotográfico de transformaciones capilares.
   - Cursos de formación con enlace directo a Hotmart.

9. **Configuración de Servidor**:
   - Permite ajustar la URL del backend dinámicamente desde la aplicación (soporta `http://10.0.2.2:3000/api` para emulador Android, IP local para red WiFi, o URL en producción).
   - Incluye botón de prueba de conexión en tiempo real.

---

## 🛠️ Cómo compilar y generar el APK

### Opción 1: Usar el script automático (Windows)
Ejecuta con doble clic el archivo:
```
admin_app\build_apk.bat
```

### Opción 2: Desde la terminal
Dentro de la carpeta `admin_app`:
```bash
# 1. Obtener dependencias
flutter pub get

# 2. Generar el APK en modo Release
flutter build apk --release
```

### 📍 Ubicación del APK generado:
El archivo APK se encontrará listo para instalar en:
```
admin_app/build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Cómo ejecutar en modo Desarrollo (Debug)
```bash
cd admin_app
flutter run
```
