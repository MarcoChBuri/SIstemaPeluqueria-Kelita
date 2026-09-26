import React, { useState } from 'react';
import { Tag, Plus, Calendar, Percent, Sparkles, DollarSign, ArrowRight } from 'lucide-react';
import { Promocion } from '../types';
import { createPromocion } from '../services/api';

interface PromocionesViewProps {
  promociones: Promocion[];
  onPromocionCreated: (promo: Promocion) => void;
  onApplyPromoToCita?: (promoId: string) => void;
  onShowToast: (message: string) => void;
}

export const PromocionesView: React.FC<PromocionesViewProps> = ({
  promociones,
  onPromocionCreated,
  onApplyPromoToCita,
  onShowToast,
}) => {
  const hoy = new Date().toISOString().split('T')[0];
  const en30Dias = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [titulo, setTitulo] = useState<string>('');
  const [descripcion, setDescripcion] = useState<string>('');
  const [tipoDescuento, setTipoDescuento] = useState<'porcentaje' | 'monto'>('porcentaje');
  const [valorDescuento, setValorDescuento] = useState<number>(20);
  const [fechaInicio, setFechaInicio] = useState<string>(hoy);
  const [fechaFin, setFechaFin] = useState<string>(en30Dias);
  const [imagenUrl, setImagenUrl] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!titulo.trim() || !fechaFin) return;

    try {
      setIsSubmitting(true);
      const nueva = await createPromocion({
        titulo: titulo.trim(),
        descripcion: descripcion.trim() || undefined,
        porcentaje_descuento: tipoDescuento === 'porcentaje' ? valorDescuento : undefined,
        monto_descuento: tipoDescuento === 'monto' ? valorDescuento : undefined,
        fecha_inicio: fechaInicio,
        fecha_fin: fechaFin,
        imagen_url: imagenUrl.trim() || undefined,
      });

      onPromocionCreated(nueva);
      onShowToast(`Promoción "${nueva.titulo}" creada correctamente.`);
      setIsModalOpen(false);
      setTitulo('');
      setDescripcion('');
      setValorDescuento(20);
      setImagenUrl('');
    } catch (err: any) {
      onShowToast(`Error: ${err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-[#eff4ff] shadow-xs">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
            Ofertas Activas
          </span>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
            Promociones del Mes
          </h1>
          <p className="text-xs text-[#515f74] mt-0.5">
            Descuentos especiales aplicables automáticamente a las citas de las clientas.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white text-xs sm:text-sm font-bold shadow-md transition-all active:scale-95 cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Nueva Promoción</span>
        </button>
      </div>

      {/* Promos Cards Grid */}
      {promociones.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center text-[#515f74] border border-[#eff4ff]">
          <Tag className="w-10 h-10 mx-auto mb-3 text-slate-300" />
          <h3 className="font-serif text-lg font-bold text-[#0b1c30] mb-1">No hay promociones vigentes</h3>
          <p className="text-xs">Crea una nueva promoción para incentivar reservas.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {promociones.map((p) => (
            <div
              key={p.id}
              className="bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs flex flex-col justify-between hover:shadow-md transition-all"
            >
              <div>
                <div className="flex items-center justify-between gap-2 mb-3">
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#ffd9e4] text-[#b10e6b]">
                    {p.porcentaje_descuento ? `${p.porcentaje_descuento}% OFF` : `$${p.monto_descuento} Descuento`}
                  </span>
                  <span className="text-[10px] text-[#515f74] flex items-center gap-1">
                    <Calendar className="w-3 h-3" /> Hasta {p.fecha_fin}
                  </span>
                </div>

                <h3 className="font-serif text-xl font-bold text-[#0b1c30] mb-2">
                  {p.titulo}
                </h3>

                <p className="text-xs text-[#515f74] mb-4">
                  {p.descripcion || 'Sin descripción.'}
                </p>
              </div>

              <div className="pt-4 border-t border-[#eff4ff] flex items-center justify-between">
                <span className="text-[11px] font-semibold text-emerald-600">
                  Activa en web
                </span>

                {onApplyPromoToCita && (
                  <button
                    onClick={() => onApplyPromoToCita(p.id)}
                    className="flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#eff4ff] hover:bg-[#b10e6b] hover:text-white text-[#b10e6b] text-xs font-bold transition-all cursor-pointer"
                  >
                    <span>Usar Promo</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Nueva Promoción */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <div className="w-full max-w-md rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-[#eff4ff]">
            <h2 className="font-serif text-xl font-bold text-[#0b1c30] mb-1">Crear Promoción</h2>
            <p className="text-xs text-[#515f74] mb-4">Se registrará en la base de datos de promociones.</p>

            <form onSubmit={handleSubmit} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Título de la Promoción</label>
                <input
                  type="text"
                  required
                  placeholder="Ej: Miércoles de Alisados Orgánicos"
                  value={titulo}
                  onChange={(e) => setTitulo(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Tipo Descuento</label>
                  <select
                    value={tipoDescuento}
                    onChange={(e) => setTipoDescuento(e.target.value as any)}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  >
                    <option value="porcentaje">Porcentaje (%)</option>
                    <option value="monto">Monto Fijo ($)</option>
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Valor ({tipoDescuento === 'porcentaje' ? '%' : '$'})</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={valorDescuento}
                    onChange={(e) => setValorDescuento(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Fecha Inicio</label>
                  <input
                    type="date"
                    value={fechaInicio}
                    onChange={(e) => setFechaInicio(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Fecha Fin</label>
                  <input
                    type="date"
                    required
                    value={fechaFin}
                    onChange={(e) => setFechaFin(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30]"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Descripción</label>
                <textarea
                  rows={2}
                  placeholder="Detalles y condiciones de la oferta..."
                  value={descripcion}
                  onChange={(e) => setDescripcion(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#eff4ff] outline-none text-[#0b1c30] resize-none"
                />
              </div>

              <div className="pt-3 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 rounded-full bg-[#eff4ff] text-[#515f74] font-semibold"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white font-bold"
                >
                  {isSubmitting ? 'Guardando...' : 'Crear Promo'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
