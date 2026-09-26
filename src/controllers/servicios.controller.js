const { supabase } = require('../lib/supabase');

const CATEGORIAS_VALIDAS = [
  'corte',
  'colorimetria',
  'tratamiento',
  'peinado_maquillaje',
  'paquete_bodas',
  'paquete_quinceanera',
  'pestanas_cejas',
  'otro',
];

/**
 * GET /api/servicios
 * Lista todos los servicios y paquetes activos.
 * Opcional: ?categoria=paquete_bodas
 */
async function listarServicios(req, res) {
  try {
    const { categoria, solo_activos } = req.query;

    let query = supabase
      .from('servicios')
      .select('*')
      .order('categoria', { ascending: true })
      .order('precio_base', { ascending: true });

    if (solo_activos !== 'false') {
      query = query.eq('activo', true);
    }
    if (categoria) {
      query = query.eq('categoria', categoria);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[listarServicios] Supabase error:', error);
      return res.status(500).json({ ok: false, error: 'No se pudieron cargar los servicios.' });
    }

    // Separar por categorías útiles para el frontend
    const paquetesBodas = (data || []).filter((s) => s.categoria === 'paquete_bodas' || s.categoria === 'paquete_quinceanera');
    const serviciosIndividuales = (data || []).filter((s) => s.categoria !== 'paquete_bodas' && s.categoria !== 'paquete_quinceanera');

    return res.status(200).json({
      ok: true,
      servicios: data || [],
      paquetes_especiales: paquetesBodas,
      servicios_regulares: serviciosIndividuales,
    });
  } catch (err) {
    console.error('[listarServicios] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * POST /api/servicios
 * Permite a Raquel agregar un nuevo servicio o paquete desde el panel.
 */
async function crearServicio(req, res) {
  try {
    const { nombre, categoria, descripcion, duracion_minutos, precio_base, imagen_url } = req.body;

    if (!nombre || nombre.trim() === '') {
      return res.status(400).json({ ok: false, error: 'El nombre del servicio es obligatorio.' });
    }
    if (!categoria || !CATEGORIAS_VALIDAS.includes(categoria)) {
      return res.status(400).json({
        ok: false,
        error: `Categoría inválida. Debe ser una de: ${CATEGORIAS_VALIDAS.join(', ')}`,
      });
    }

    const duracionNum = parseInt(duracion_minutos, 10);
    if (isNaN(duracionNum) || duracionNum <= 0) {
      return res.status(400).json({ ok: false, error: 'La duración en minutos debe ser mayor a 0.' });
    }

    const precioNum = Number(precio_base);
    if (isNaN(precioNum) || precioNum < 0) {
      return res.status(400).json({ ok: false, error: 'El precio base debe ser un número >= 0.' });
    }

    const nuevoServicio = {
      nombre: nombre.trim(),
      categoria,
      descripcion: descripcion ? descripcion.trim() : null,
      duracion_minutos: duracionNum,
      precio_base: +precioNum.toFixed(2),
      imagen_url: imagen_url ? imagen_url.trim() : null,
      activo: true,
    };

    const { data, error } = await supabase
      .from('servicios')
      .insert(nuevoServicio)
      .select()
      .single();

    if (error) {
      console.error('[crearServicio] Supabase error:', error);
      return res.status(500).json({ ok: false, error: 'Error al guardar el servicio.' });
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Servicio creado correctamente.',
      servicio: data,
    });
  } catch (err) {
    console.error('[crearServicio] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

module.exports = {
  listarServicios,
  crearServicio,
};
