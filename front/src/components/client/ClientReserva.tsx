import React, { useEffect, useState } from 'react';
import {
  CalendarDays,
  Clock,
  Scissors,
  User,
  CheckCircle,
  MessageCircle,
  Sparkles,
  ChevronRight,
} from 'lucide-react';
import { Servicio } from '../../types';
import { getServicios } from '../../services/api';
import { SALON_CONFIG } from '../../config/salonConfig';
import { ReservaModal } from './ReservaModal';

export const ClientReserva: React.FC = () => {
  const [servicios, setServicios] = useState<Servicio[]>([]);
  const [loading, setLoading] = useState(true);

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [servicioModal, setServicioModal] = useState<Servicio | null>(null);

  useEffect(() => {
    setLoading(true);
    getServicios()
      .then((data) => {
        const lista = data.servicios || [];
        setServicios(lista);
      })
      .catch((err) => console.error('Error cargando servicios:', err))
      .finally(() => setLoading(false));
  }, []);

  const handleOpenModal = (s: Servicio) => {
    setServicioModal(s);
    setModalOpen(true);
  };

  return (
    <div className="min-h-screen bg-[#fefcfd] pb-16">
      {/* Header Banner */}
      <div className="bg-gradient-to-br from-[#0b1c30] via-[#1a2d45] to-[#0b1c30] text-white py-12 sm:py-16 px-4 sm:px-6 relative overflow-hidden text-center">
        <div className="absolute top-0 right-0 w-60 h-60 rounded-full bg-[#b10e6b]/15 blur-[90px]" />
        <div className="relative z-10 max-w-3xl mx-auto">
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-500/20 text-emerald-300 text-xs font-bold uppercase tracking-widest mb-3 border border-emerald-500/30">
            <MessageCircle className="w-4 h-4 text-emerald-400" />
            Reserva Instantánea por WhatsApp
          </span>
          <h1 className="font-serif text-2xl sm:text-4xl font-bold mb-2">
            Elige tu Servicio
          </h1>
          <p className="text-white/60 text-xs sm:text-sm max-w-md mx-auto">
            Selecciona el servicio que deseas y se abrirá la ventana para escoger tu día en el calendario y confirmar por WhatsApp.
          </p>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 -mt-6 relative z-20">
        {loading ? (
          <div className="bg-white rounded-3xl p-12 text-center shadow-xl border border-[#f5e6ed]">
            <div className="w-10 h-10 border-4 border-[#b10e6b] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
            <p className="text-sm font-medium text-[#515f74]">Cargando servicios...</p>
          </div>
        ) : (
          <div className="bg-white rounded-3xl p-5 sm:p-8 border border-[#f5e6ed] shadow-2xl space-y-6 animate-[fadeInUp_0.4s_ease-out]">
            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-[#b10e6b]">
                <Scissors className="w-4 h-4" />
                <span>Haz clic en un servicio para reservar</span>
              </label>
              <span className="text-xs text-[#515f74]">
                {servicios.length} disponibles
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
              {servicios.map((s) => (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => handleOpenModal(s)}
                  className="group text-left p-4 rounded-2xl border border-[#f5e6ed] hover:border-[#b10e6b] bg-white hover:bg-[#fdf2f8]/50 shadow-xs hover:shadow-lg transition-all duration-300 cursor-pointer flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between gap-2 mb-1">
                      <span className="font-bold text-sm text-[#0b1c30] group-hover:text-[#b10e6b] transition-colors">
                        {s.nombre}
                      </span>
                      <span className="font-serif font-bold text-sm text-[#b10e6b] whitespace-nowrap">
                        {SALON_CONFIG.monedaSimbolo}{Number(s.precio_base).toFixed(2)}
                      </span>
                    </div>
                    {s.descripcion && (
                      <p className="text-[11px] text-[#515f74] line-clamp-2">{s.descripcion}</p>
                    )}
                  </div>

                  <div className="mt-3 pt-2 border-t border-[#f5e6ed] flex items-center justify-between text-[11px]">
                    <span className="text-[#8b7079] flex items-center gap-1">
                      <Clock className="w-3 h-3" /> {s.duracion_minutos} min
                    </span>
                    <span className="font-bold text-[#b10e6b] flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                      <CalendarDays className="w-3.5 h-3.5" /> Escoger Día <ChevronRight className="w-3 h-3" />
                    </span>
                  </div>
                </button>
              ))}
            </div>

            {/* Banner Descuentos */}
            <div className="bg-gradient-to-r from-[#fdf2f8] via-[#fff1f5] to-[#fff7ed] rounded-2xl p-4 border border-[#f5e6ed] flex items-center justify-between gap-3 text-xs mt-4">
              <div className="flex items-center gap-2.5">
                <Sparkles className="w-5 h-5 text-[#b10e6b] shrink-0" />
                <span className="text-[#515f74]">
                  ¿Tienes cupones o promociones? Inicia sesión en el panel para aplicarlos.
                </span>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Pop-up Overlay Modal */}
      <ReservaModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        servicio={servicioModal}
        serviciosDisponibles={servicios}
        onSelectServicio={(s) => setServicioModal(s)}
      />
    </div>
  );
};
