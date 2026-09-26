import React, { useState, useEffect } from 'react';
import { Calculator, Sparkles, DollarSign, Clock, Layers, ShieldCheck, CheckCircle2 } from 'lucide-react';
import { CalculoPrecioResult } from '../types';
import { calcularPrecio } from '../services/api';

interface CalculadoraViewProps {
  onScheduleAppointmentWithPrice?: (precio: number) => void;
  onShowToast: (message: string) => void;
}

export const CalculadoraView: React.FC<CalculadoraViewProps> = ({
  onScheduleAppointmentWithPrice,
  onShowToast,
}) => {
  const [porcionesDecolorante, setPorcionesDecolorante] = useState<number>(2);
  const [tubosTinte, setTubosTinte] = useState<number>(1);
  const [mezclasPeroxido, setMezclasPeroxido] = useState<number>(2);
  const [horasTrabajo, setHorasTrabajo] = useState<number>(3);
  const [extra, setExtra] = useState<number>(0);

  const [calculoResult, setCalculoResult] = useState<CalculoPrecioResult | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const handleCalcular = async () => {
    try {
      setIsLoading(true);
      const res = await calcularPrecio({
        porciones_decolorante: porcionesDecolorante,
        tubos_tinte: tubosTinte,
        mezclas_peroxido: mezclasPeroxido,
        horas_trabajo: horasTrabajo,
        extra: extra || 0,
      });
      setCalculoResult(res);
    } catch (err: any) {
      onShowToast(`Error en cálculo: ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  // Calcular inicialmente
  useEffect(() => {
    handleCalcular();
  }, [porcionesDecolorante, tubosTinte, mezclasPeroxido, horasTrabajo, extra]);

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="bg-white p-6 sm:p-8 rounded-2xl border border-[#eff4ff] shadow-xs">
        <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
          Motor Químico Oficial de Raquel
        </span>
        <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
          Calculadora de Precios de Colorimetría
        </h1>
        <p className="text-xs text-[#515f74] mt-1">
          Cálculo exacto del costo de materiales (decolorante, tinte, peróxido), multiplicador de margen comercial y mano de obra.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Controls Section (Inputs) */}
        <div className="lg:col-span-7 bg-white p-6 sm:p-8 rounded-2xl border border-[#eff4ff] shadow-xs space-y-6">
          <h2 className="font-serif text-lg font-bold text-[#0b1c30] flex items-center gap-2">
            <Layers className="w-5 h-5 text-[#b10e6b]" />
            Insumos y Tiempo de Aplicación
          </h2>

          {/* Decolorante */}
          <div className="bg-[#f8f9ff] p-4 rounded-xl border border-[#eff4ff]">
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
              <span>8 (Decoloración global)</span>
            </div>
          </div>

          {/* Tubos de Tinte */}
          <div className="bg-[#f8f9ff] p-4 rounded-xl border border-[#eff4ff]">
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
              <span>1 (Raíz o matiz)</span>
              <span>6 (Largo abundante)</span>
            </div>
          </div>

          {/* Mezclas de Peróxido */}
          <div className="bg-[#f8f9ff] p-4 rounded-xl border border-[#eff4ff]">
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
          <div className="bg-[#f8f9ff] p-4 rounded-xl border border-[#eff4ff]">
            <div className="flex items-center justify-between mb-2">
              <label className="font-bold text-xs text-[#0b1c30]">
                Horas de Mano de Obra
              </label>
              <span className="text-xs font-bold text-[#b10e6b] bg-[#ffd9e4] px-2.5 py-0.5 rounded-full">
                {horasTrabajo} {horasTrabajo === 1 ? 'hora' : 'horas'} ($5.00/h)
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
          <div className="bg-[#f8f9ff] p-4 rounded-xl border border-[#eff4ff]">
            <label className="block font-bold text-xs text-[#0b1c30] mb-1">
              Costo Extra Insumos ($)
            </label>
            <input
              type="number"
              min="0"
              step="0.5"
              value={extra}
              onChange={(e) => setExtra(Number(e.target.value))}
              placeholder="Ej: Plex, ampolla, gorro térmico..."
              className="w-full px-3 py-2 rounded-xl bg-white border border-[#eff4ff] text-xs outline-none"
            />
          </div>
        </div>

        {/* Results Breakdown Section */}
        <div className="lg:col-span-5 flex flex-col gap-6">
          <div className="bg-white p-6 sm:p-8 rounded-2xl border border-[#eff4ff] shadow-xs flex flex-col justify-between">
            <div>
              <span className="text-[10px] uppercase tracking-widest text-[#515f74] font-bold block mb-1">
                Resultado de la Fórmula Backend
              </span>
              <div className="text-3xl sm:text-4xl font-serif font-bold text-[#0b1c30] mb-2">
                ${calculoResult ? calculoResult.PRECIO_FINAL.toFixed(2) : '0.00'}
              </div>
              <p className="text-xs text-emerald-600 font-semibold mb-6 flex items-center gap-1.5">
                <CheckCircle2 className="w-4 h-4" />
                {calculoResult?.mensaje || 'Precio sugerido de cobro'}
              </p>

              {/* Breakdown Details */}
              {calculoResult && calculoResult.desglose && (
                <div className="space-y-3 text-xs border-t border-[#eff4ff] pt-4">
                  <div className="flex justify-between text-[#515f74]">
                    <span>Decolorante ({calculoResult.desglose.decolorante.porciones} porc. x ${calculoResult.desglose.decolorante.precio_unitario})</span>
                    <span className="font-semibold text-[#0b1c30]">${calculoResult.desglose.decolorante.subtotal.toFixed(2)}</span>
                  </div>

                  <div className="flex justify-between text-[#515f74]">
                    <span>Tinte ({calculoResult.desglose.tinte.tubos} tubos x ${calculoResult.desglose.tinte.precio_unitario})</span>
                    <span className="font-semibold text-[#0b1c30]">${calculoResult.desglose.tinte.subtotal.toFixed(2)}</span>
                  </div>

                  <div className="flex justify-between text-[#515f74]">
                    <span>Peróxido ({calculoResult.desglose.peroxido.mezclas} mezclas)</span>
                    <span className="font-semibold text-[#0b1c30]">${calculoResult.desglose.peroxido.subtotal.toFixed(2)}</span>
                  </div>

                  <div className="flex justify-between text-[#515f74]">
                    <span>Total Materiales Puro</span>
                    <span className="font-bold text-[#0b1c30]">${calculoResult.desglose.costo_total_materiales.toFixed(2)}</span>
                  </div>

                  <div className="flex justify-between text-[#b10e6b] font-bold bg-[#ffd9e4]/30 p-2 rounded-lg">
                    <span>Materiales con Margen ({calculoResult.desglose.multiplicador})</span>
                    <span>${calculoResult.desglose.materiales_con_margen.toFixed(2)}</span>
                  </div>

                  <div className="flex justify-between text-[#515f74]">
                    <span>Mano de Obra ({calculoResult.desglose.mano_de_obra.horas}h x ${calculoResult.desglose.mano_de_obra.precio_hora}/h)</span>
                    <span className="font-semibold text-[#0b1c30]">${calculoResult.desglose.mano_de_obra.subtotal.toFixed(2)}</span>
                  </div>
                </div>
              )}
            </div>

            {onScheduleAppointmentWithPrice && calculoResult && (
              <button
                onClick={() => onScheduleAppointmentWithPrice(calculoResult.PRECIO_FINAL)}
                className="w-full mt-6 py-3 px-6 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white font-bold text-xs sm:text-sm shadow-md transition-all active:scale-95 cursor-pointer"
              >
                Agendar Cita con este Precio (${calculoResult.PRECIO_FINAL.toFixed(2)})
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
