const { supabase } = require('../lib/supabase');

/**
 * Genera un código único corto para QR si no se proporciona uno.
 */
function generarCodigoQR() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = 'RAQUEL-VIP-';
  for (let i = 0; i < 5; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * GET /api/promociones
 * Lista las promociones.
 * Query params opcionales:
 * - ?solo_publicas=true (solo devuelve promociones públicas y activas para la web)
 * - ?incluir_inactivas=true (para el panel admin)
 */
async function listarPromociones(req, res) {
  try {
    const { solo_publicas, incluir_inactivas } = req.query;
    const hoy = new Date().toISOString().split('T')[0];

    let query = supabase
      .from('promociones')
      .select('*')
      .order('created_at', { ascending: false });

    if (solo_publicas === 'true') {
      // Filtrar: activa y dentro del rango de fechas
      query = query
        .eq('activa', true)
        .lte('fecha_inicio', hoy)
        .gte('fecha_fin', hoy);
    } else if (incluir_inactivas !== 'true') {
      // Por defecto para clientes generales si no se especifica solo_publicas
      query = query.eq('activa', true);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[listarPromociones] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al consultar promociones.' });
    }

    // Normalizar para que frontend y apps tengan campos consistentes
    const listaNormalizada = (data || []).map((p) => ({
      ...p,
      es_publica: p.activa,
      codigo_qr: p.id,
    }));

    return res.status(200).json({
      ok: true,
      promociones: listaNormalizada,
    });
  } catch (err) {
    console.error('[listarPromociones] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * POST /api/promociones
 * Raquel crea una nueva promoción.
 */
async function crearPromocion(req, res) {
  try {
    const {
      titulo,
      descripcion,
      porcentaje_descuento,
      monto_descuento,
      fecha_inicio,
      fecha_fin,
      imagen_url,
      es_publica,
      activa,
    } = req.body;

    if (!titulo || titulo.trim() === '') {
      return res.status(400).json({ ok: false, error: 'El título de la promoción es obligatorio.' });
    }
    if (!fecha_fin) {
      return res.status(400).json({ ok: false, error: 'La fecha de finalización es obligatoria.' });
    }

    // Determinar estado activa: si es_publica es false o activa es false, queda desactivada
    let estadoActiva = true;
    if (activa !== undefined) {
      estadoActiva = Boolean(activa);
    } else if (es_publica !== undefined) {
      estadoActiva = Boolean(es_publica);
    }

    const nuevaPromo = {
      titulo: titulo.trim(),
      descripcion: descripcion ? descripcion.trim() : null,
      porcentaje_descuento: porcentaje_descuento ? parseInt(porcentaje_descuento, 10) : null,
      monto_descuento: monto_descuento ? Number(monto_descuento) : null,
      fecha_inicio: fecha_inicio || new Date().toISOString().split('T')[0],
      fecha_fin,
      imagen_url: imagen_url ? imagen_url.trim() : null,
      activa: estadoActiva,
    };

    const { data, error } = await supabase
      .from('promociones')
      .insert(nuevaPromo)
      .select()
      .single();

    if (error) {
      console.error('[crearPromocion] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al crear la promoción en la base de datos.' });
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Promoción creada exitosamente.',
      promocion: {
        ...data,
        es_publica: data.activa,
        codigo_qr: data.id,
      },
    });
  } catch (err) {
    console.error('[crearPromocion] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * PUT /api/promociones/:id
 * Editar una promoción existente (activar/desactivar, fechas, descuentos, etc.)
 */
async function actualizarPromocion(req, res) {
  try {
    const { id } = req.params;
    const {
      titulo,
      descripcion,
      porcentaje_descuento,
      monto_descuento,
      fecha_inicio,
      fecha_fin,
      imagen_url,
      activa,
      es_publica,
    } = req.body;

    const updates = {};
    if (titulo !== undefined) updates.titulo = titulo.trim();
    if (descripcion !== undefined) updates.descripcion = descripcion ? descripcion.trim() : null;
    if (porcentaje_descuento !== undefined) updates.porcentaje_descuento = porcentaje_descuento ? parseInt(porcentaje_descuento, 10) : null;
    if (monto_descuento !== undefined) updates.monto_descuento = monto_descuento ? Number(monto_descuento) : null;
    if (fecha_inicio !== undefined) updates.fecha_inicio = fecha_inicio;
    if (fecha_fin !== undefined) updates.fecha_fin = fecha_fin;
    if (imagen_url !== undefined) updates.imagen_url = imagen_url ? imagen_url.trim() : null;

    // Sincronizar activa / es_publica (para poner o quitar de la web)
    if (activa !== undefined) {
      updates.activa = Boolean(activa);
    } else if (es_publica !== undefined) {
      updates.activa = Boolean(es_publica);
    }

    const { data, error } = await supabase
      .from('promociones')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[actualizarPromocion] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al actualizar la promoción.' });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Promoción actualizada correctamente.',
      promocion: {
        ...data,
        es_publica: data.activa,
        codigo_qr: data.id,
      },
    });
  } catch (err) {
    console.error('[actualizarPromocion] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * DELETE /api/promociones/:id
 * Eliminar una promoción.
 */
async function eliminarPromocion(req, res) {
  try {
    const { id } = req.params;
    const { error } = await supabase.from('promociones').delete().eq('id', id);

    if (error) {
      console.error('[eliminarPromocion] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al eliminar la promoción.' });
    }

    return res.status(200).json({ ok: true, mensaje: 'Promoción eliminada correctamente.' });
  } catch (err) {
    console.error('[eliminarPromocion] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * POST /api/promociones/validar-qr
 * Validar o escanear el código QR de una promoción.
 */
async function validarQrPromocion(req, res) {
  try {
    const { codigo_qr } = req.body;
    if (!codigo_qr || codigo_qr.trim() === '') {
      return res.status(400).json({ ok: false, error: 'Ingresa o escanea un código QR válido.' });
    }

    const codeClean = codigo_qr.trim().toUpperCase();
    const hoy = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('promociones')
      .select('*')
      .eq('id', codeClean)
      .single();

    if (error || !data) {
      return res.status(404).json({
        ok: false,
        error: `El código QR "${codeClean}" no existe o es inválido.`,
      });
    }

    if (!data.activa) {
      return res.status(400).json({
        ok: false,
        error: `La promoción "${data.titulo}" está desactivada actualmente.`,
      });
    }

    if (data.fecha_fin < hoy) {
      return res.status(400).json({
        ok: false,
        error: `La promoción "${data.titulo}" ya expiró el ${data.fecha_fin}.`,
      });
    }

    return res.status(200).json({
      ok: true,
      valida: true,
      mensaje: `🎉 ¡Código QR Válido! Promoción: "${data.titulo}"`,
      promocion: {
        ...data,
        es_publica: data.activa,
        codigo_qr: data.id,
      },
    });
  } catch (err) {
    console.error('[validarQrPromocion] Error:', err);
    return res.status(500).json({ ok: false, error: 'Error interno al validar el código QR.' });
  }
}

module.exports = {
  listarPromociones,
  crearPromocion,
  actualizarPromocion,
  eliminarPromocion,
  validarQrPromocion,
};

