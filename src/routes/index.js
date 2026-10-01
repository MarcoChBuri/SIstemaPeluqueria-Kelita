const { Router } = require('express');

// Controladores
const {
  crearCita,
  listarCitas,
  actualizarEstadoCita,
  verificarDisponibilidad,
} = require('../controllers/citas.controller');

const { listarServicios, crearServicio, actualizarServicio, eliminarServicio } = require('../controllers/servicios.controller');
const {
  listarPromociones,
  crearPromocion,
  actualizarPromocion,
  eliminarPromocion,
  validarQrPromocion,
} = require('../controllers/promociones.controller');

const { listarGaleria, agregarFotoGaleria } = require('../controllers/galeria.controller');
const { listarCursosHotmart, crearCursoHotmart } = require('../controllers/cursos.controller');
const { registrarGasto, listarGastos } = require('../controllers/gastos.controller');
const { calcularPrecio } = require('../controllers/calculadora.controller');

const { registrarVentaProducto, listarVentasProductos } = require('../controllers/productos.controller');
const { reporteSimple } = require('../controllers/reportes.controller');

const router = Router();

// ==========================================
// 1. CITAS Y RESERVAS (Clientes y Raquel)
// ==========================================
router.post('/citas',                   crearCita);                 // Cliente agenda cita
router.get('/citas',                    listarCitas);               // Raquel revisa su agenda
router.patch('/citas/:id/estado',       actualizarEstadoCita);      // Raquel confirma/cancela cita
router.get('/citas/disponibilidad',     verificarDisponibilidad);   // Consultar horas libres de un día

// ==========================================
// 2. SERVICIOS Y PAQUETES DE BODAS
// ==========================================
router.get('/servicios',                listarServicios);           // Catálogo público
router.post('/servicios',               crearServicio);             // Raquel agrega nuevo servicio
router.put('/servicios/:id',            actualizarServicio);        // Raquel edita servicio
router.delete('/servicios/:id',         eliminarServicio);          // Raquel elimina servicio

// ==========================================
// 3. PROMOCIONES DEL MES Y CÓDIGOS QR
// ==========================================
router.get('/promociones',              listarPromociones);         // Promos visibles en web/admin
router.post('/promociones',             crearPromocion);            // Raquel crea promo
router.put('/promociones/:id',          actualizarPromocion);       // Raquel edita promo
router.delete('/promociones/:id',       eliminarPromocion);         // Raquel elimina promo
router.post('/promociones/validar-qr',  validarQrPromocion);        // Validar QR de cliente VIP

// ==========================================
// 4. GALERÍA Y PORTAFOLIO DE TRABAJOS
// ==========================================
router.get('/galeria',                  listarGaleria);             // Galería pública
router.post('/galeria',                 agregarFotoGaleria);        // Raquel sube foto

// ==========================================
// 5. CURSOS ONLINE (Hotmart)
// ==========================================
router.get('/cursos',                   listarCursosHotmart);       // Cursos con link a Hotmart
router.post('/cursos',                  crearCursoHotmart);         // Raquel publica curso

// ==========================================
// 6. GASTOS Y CALCULADORA
// ==========================================
router.post('/gastos',                  registrarGasto);
router.get('/gastos',                   listarGastos);
router.post('/calcular-precio',         calcularPrecio);

// ==========================================
// 7. PRODUCTOS Y REPORTES
// ==========================================
router.post('/productos/venta',         registrarVentaProducto);
router.get('/productos/ventas',         listarVentasProductos);
router.get('/reporte-simple',           reporteSimple);

module.exports = router;

