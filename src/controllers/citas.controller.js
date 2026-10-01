const { supabase } = require('../lib/supabase');

/**
 * POST /api/citas
 * Crea una nueva reserva de cita.
 *
 * Body esperado:
 * {
 *   "cliente_nombre": "María Perez",
 *   "cliente_telefono": "0991234567",
 *   "cliente_email": "maria@gmail.com", // opcional
 *   "servicio_id": "uuid-del-servicio",
 *   "promocion_id": "uuid-promocion",   // opcional
 *   "fecha_cita": "2026-09-20",         // YYYY-MM-DD
 *   "hora_inicio": "14:00",             // HH:mm
 *   "notas": "Tengo el cabello largo y tinturado" // opcional
 * }
 */
async function crearCita(req, res) {
  try {
    const {
      cliente_nombre,
      cliente_telefono,
      cliente_email,
      servicio_id,
      promocion_id,
      fecha_cita,
      hora_inicio,
      notas,
    } = req.body;

    // 1. Validaciones básicas
    if (!cliente_nombre || cliente_nombre.trim() === '') {
      return res.status(400).json({ ok: false, error: 'El nombre del cliente es obligatorio.' });
    }
    if (!cliente_telefono || cliente_telefono.trim() === '') {
      return res.status(400).json({ ok: false, error: 'El teléfono de contacto es obligatorio.' });
    }
    if (!servicio_id) {
      return res.status(400).json({ ok: false, error: 'Debes seleccionar un servicio.' });
    }
    if (!fecha_cita || !hora_inicio) {
      return res.status(400).json({ ok: false, error: 'La fecha y hora de la cita son obligatorias.' });
    }

    // 2. Obtener servicio para saber duración y precio base
    const { data: servicio, error: errServicio } = await supabase
      .from('servicios')
      .select('*')
      .eq('id', servicio_id)
      .single();

    if (errServicio || !servicio) {
      return res.status(404).json({ ok: false, error: 'Servicio no encontrado.' });
    }

    // 3. Calcular hora_fin sumando la duración en minutos (usar duracion_minutos personalizada o del servicio)
    const duracionFinal = req.body.duracion_minutos ? parseInt(req.body.duracion_minutos, 10) : (servicio.duracion_minutos || 60);
    const [horasStr, minutosStr] = hora_inicio.split(':');
    const inicioMinutos = parseInt(horasStr, 10) * 60 + parseInt(minutosStr, 10);
    const finMinutos = inicioMinutos + duracionFinal;

    const finHora = String(Math.floor(finMinutos / 60)).padStart(2, '0');
    const finMin = String(finMinutos % 60).padStart(2, '0');
    const hora_fin = `${finHora}:${finMin}`;


    // 4. Validar disponibilidad (evitar solapamiento de horarios en citas no canceladas)
    const { data: citasExistentes, error: errCitas } = await supabase
      .from('citas')
      .select('hora_inicio, hora_fin, estado')
      .eq('fecha_cita', fecha_cita)
      .neq('estado', 'cancelada');

    if (errCitas) {
      console.error('[crearCita] Error al verificar citas existentes:', errCitas);
    } else if (citasExistentes && citasExistentes.length > 0) {
      const seSolapa = citasExistentes.some((cita) => {
        return hora_inicio < cita.hora_fin && hora_fin > cita.hora_inicio;
      });

      if (seSolapa) {
        return res.status(409).json({
          ok: false,
          error: 'Ese horario ya está ocupado. Por favor elige otra hora.',
        });
      }
    }

    // 5. Calcular precio final y descuentos si aplica promoción
    let precioOriginal = Number(servicio.precio_base);
    let descuentoAplicado = 0;

    if (promocion_id) {
      const { data: promo } = await supabase
        .from('promociones')
        .select('*')
        .eq('id', promocion_id)
        .eq('activa', true)
        .single();

      if (promo) {
        if (promo.porcentaje_descuento) {
          descuentoAplicado = (precioOriginal * promo.porcentaje_descuento) / 100;
        } else if (promo.monto_descuento) {
          descuentoAplicado = Number(promo.monto_descuento);
        }
      }
    }

    const precioFinal = Math.max(0, precioOriginal - descuentoAplicado);

    // 6. Insertar en la base de datos
    const nuevaCita = {
      cliente_nombre: cliente_nombre.trim(),
      cliente_telefono: cliente_telefono.trim(),
      cliente_email: cliente_email ? cliente_email.trim() : null,
      servicio_id,
      promocion_id: promocion_id || null,
      fecha_cita,
      hora_inicio,
      hora_fin,
      estado: 'pendiente',
      estado_pago: 'pendiente',
      precio_original: +precioOriginal.toFixed(2),
      descuento_aplicado: +descuentoAplicado.toFixed(2),
      precio_final: +precioFinal.toFixed(2),
      notas: notas ? notas.trim() : null,
    };

    const { data, error } = await supabase
      .from('citas')
      .insert(nuevaCita)
      .select('*, servicios(*), promociones(*)')
      .single();

    if (error) {
      console.error('[crearCita] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'Error al registrar la cita.' });
    }

    // 7. Generar link directo de WhatsApp para confirmación
    const mensajeWsp = encodeURIComponent(
      `¡Hola Raquel! Acabo de solicitar una cita en tu web:\n` +
      `📅 Fecha: ${fecha_cita}\n` +
      `⏰ Hora: ${hora_inicio} a ${hora_fin}\n` +
      `💇‍♀️ Servicio: ${servicio.nombre}\n` +
      `💰 Total estimado: $${precioFinal.toFixed(2)}\n` +
      `👤 Nombre: ${cliente_nombre}`
    );

    return res.status(201).json({
      ok: true,
      mensaje: '🎉 ¡Cita agendada con éxito!',
      cita: data,
      whatsapp_url: `https://wa.me/?text=${mensajeWsp}`,
    });
  } catch (err) {
    console.error('[crearCita] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * GET /api/citas
 * Lista las citas (para el panel de administración de Raquel).
 * Filtros opcionales por query: fecha, estado, mes, anio.
 */
async function listarCitas(req, res) {
  try {
    const { fecha, estado, mes, anio } = req.query;

    let query = supabase
      .from('citas')
      .select('*, servicios(nombre, duracion_minutos, categoria), promociones(titulo, porcentaje_descuento)')
      .order('fecha_cita', { ascending: true })
      .order('hora_inicio', { ascending: true });

    if (fecha) {
      query = query.eq('fecha_cita', fecha);
    }
    if (estado) {
      query = query.eq('estado', estado);
    }
    if (mes && anio) {
      const inicioMes = `${anio}-${String(mes).padStart(2, '0')}-01`;
      const finMes = new Date(anio, mes, 0).toISOString().split('T')[0];
      query = query.gte('fecha_cita', inicioMes).lte('fecha_cita', finMes);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[listarCitas] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'No se pudieron cargar las citas.' });
    }

    return res.status(200).json({
      ok: true,
      cantidad: data ? data.length : 0,
      citas: data || [],
    });
  } catch (err) {
    console.error('[listarCitas] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * PATCH /api/citas/:id/estado
 * Cambia el estado de una cita (confirmar, completar, cancelar) y estado de pago.
 */
async function actualizarEstadoCita(req, res) {
  try {
    const { id } = req.params;
    const { estado, estado_pago } = req.body;

    const actualizaciones = {};
    if (estado) actualizaciones.estado = estado;
    if (estado_pago) actualizaciones.estado_pago = estado_pago;

    if (Object.keys(actualizaciones).length === 0) {
      return res.status(400).json({ ok: false, error: 'No se enviaron campos para actualizar.' });
    }

    const { data, error } = await supabase
      .from('citas')
      .update(actualizaciones)
      .eq('id', id)
      .select('*, servicios(nombre)')
      .single();

    if (error) {
      console.error('[actualizarEstadoCita] Error Supabase:', error);
      return res.status(500).json({ ok: false, error: 'No se pudo actualizar la cita.' });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Cita actualizada correctamente.',
      cita: data,
    });
  } catch (err) {
    console.error('[actualizarEstadoCita] Error inesperado:', err);
    return res.status(500).json({ ok: false, error: 'Error interno del servidor.' });
  }
}

/**
 * GET /api/citas/disponibilidad
 * Devuelve las horas ya reservadas de un día específico para bloquearlas en el calendario del cliente.
 */
async function verificarDisponibilidad(req, res) {
  try {
    const { fecha } = req.query;
    if (!fecha) {
      return res.status(400).json({ ok: false, error: 'El parámetro fecha (YYYY-MM-DD) es obligatorio.' });
    }

    const { data, error } = await supabase
      .from('citas')
      .select('hora_inicio, hora_fin, estado')
      .eq('fecha_cita', fecha)
      .neq('estado', 'cancelada');

    if (error) {
      return res.status(500).json({ ok: false, error: 'Error al consultar disponibilidad.' });
    }

    return res.status(200).json({
      ok: true,
      fecha,
      horas_ocupadas: data || [],
    });
  } catch (err) {
    return res.status(500).json({ ok: false, error: 'Error interno.' });
  }
}

module.exports = {
  crearCita,
  listarCitas,
  actualizarEstadoCita,
  verificarDisponibilidad,
};
