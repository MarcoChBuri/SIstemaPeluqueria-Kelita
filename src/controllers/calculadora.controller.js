/**
 * POST /api/calcular-precio
 *
 * Calculadora de precios para servicios de tinte y colorimetría.
 * Recibe las "porciones" visuales de cada insumo y devuelve el
 * precio final automatizado con el multiplicador x3 de margen.
 *
 * Body esperado:
 * {
 *   "porciones_decolorante": 2,
 *   "tubos_tinte":           1,
 *   "mezclas_peroxido":      2,
 *   "horas_trabajo":         3
 * }
 *
 * Fórmula:
 *   costo_materiales = (porciones * $6.25) + (tubos * $6.00) + (mezclas * $1.50)
 *   precio_materiales_con_margen = costo_materiales * 3
 *   costo_mano_de_obra = horas * $10.00
 *   PRECIO_FINAL = precio_materiales_con_margen + costo_mano_de_obra
 */

// Precios unitarios de referencia (USD)
const PRECIOS = Object.freeze({
  PORCION_DECOLORANTE: 25,  // 1/4 de pote de $25
  TUBO_TINTE: 4,
  MEZCLA_PEROXIDO: 0.08,
  HORA_TRABAJO: 5.00,
  MULTIPLICADOR: 1.5,
  EXTRA: 1

});

function calcularPrecio(req, res) {
  try {
    const {
      porciones_decolorante,
      tubos_tinte,
      mezclas_peroxido,
      horas_trabajo,
      extra,
    } = req.body;

    // --- Validaciones ---
    const camposObligatorios = [
      { nombre: 'porciones_decolorante', valor: porciones_decolorante },
      { nombre: 'tubos_tinte', valor: tubos_tinte },
      { nombre: 'mezclas_peroxido', valor: mezclas_peroxido },
      { nombre: 'horas_trabajo', valor: horas_trabajo },
    ];

    for (const campo of camposObligatorios) {
      const val = Number(campo.valor);
      if (campo.valor === undefined || campo.valor === null || isNaN(val) || val < 0) {
        return res.status(400).json({
          ok: false,
          error: `El campo "${campo.nombre}" es obligatorio y debe ser un número >= 0.`,
        });
      }
    }

    // El campo extra es opcional (por defecto 0)
    let extraNum = 0;
    if (extra !== undefined && extra !== null && extra !== '') {
      extraNum = Number(extra);
      if (isNaN(extraNum) || extraNum < 0) {
        return res.status(400).json({
          ok: false,
          error: 'El campo "extra" debe ser un número >= 0.',
        });
      }
    }

    const porcionesNum = Number(porciones_decolorante);
    const tubosNum = Number(tubos_tinte);
    const mezclasNum = Number(mezclas_peroxido);
    const horasNum = Number(horas_trabajo);


    // --- Cálculo del desglose ---
    const costoDecolorante = porcionesNum * PRECIOS.PORCION_DECOLORANTE;
    const costoTinte = tubosNum * PRECIOS.TUBO_TINTE;
    const costoPeroxido = mezclasNum * PRECIOS.MEZCLA_PEROXIDO;
    const costoExtra = extraNum * PRECIOS.EXTRA;

    const costoTotalMateriales = costoDecolorante + costoTinte + costoPeroxido + costoExtra;
    const materialesConMargen = costoTotalMateriales * PRECIOS.MULTIPLICADOR;

    const costoManoDeObra = horasNum * PRECIOS.HORA_TRABAJO;

    const precioFinal = materialesConMargen + costoManoDeObra;

    return res.status(200).json({
      ok: true,
      desglose: {
        decolorante: {
          porciones: porcionesNum,
          precio_unitario: PRECIOS.PORCION_DECOLORANTE,
          subtotal: +costoDecolorante.toFixed(2),
        },
        tinte: {
          tubos: tubosNum,
          precio_unitario: PRECIOS.TUBO_TINTE,
          subtotal: +costoTinte.toFixed(2),
        },
        peroxido: {
          mezclas: mezclasNum,
          precio_unitario: PRECIOS.MEZCLA_PEROXIDO,
          subtotal: +costoPeroxido.toFixed(2),
        },
        extra: {
          extra: costoExtra.toFixed(2),
        },
        costo_total_materiales: +costoTotalMateriales.toFixed(2),
        multiplicador: `x${PRECIOS.MULTIPLICADOR}`,
        materiales_con_margen: +materialesConMargen.toFixed(2),
        mano_de_obra: {
          horas: horasNum,
          precio_hora: PRECIOS.HORA_TRABAJO,
          subtotal: +costoManoDeObra.toFixed(2),
        },
      },
      PRECIO_FINAL: +precioFinal.toFixed(2),
      mensaje: `💰 Debes cobrar $${precioFinal.toFixed(2)} por este servicio.`,
    });
  } catch (err) {
    console.error('[calcularPrecio] Error inesperado:', err);
    return res.status(500).json({
      ok: false,
      error: 'Error interno del servidor.',
    });
  }
}

module.exports = { calcularPrecio };
