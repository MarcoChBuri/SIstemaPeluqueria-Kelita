const { supabase } = require('../lib/supabase');

/**
 * GET /api/promociones
 * Lista las promociones activas y vigentes.
 */
async function listarPromociones(req, res) {
  try {
    const hoy = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('promociones')
      .select('*')
      .eq('activa', true)
      .lte('fecha_inicio', hoy)
      .gte('fecha_fin', hoy)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[listarPromociones] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al consultar promociones.' });
    }

    return res.status(200).json({
      ok: true,
      promociones: data || [],
    });
  } catch (err) {
    console.error('[listarPromociones] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * POST /api/promociones
 * Raquel crea una nueva promoción del mes.
 */
async function crearPromocion(req, res) {
  try {
    const { titulo, descripcion, porcentaje_descuento, monto_descuento, fecha_inicio, fecha_fin, imagen_url } = req.body;

    if (!titulo || titulo.trim() === '') {
      return res.status(400).json({ ok: false, error: 'El título de la promoción es obligatorio.' });
    }
    if (!fecha_fin) {
      return res.status(400).json({ ok: false, error: 'La fecha de finalización es obligatoria.' });
    }

    const nuevaPromo = {
      titulo: titulo.trim(),
      descripcion: descripcion ? descripcion.trim() : null,
      porcentaje_descuento: porcentaje_descuento ? parseInt(porcentaje_descuento, 10) : null,
      monto_descuento: monto_descuento ? Number(monto_descuento) : null,
      fecha_inicio: fecha_inicio || new Date().toISOString().split('T')[0],
      fecha_fin,
      imagen_url: imagen_url ? imagen_url.trim() : null,
      activa: true,
    };

    const { data, error } = await supabase
      .from('promociones')
      .insert(nuevaPromo)
      .select()
      .single();

    if (error) {
      console.error('[crearPromocion] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al crear la promoción.' });
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Promoción creada exitosamente.',
      promocion: data,
    });
  } catch (err) {
    console.error('[crearPromocion] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

module.exports = {
  listarPromociones,
  crearPromocion,
};
