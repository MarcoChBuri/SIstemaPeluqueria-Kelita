import React, { useState, useEffect } from 'react';
import { Settings, Layers, CheckCircle2, RefreshCw, X, Save } from 'lucide-react';
import { CalculoPrecioResult } from '../types';

interface CalculadoraViewProps {
  onScheduleAppointmentWithPrice?: (precio: number) => void;
  onShowToast: (message: string) => void;
}

interface PreciosInsumos {
  precioDecolorante: number;
  precioTinte: number;
  precioPeroxido: number;
  precioHoraManoObra: number;
  multiplicador: number;
}

const DEFAULT_PRECIOS: PreciosInsumos = {
  precioDecolorante: 3.50,
  precioTinte: 6.00,
  precioPeroxido: 1.50,
  precioHoraManoObra: 10.00,
  multiplicador: 2.5,
};

export const CalculadoraView: React.FC<CalculadoraViewProps> = ({
  onScheduleAppointmentWithPrice,
  onShowToast,
}) => {
  // Cantidades de insumos
  const [porcionesDecolorante, setPorcionesDecolorante] = useState<number>(2);
  const [tubosTinte, setTubosTinte] = useState<number>(1);
  const [mezclasPeroxido, setMezclasPeroxido] = useState<number>(2);
  const [horasTrabajo, setHorasTrabajo] = useState<number>(3);
  const [extra, setExtra] = useState<number>(0);

  // Precios configurables de proveedor
  const [preciosInsumos, setPreciosInsumos] = useState<PreciosInsumos>(() => {
    try {
      const saved = localStorage.getItem('raquel_precios_insumos');
      if (saved) return JSON.parse(saved);
    } catch (_) {}
    return DEFAULT_PRECIOS;
  });

  // Modal de configuración de precios
  const [isConfigOpen, setIsConfigOpen] = useState<boolean>(false);
  const [tempPrecios, setTempPrecios] = useState<PreciosInsumos>(preciosInsumos);

  // Resultado del cálculo local/personalizado
  const [calculoResult, setCalculoResult] = useState<CalculoPrecioResult | null>(null);

  // Guardar precios localmente
  const handleSavePrecios = (e: React.FormEvent) => {
    e.preventDefault();
    setPreciosInsumos(tempPrecios);
    try {
      localStorage.setItem('raquel_precios_insumos', JSON.stringify(tempPrecios));
    } catch (_) {}
    setIsConfigOpen(false);
    onShowToast('¡Precios de proveedor actualizados correctamente!');
  };

  // Calcular precio en base a insumos y precios de proveedor
  useEffect(() => {
    const costDecol = porcionesDecolorante * preciosInsumos.precioDecolorante;
    const costTinte = tubosTinte * preciosInsumos.precioTinte;
    const costPerox = mezclasPeroxido * preciosInsumos.precioPeroxido;
    const costExtra = Number(extra) || 0;

    const totalMaterialesPuro = costDecol + costTinte + costPerox + costExtra;
    const materialesConMargen = totalMaterialesPuro * preciosInsumos.multiplicador;
    const manoDeObra = horasTrabajo * preciosInsumos.precioHoraManoObra;
    const precioFinal = materialesConMargen + manoDeObra;

    setCalculoResult({
      ok: true,
      desglose: {
        decolorante: {
          porciones: porcionesDecolorante,
          precio_unitario: preciosInsumos.precioDecolorante,
          subtotal: +costDecol.toFixed(2),
        },
        tinte: {
          tubos: tubosTinte,
          precio_unitario: preciosInsumos.precioTinte,
          subtotal: +costTinte.toFixed(2),
        },
        peroxido: {
          mezclas: mezclasPeroxido,
          precio_unitario: preciosInsumos.precioPeroxido,
          subtotal: +costPerox.toFixed(2),
        },
        extra: {
          extra: costExtra.toFixed(2),
        },
        costo_total_materiales: +totalMaterialesPuro.toFixed(2),
        multiplicador: `${preciosInsumos.multiplicador}x`,
        materiales_con_margen: +materialesConMargen.toFixed(2),
        mano_de_obra: {
          horas: horasTrabajo,
          precio_hora: preciosInsumos.precioHoraManoObra,
          subtotal: +manoDeObra.toFixed(2),
        },
      },
      PRECIO_FINAL: +precioFinal.toFixed(2),
      mensaje: `Cálculo ajustado a tu lista de costos de proveedor.`,
    });
  }, [porcionesDecolorante, tubosTinte, mezclasPeroxido, horasTrabajo, extra, preciosInsumos]);

  return (
    <div className="flex flex-col gap-6 w-full max-w-5xl mx-auto">
      {/* Header con Botón de Ajuste de Precios */}
      <div className="bg-white p-6 sm:p-8 rounded-2xl border border-[#eff4ff] shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
            Motor Químico de Colorimetría
          </span>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
            Calculadora de Precios
          </h1>
          <p className="text-xs text-[#515f74] mt-1">
            Calcula el valor exacto de químicos, insumos y mano de obra para cada trabajo.
          </p>
        </div>

        <button
          onClick={() => {
            setTempPrecios(preciosInsumos);
            setIsConfigOpen(true);
          }}
          className="px-4 py-2.5 rounded-full bg-[#fdf2f8] hover:bg-[#ffd9e4] text-[#b10e6b] font-bold text-xs flex items-center justify-center gap-2 border border-[#f5e6ed] transition-all cursor-pointer shrink-0"
        >
          <Settings className="w-4 h-4" />
          <span>Ajustar Precios Proveedor</span>
        </button>
      </div>

      {/* 1. RESUMEN DE COBRO Y DESGLOSE (ARRIBA COMO PIDIÓ EL USUARIO) */}
      <div className="bg-gradient-to-br from-[#0b1c30] via-[#112744] to-[#1e293b] p-6 sm:p-8 rounded-3xl text-white shadow-xl border border-[#1e3a5f]">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6 border-b border-[#334155] pb-6 mb-6">
          <div>
            <span className="text-[10px] uppercase tracking-widest text-[#94a3b8] font-bold block mb-1">
              Resumen Total a Cobrar (Recomendado)
            </span>
            <div className="text-4xl sm:text-5xl font-serif font-bold text-[#ffd9e4] flex items-baseline gap-2">
              ${calculoResult ? calculoResult.PRECIO_FINAL.toFixed(2) : '0.00'}
              <span className="text-xs font-sans text-emerald-400 font-semibold flex items-center gap-1">
                <CheckCircle2 className="w-4 h-4" /> Cobro Final Sugerido
              </span>
            </div>
          </div>

          {onScheduleAppointmentWithPrice && calculoResult && (
            <button
              onClick={() => onScheduleAppointmentWithPrice(calculoResult.PRECIO_FINAL)}
              className="w-full md:w-auto px-6 py-3.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white font-bold text-xs sm:text-sm shadow-lg shadow-[#b10e6b]/30 transition-all active:scale-95 cursor-pointer flex items-center justify-center gap-2"
            >
              <span>Agendar Cita con ${calculoResult.PRECIO_FINAL.toFixed(2)}</span>
            </button>
          )}
        </div>

        {/* Desglose Detallado arriba */}
        {calculoResult && calculoResult.desglose && (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 text-xs">
            <div className="bg-[#1e293b]/70 p-3.5 rounded-2xl border border-[#334155]">
              <span className="text-[#94a3b8] block text-[10px]">Decolorante</span>
              <span className="font-bold text-white text-sm">
                ${calculoResult.desglose.decolorante.subtotal.toFixed(2)}
              </span>
              <span className="text-[10px] text-[#94a3b8] block mt-0.5">
                {calculoResult.desglose.decolorante.porciones} porc. x ${preciosInsumos.precioDecolorante}
              </span>
            </div>

            <div className="bg-[#1e293b]/70 p-3.5 rounded-2xl border border-[#334155]">
              <span className="text-[#94a3b8] block text-[10px]">Tubos de Tinte</span>
              <span className="font-bold text-white text-sm">
                ${calculoResult.desglose.tinte.subtotal.toFixed(2)}
              </span>
              <span className="text-[10px] text-[#94a3b8] block mt-0.5">
                {calculoResult.desglose.tinte.tubos} tubos x ${preciosInsumos.precioTinte}
              </span>
            </div>

            <div className="bg-[#1e293b]/70 p-3.5 rounded-2xl border border-[#334155]">
              <span className="text-[#94a3b8] block text-[10px]">Peróxido</span>
              <span className="font-bold text-white text-sm">
                ${calculoResult.desglose.peroxido.subtotal.toFixed(2)}
              </span>
              <span className="text-[10px] text-[#94a3b8] block mt-0.5">
                {calculoResult.desglose.peroxido.mezclas} mezclas x ${preciosInsumos.precioPeroxido}
              </span>
            </div>

            <div className="bg-[#1e293b]/70 p-3.5 rounded-2xl border border-[#334155]">
              <span className="text-[#94a3b8] block text-[10px]">Mano de Obra ({horasTrabajo}h)</span>
              <span className="font-bold text-[#ffd9e4] text-sm">
                ${calculoResult.desglose.mano_de_obra.subtotal.toFixed(2)}
              </span>
              <span className="text-[10px] text-[#94a3b8] block mt-0.5">
                ${preciosInsumos.precioHoraManoObra}/hora
              </span>
            </div>
          </div>
        )}
      </div>

      {/* 2. CONTROLES DE INSUMOS Y TIEMPO (ABAJO DEL RESUMEN) */}
      <div className="bg-white p-6 sm:p-8 rounded-3xl border border-[#eff4ff] shadow-xs space-y-6">
        <h2 className="font-serif text-lg font-bold text-[#0b1c30] flex items-center gap-2">
          <Layers className="w-5 h-5 text-[#b10e6b]" />
          Selecciona Insumos y Horas de Aplicación
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Decolorante */}
          <div className="bg-[#f8f9ff] p-4 rounded-2xl border border-[#eff4ff]">
            <div className="flex items-center justify-between mb-2">
              <label className="font-bold text-xs text-[#0b1c30]">
                Porciones de Decolorante
              </label>
              <span className="text-xs font-bold text-[#b10e6b] bg-[#ffd9e4] px-2.5 py-0.5 rounded-full">
                {porcionesDecolorante} {porcionesDecolorante === 1 ? 'porción' : 'porciones'}
              </span>
            </div>
            <input
              type="range"
              min="0"
              max="8"
              step="1"
              value={porcionesDecolorante}
              onChange={(e) => setPorcionesDecolorante(Number(e.target.value))}
              className="w-full accent-[#b10e6b] cursor-pointer"
            />
            <div className="flex justify-between text-[10px] text-[#515f74] mt-1">
              <span>0 (Sin decolorar)</span>
              <span>2 (Balayage medio)</span>
              <span>8 (Abundante)</span>
            </div>
          </div>

          {/* Tubos de Tinte */}
          <div className="bg-[#f8f9ff] p-4 rounded-2xl border border-[#eff4ff]">
            <div className="flex items-center justify-between mb-2">
              <label className="font-bold text-xs text-[#0b1c30]">
                Tubos de Tinte / Matizador
              </label>
              <span className="text-xs font-bold text-[#b10e6b] bg-[#ffd9e4] px-2.5 py-0.5 rounded-full">
                {tubosTinte} {tubosTinte === 1 ? 'tubo' : 'tubos'}
              </span>
            </div>
            <input
              type="range"
              min="0"
              max="6"
              step="1"
              value={tubosTinte}
              onChange={(e) => setTubosTinte(Number(e.target.value))}
              className="w-full accent-[#b10e6b] cursor-pointer"
            />
            <div className="flex justify-between text-[10px] text-[#515f74] mt-1">
              <span>0</span>
              <span>1 (Raíz)</span>
              <span>6 (Largo)</span>
            </div>
          </div>

          {/* Mezclas de Peróxido */}
          <div className="bg-[#f8f9ff] p-4 rounded-2xl border border-[#eff4ff]">
            <div className="flex items-center justify-between mb-2">
              <label className="font-bold text-xs text-[#0b1c30]">
                Mezclas de Peróxido / Revelador
              </label>
              <span className="text-xs font-bold text-[#b10e6b] bg-[#ffd9e4] px-2.5 py-0.5 rounded-full">
                {mezclasPeroxido} mezclas
              </span>
            </div>
            <input
              type="range"
              min="0"
              max="10"
              step="1"
              value={mezclasPeroxido}
              onChange={(e) => setMezclasPeroxido(Number(e.target.value))}
              className="w-full accent-[#b10e6b] cursor-pointer"
            />
          </div>

          {/* Horas de Trabajo */}
          <div className="bg-[#f8f9ff] p-4 rounded-2xl border border-[#eff4ff]">
            <div className="flex items-center justify-between mb-2">
              <label className="font-bold text-xs text-[#0b1c30]">
                Horas de Mano de Obra
              </label>
              <span className="text-xs font-bold text-[#b10e6b] bg-[#ffd9e4] px-2.5 py-0.5 rounded-full">
                {horasTrabajo} {horasTrabajo === 1 ? 'hora' : 'horas'} (${preciosInsumos.precioHoraManoObra}/h)
              </span>
            </div>
            <input
              type="range"
              min="0.5"
              max="8"
              step="0.5"
              value={horasTrabajo}
              onChange={(e) => setHorasTrabajo(Number(e.target.value))}
              className="w-full accent-[#b10e6b] cursor-pointer"
            />
          </div>

          {/* Extra */}
          <div className="bg-[#f8f9ff] p-4 rounded-2xl border border-[#eff4ff] md:col-span-2">
            <label className="block font-bold text-xs text-[#0b1c30] mb-1">
              Costo Extra Insumos ($)
            </label>
            <input
              type="number"
              min="0"
              step="0.5"
              value={extra}
              onChange={(e) => setExtra(Number(e.target.value))}
              placeholder="Ej: Ampolla, Plex, gorro térmico..."
              className="w-full px-4 py-2.5 rounded-xl bg-white border border-[#eff4ff] text-xs outline-none focus:ring-2 focus:ring-[#b10e6b]/20"
            />
          </div>
        </div>
      </div>

      {/* MODAL CONFIGURACIÓN DE PRECIOS PROVEEDOR */}
      {isConfigOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-md w-full border border-[#eff4ff] shadow-2xl space-y-6">
            <div className="flex items-center justify-between border-b border-[#eff4ff] pb-4">
              <h2 className="font-serif text-xl font-bold text-[#0b1c30] flex items-center gap-2">
                <Settings className="w-5 h-5 text-[#b10e6b]" />
                Ajustar Precios de Insumos
              </h2>
              <button
                onClick={() => setIsConfigOpen(false)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSavePrecios} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">
                  Precio por Porción de Decolorante ($)
                </label>
                <input
                  type="number"
                  step="0.1"
                  value={tempPrecios.precioDecolorante}
                  onChange={(e) => setTempPrecios({ ...tempPrecios, precioDecolorante: Number(e.target.value) })}
                  className="w-full px-3 py-2 rounded-xl bg-[#f8f9ff] border border-[#eff4ff] outline-none font-bold text-[#0b1c30]"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">
                  Precio por Tubo de Tinte / Matizador ($)
                </label>
                <input
                  type="number"
                  step="0.1"
                  value={tempPrecios.precioTinte}
                  onChange={(e) => setTempPrecios({ ...tempPrecios, precioTinte: Number(e.target.value) })}
                  className="w-full px-3 py-2 rounded-xl bg-[#f8f9ff] border border-[#eff4ff] outline-none font-bold text-[#0b1c30]"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">
                  Precio por Mezcla de Peróxido ($)
                </label>
                <input
                  type="number"
                  step="0.1"
                  value={tempPrecios.precioPeroxido}
                  onChange={(e) => setTempPrecios({ ...tempPrecios, precioPeroxido: Number(e.target.value) })}
                  className="w-full px-3 py-2 rounded-xl bg-[#f8f9ff] border border-[#eff4ff] outline-none font-bold text-[#0b1c30]"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">
                  Precio por Hora Mano de Obra ($)
                </label>
                <input
                  type="number"
                  step="0.5"
                  value={tempPrecios.precioHoraManoObra}
                  onChange={(e) => setTempPrecios({ ...tempPrecios, precioHoraManoObra: Number(e.target.value) })}
                  className="w-full px-3 py-2 rounded-xl bg-[#f8f9ff] border border-[#eff4ff] outline-none font-bold text-[#0b1c30]"
                  required
                />
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">
                  Multiplicador Margen Materiales (Ej: 2.5)
                </label>
                <input
                  type="number"
                  step="0.1"
                  value={tempPrecios.multiplicador}
                  onChange={(e) => setTempPrecios({ ...tempPrecios, multiplicador: Number(e.target.value) })}
                  className="w-full px-3 py-2 rounded-xl bg-[#f8f9ff] border border-[#eff4ff] outline-none font-bold text-[#0b1c30]"
                  required
                />
              </div>

              <div className="pt-4 flex gap-3">
                <button
                  type="button"
                  onClick={() => setTempPrecios(DEFAULT_PRECIOS)}
                  className="flex-1 py-3 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer"
                >
                  <RefreshCw className="w-3.5 h-3.5" /> Restablecer
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer shadow-md"
                >
                  <Save className="w-3.5 h-3.5" /> Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
