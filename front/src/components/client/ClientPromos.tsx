import React, { useEffect, useState } from 'react';
import { Tag, Calendar, Percent, ArrowRight, Sparkles } from 'lucide-react';
import { Promocion } from '../../types';
import { getPromociones } from '../../services/api';

interface ClientPromosProps {
  onReservar: () => void;
}

export const ClientPromos: React.FC<ClientPromosProps> = ({ onReservar }) => {
  const [promos, setPromos] = useState<Promocion[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getPromociones()
      .then((data) => setPromos(data))
      .catch((err) => console.error('Error cargando promociones:', err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="min-h-screen bg-[#fefcfd] pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0b1c30] to-[#1a2d45] text-white py-16 sm:py-20 px-6">
        <div className="max-w-4xl mx-auto text-center">
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 text-white/90 text-xs font-bold uppercase tracking-widest mb-4">
            <Sparkles className="w-4 h-4 text-[#ec4899]" />
            Beneficios Exclusivos
          </span>
          <h1 className="font-serif text-3xl sm:text-5xl font-bold mb-4">
            Promociones y Descuentos
          </h1>
          <p className="text-white/70 max-w-xl mx-auto text-sm sm:text-base leading-relaxed">
            Aprovecha los paquetes de temporada, descuentos en tinturas, alisados y combos especiales para renovar tu imagen al mejor precio.
          </p>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-12">
        {loading ? (
          <div className="text-center py-20 text-[#515f74]">
            <div className="w-10 h-10 border-4 border-[#b10e6b] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-sm font-medium">Buscando ofertas activas...</p>
          </div>
        ) : promos.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-3xl border border-[#f5e6ed] p-12 max-w-md mx-auto shadow-xs">
            <Tag className="w-12 h-12 mx-auto mb-3 text-slate-300" />
            <h3 className="font-bold text-[#0b1c30] mb-1">Sin promociones activas</h3>
            <p className="text-xs text-[#515f74]">
              Actualmente no hay promociones activas registradas. ¡Vuelve pronto o consulta directamente a Raquel por WhatsApp!
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {promos.map((p) => (
              <div
                key={p.id}
                className="relative bg-white rounded-3xl p-8 border border-[#f5e6ed] shadow-md hover:shadow-xl transition-all duration-300 flex flex-col justify-between overflow-hidden group"
              >
                <div className="absolute top-0 right-0 w-36 h-36 bg-gradient-to-bl from-[#b10e6b]/10 to-transparent rounded-bl-full pointer-events-none" />

                <div>
                  <div className="flex items-center justify-between mb-4">
                    <span className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold bg-gradient-to-r from-[#b10e6b] to-[#d23284] text-white shadow-xs">
                      <Percent className="w-3.5 h-3.5" />
                      {p.porcentaje_descuento
                        ? `${p.porcentaje_descuento}% de Descuento`
                        : `$${p.monto_descuento} de Ahorro`}
                    </span>
                    {p.fecha_fin && (
                      <span className="text-[11px] font-medium text-[#8b7079] flex items-center gap-1">
                        <Calendar className="w-3 h-3" /> Hasta {p.fecha_fin}
                      </span>
                    )}
                  </div>

                  <h3 className="font-serif text-2xl font-bold text-[#0b1c30] mb-3 group-hover:text-[#b10e6b] transition-colors">
                    {p.titulo}
                  </h3>

                  <p className="text-sm text-[#515f74] leading-relaxed mb-6">
                    {p.descripcion || 'Aplica al agendar tu cita y menciona esta promoción al momento de la atención.'}
                  </p>
                </div>

                <div className="pt-6 border-t border-[#f5e6ed] flex items-center justify-between">
                  <span className="text-xs font-semibold text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full">
                    Activa
                  </span>
                  <button
                    onClick={onReservar}
                    className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#0b1c30] hover:bg-[#b10e6b] text-white text-xs font-bold transition-all cursor-pointer shadow-sm"
                  >
                    <span>Aprovechar Promo</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
