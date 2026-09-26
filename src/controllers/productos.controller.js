const { supabase } = require('../lib/supabase');

/**
 * POST /api/productos/venta
 * Registra una venta de producto de forma súper simple.
 *
 * Body esperado:
 * {
 *   "nombre": "Shampoo",
 *   "costo":  2.00,   // lo que le costó a Raquel
 *   "precio": 22.00   // a lo que lo vendió
 * }
 */
async function registrarVentaProducto(req, res) {
  try {
    const { nombre, costo, precio, nombre_producto, precio_costo, precio_venta } = req.body;

    const nombreFinal = (nombre || nombre_producto || '').trim();
    if (!nombreFinal) {
      return res.status(400).json({
        ok: false,
        error: 'El nombre del producto es obligatorio.',
      });
    }

    const valorCosto = costo !== undefined ? costo : precio_costo;
    const costoNum = Number(valorCosto);
    if (valorCosto === undefined || valorCosto === null || isNaN(costoNum) || costoNum < 0) {
      return res.status(400).json({
        ok: false,
        error: 'El campo "costo" es obligatorio y debe ser un número >= 0.',
      });
    }

    const valorPrecio = precio !== undefined ? precio : precio_venta;
    const precioNum = Number(valorPrecio);
    if (valorPrecio === undefined || valorPrecio === null || isNaN(precioNum) || precioNum <= 0) {
      return res.status(400).json({
        ok: false,
        error: 'El campo "precio" es obligatorio y debe ser un número mayor a 0.',
      });
    }

    // Ganancia calculada
    const ganancia = precioNum - costoNum;

    const { data, error } = await supabase
      .from('ventas_productos')
      .insert({
        nombre_producto: nombreFinal,
        precio_costo: costoNum,
        precio_venta: precioNum,
        cantidad: 1,
        estado_pago: 'verificado',
      })
      .select()
      .single();

    if (error) {
      console.error('[registrarVentaProducto] Supabase error:', error);
      return res.status(500).json({
        ok: false,
        error: 'No se pudo registrar la venta del producto.',
      });
    }

    return res.status(201).json({
      ok: true,
      mensaje: `✅ Venta registrada. Ganancia: $${ganancia.toFixed(2)}`,
      data: {
        id: data.id,
        nombre: data.nombre_producto,
        costo: +costoNum.toFixed(2),
        precio: +precioNum.toFixed(2),
        ganancia: +ganancia.toFixed(2),
        fecha: data.fecha,
      },
    });
  } catch (err) {
    console.error('[registrarVentaProducto] Error inesperado:', err);
    return res.status(500).json({
      ok: false,
      error: 'Error interno del servidor.',
    });
  }
}

/**
 * GET /api/productos/ventas
 * Lista las ventas de productos del mes.
 */
async function listarVentasProductos(req, res) {
  try {
    const ahora = new Date(
      new Date().toLocaleString('en-US', { timeZone: 'America/Guayaquil' })
    );

    const mes  = parseInt(req.query.mes, 10)  || (ahora.getMonth() + 1);
    const anio = parseInt(req.query.anio, 10) || ahora.getFullYear();

    const inicioMes = new Date(anio, mes - 1, 1).toISOString();
    const finMes    = new Date(anio, mes, 1).toISOString();

    const { data, error } = await supabase
      .from('ventas_productos')
      .select('*')
      .gte('fecha', inicioMes)
      .lt('fecha', finMes)
      .order('fecha', { ascending: false });

    if (error) {
      console.error('[listarVentasProductos] Supabase error:', error);
      return res.status(500).json({
        ok: false,
        error: 'No se pudieron obtener las ventas de productos.',
      });
    }

    const totalVentas = data.reduce((sum, row) => sum + Number(row.precio_venta), 0);
    const totalCosto  = data.reduce((sum, row) => sum + Number(row.precio_costo), 0);
    const gananciaReal = totalVentas - totalCosto;

    const nombreMes = new Date(anio, mes - 1)
      .toLocaleString('es-EC', { month: 'long' })
      .toUpperCase();

    return res.status(200).json({
      ok: true,
      periodo: `${nombreMes} ${anio}`,
      cantidad: data.length,
      total_ventas: +totalVentas.toFixed(2),
      total_costo: +totalCosto.toFixed(2),
      ganancia_total: +gananciaReal.toFixed(2),
      ventas: data.map((v) => ({
        id: v.id,
        nombre: v.nombre_producto,
        costo: +Number(v.precio_costo).toFixed(2),
        precio: +Number(v.precio_venta).toFixed(2),
        ganancia: +(Number(v.precio_venta) - Number(v.precio_costo)).toFixed(2),
        fecha: v.fecha,
      })),
    });
  } catch (err) {
    console.error('[listarVentasProductos] Error inesperado:', err);
    return res.status(500).json({
      ok: false,
      error: 'Error interno del servidor.',
    });
  }
}

module.exports = { registrarVentaProducto, listarVentasProductos };
