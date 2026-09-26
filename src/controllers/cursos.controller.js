const { supabase } = require('../lib/supabase');

/**
 * GET /api/cursos
 * Lista los cursos activos que enlazan a Hotmart.
 */
async function listarCursosHotmart(req, res) {
  try {
    const { data, error } = await supabase
      .from('cursos_hotmart')
      .select('*')
      .eq('activo', true)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[listarCursosHotmart] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al consultar cursos.' });
    }

    return res.status(200).json({
      ok: true,
      cursos: data || [],
    });
  } catch (err) {
    console.error('[listarCursosHotmart] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * POST /api/cursos
 * Raquel agrega un nuevo curso con su link de Hotmart.
 */
async function crearCursoHotmart(req, res) {
  try {
    const { titulo, descripcion, precio_referencia, imagen_url, link_hotmart } = req.body;

    if (!titulo || !link_hotmart) {
      return res.status(400).json({ ok: false, error: 'Título y link_hotmart son obligatorios.' });
    }

    const nuevoCurso = {
      titulo: titulo.trim(),
      descripcion: descripcion ? descripcion.trim() : '',
      precio_referencia: Number(precio_referencia) || 0,
      imagen_url: imagen_url ? imagen_url.trim() : null,
      link_hotmart: link_hotmart.trim(),
      activo: true,
    };

    const { data, error } = await supabase
      .from('cursos_hotmart')
      .insert(nuevoCurso)
      .select()
      .single();

    if (error) {
      console.error('[crearCursoHotmart] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al registrar curso.' });
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Curso registrado correctamente.',
      curso: data,
    });
  } catch (err) {
    console.error('[crearCursoHotmart] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

module.exports = {
  listarCursosHotmart,
  crearCursoHotmart,
};
