const { supabase } = require('../lib/supabase');

/**
 * GET /api/reporte-simple
 * Devuelve totales consolidados del mes:
 *  - Ingresos por servicios (citas completadas/confirmadas o pagadas)
 *  - Ingresos por ventas de productos (+ ganancia real)
 *  - Total gastos
 *  - Balance neto
 *
 * Query params opcionales:
 *  - mes:  número 1-12  (default: mes actual)
 *  - anio: número YYYY  (default: año actual)
 */
async function reporteSimple(req, res) {
  try {
    const ahora = new Date(
      new Date().toLocaleString('en-US', { timeZone: 'America/Guayaquil' })
    );

    const mes = parseInt(req.query.mes, 10) || ahora.getMonth() + 1;
    const anio = parseInt(req.query.anio, 10) || ahora.getFullYear();

    const inicioMes = `${anio}-${String(mes).padStart(2, '0')}-01`;
    const finMes = new Date(anio, mes, 0).toISOString().split('T')[0];

    // --- Consultas a la base de datos ---
    const [resCitas, resProductos, resGastos] = await Promise.all([
      // Ingresos por servicios desde la tabla 'citas'
      supabase
        .from('citas')
        .select('precio_final, estado, estado_pago')
        .gte('fecha_cita', inicioMes)
        .lte('fecha_cita', finMes)
        .neq('estado', 'cancelada'),

      // Ventas de productos
      supabase
        .from('ventas_productos')
        .select('precio_costo, precio_venta, cantidad')
        .gte('fecha', `${inicioMes}T00:00:00Z`)
        .lte('fecha', `${finMes}T23:59:59Z`),

      // Gastos
      supabase
        .from('gastos')
        .select('monto')
        .gte('fecha', `${inicioMes}T00:00:00Z`)
        .lte('fecha', `${finMes}T23:59:59Z`),
    ]);

    // --- Cálculos ---
    const citasData = resCitas.data || [];
    const totalServicios = citasData.reduce(
      (sum, row) => sum + Number(row.precio_final || 0),
      0
    );

    const productosData = resProductos.data || [];
    const totalVentasProductos = productosData.reduce(
      (sum, row) => sum + Number(row.precio_venta || 0) * Number(row.cantidad || 1),
      0
    );

    const totalCostoProductos = productosData.reduce(
      (sum, row) => sum + Number(row.precio_costo || 0) * Number(row.cantidad || 1),
      0
    );

    const gananciaRealProductos = totalVentasProductos - totalCostoProductos;

    const gastosData = resGastos.data || [];
    const totalGastos = gastosData.reduce(
      (sum, row) => sum + Number(row.monto || 0),
      0
    );

    const totalCursos = 0; // Cursos Hotmart delegados a Hotmart
    const totalIngresos = totalCursos + totalServicios + totalVentasProductos;
    const balanceNeto = totalIngresos - totalGastos;

    const nombreMes = new Date(anio, mes - 1)
      .toLocaleString('es-EC', { month: 'long' })
      .toUpperCase();

    return res.status(200).json({
      ok: true,
      periodo: `${nombreMes} ${anio}`,
      ingresos: {
        cursos: +totalCursos.toFixed(2),
        servicios: +totalServicios.toFixed(2),
        productos: +totalVentasProductos.toFixed(2),
      },
      total_ingresos: +totalIngresos.toFixed(2),
      total_gastos: +totalGastos.toFixed(2),
      ganancia_real_productos: +gananciaRealProductos.toFixed(2),
      balance_neto: +balanceNeto.toFixed(2),
      mensaje:
        balanceNeto >= 0
          ? `✅ Balance positivo: $${balanceNeto.toFixed(2)} de ganancia neta este mes.`
          : `⚠️ Balance negativo: -$${Math.abs(balanceNeto).toFixed(2)} este mes.`,
    });
  } catch (err) {
    console.error('[reporteSimple] Error inesperado:', err);
    return res.status(500).json({
      ok: false,
      error: 'Error interno del servidor al calcular el reporte.',
    });
  }
}

module.exports = { reporteSimple };
