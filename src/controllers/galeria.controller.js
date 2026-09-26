const { supabase } = require('../lib/supabase');

/**
 * GET /api/galeria
 * Obtiene las fotos de los trabajos para mostrar en el portafolio de la web.
 */
async function listarGaleria(req, res) {
  try {
    const { categoria } = req.query;

    let query = supabase
      .from('galeria_trabajos')
      .select('*')
      .order('destacado', { ascending: false })
      .order('created_at', { ascending: false });

    if (categoria) {
      query = query.eq('categoria', categoria);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[listarGaleria] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al consultar galería.' });
    }

    return res.status(200).json({
      ok: true,
      trabajos: data || [],
    });
  } catch (err) {
    console.error('[listarGaleria] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * POST /api/galeria
 * Raquel sube una foto de su trabajo al portafolio.
 */
async function agregarFotoGaleria(req, res) {
  try {
    const { titulo, categoria, imagen_url, descripcion, destacado } = req.body;

    if (!titulo || !imagen_url) {
      return res.status(400).json({ ok: false, error: 'Título e imagen_url son obligatorios.' });
    }

    const nuevoTrabajo = {
      titulo: titulo.trim(),
      categoria: categoria ? categoria.trim() : 'General',
      imagen_url: imagen_url.trim(),
      descripcion: descripcion ? descripcion.trim() : null,
      destacado: Boolean(destacado),
    };

    const { data, error } = await supabase
      .from('galeria_trabajos')
      .insert(nuevoTrabajo)
      .select()
      .single();

    if (error) {
      console.error('[agregarFotoGaleria] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al agregar foto a la galería.' });
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Foto agregada al portafolio.',
      trabajo: data,
    });
  } catch (err) {
    console.error('[agregarFotoGaleria] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

module.exports = {
  listarGaleria,
  agregarFotoGaleria,
};
