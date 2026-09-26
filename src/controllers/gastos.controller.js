const { supabase } = require('../lib/supabase');

const CATEGORIAS_VALIDAS = ['arriendo', 'servicios', 'productos', 'comida', 'transporte', 'otros'];

/**
 * POST /api/gastos
 * Registra un gasto operativo del negocio.
 *
 * Body esperado:
 * {
 *   "monto":     45.00,
 *   "categoria": "servicios",
 *   "concepto":  "Pago de luz" // opcional
 * }
 */
async function registrarGasto(req, res) {
  try {
    const { monto, categoria, concepto } = req.body;

    const montoNum = Number(monto);
    if (!monto || isNaN(montoNum) || montoNum <= 0) {
      return res.status(400).json({
        ok: false,
        error: 'El campo "monto" es obligatorio y debe ser un número mayor a 0.',
      });
    }

    if (!categoria || !CATEGORIAS_VALIDAS.includes(categoria)) {
      return res.status(400).json({
        ok: false,
        error: `El campo "categoria" debe ser uno de: ${CATEGORIAS_VALIDAS.join(', ')}.`,
      });
    }

    const { data, error } = await supabase
      .from('gastos')
      .insert([
        {
          monto: +montoNum.toFixed(2),
          categoria,
          concepto: concepto ? concepto.trim() : null,
        },
      ])
      .select()
      .single();

    if (error) {
      console.error('[registrarGasto] Supabase error:', error);
      return res.status(500).json({
        ok: false,
        error: 'No se pudo guardar el gasto. Intenta de nuevo.',
      });
    }

    return res.status(201).json({
      ok: true,
      mensaje: '✅ Gasto registrado correctamente.',
      data,
    });
  } catch (err) {
    console.error('[registrarGasto] Error inesperado:', err);
    return res.status(500).json({
      ok: false,
      error: 'Error interno del servidor.',
    });
  }
}

/**
 * GET /api/gastos
 * Lista los gastos del mes.
 */
async function listarGastos(req, res) {
  try {
    const { data, error } = await supabase
      .from('gastos')
      .select('*')
      .order('fecha', { ascending: false });

    if (error) {
      return res.status(500).json({ ok: false, error: 'Error al consultar gastos.' });
    }

    const total = (data || []).reduce((sum, g) => sum + Number(g.monto), 0);

    return res.status(200).json({
      ok: true,
      total: +total.toFixed(2),
      gastos: data || [],
    });
  } catch (err) {
    return res.status(500).json({ ok: false, error: 'Error interno.' });
  }
}

module.exports = { registrarGasto, listarGastos };
