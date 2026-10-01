import React, { useState, useEffect } from 'react';
import { X, CalendarDays, Scissors, MessageCircle, Clock, ChevronRight } from 'lucide-react';
import { Servicio } from '../../types';
import { SALON_CONFIG, buildWhatsAppUrl } from '../../config/salonConfig';

interface ReservaModalProps {
  isOpen: boolean;
  onClose: () => void;
  servicio: Servicio | null;
  serviciosDisponibles?: Servicio[];
  onSelectServicio?: (s: Servicio) => void;
}

export const ReservaModal: React.FC<ReservaModalProps> = ({
  isOpen,
  onClose,
  servicio,
  serviciosDisponibles,
  onSelectServicio,
}) => {
  const [fecha, setFecha] = useState<string>('');

  // Lock body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  if (!isOpen || !servicio) return null;

  const todayStr = new Date().toISOString().split('T')[0];

  const handleWhatsAppSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    let fechaTexto = '';
    if (fecha) {
      try {
        const [year, month, day] = fecha.split('-').map(Number);
        const dateObj = new Date(year, month - 1, day);
        fechaTexto = dateObj.toLocaleDateString('es-ES', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric',
        });
      } catch {
        fechaTexto = fecha;
      }
    }

    let mensaje = `¡Hola ${SALON_CONFIG.nombre}! 💇‍♀️ Quiero consultar / reservar el servicio:\n\n💅 *Servicio:* ${servicio.nombre}\n💰 *Precio referencia:* ${SALON_CONFIG.monedaSimbolo}${Number(servicio.precio_base).toFixed(2)}`;

    if (fechaTexto) {
      mensaje += `\n📅 *Día preferido:* ${fechaTexto}`;
    }

    mensaje += `\n\n¿Tienen disponibilidad? 🙏`;

    const url = buildWhatsAppUrl(mensaje);
    window.open(url, '_blank', 'noopener,noreferrer');
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-3 sm:p-4 animate-[fadeIn_0.2s_ease-out]"
      onClick={onClose}
    >
      <div
        className="relative max-w-md w-full bg-white rounded-3xl p-5 sm:p-7 shadow-2xl border border-[#f5e6ed] max-h-[92vh] overflow-y-auto animate-[scaleIn_0.25s_ease-out]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-9 h-9 rounded-full bg-slate-100 hover:bg-slate-200 text-[#0b1c30] flex items-center justify-center transition-colors cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="flex items-center gap-2 mb-1">
          <span className="px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-emerald-100 text-emerald-800 flex items-center gap-1">
            <MessageCircle className="w-3.5 h-3.5 text-emerald-600" /> WhatsApp Directo
          </span>
        </div>
        <h2 className="font-serif text-xl sm:text-2xl font-bold text-[#0b1c30] mb-1">
          Reservar Servicio
        </h2>
        <p className="text-xs text-[#515f74] mb-4">
          Te llevamos directo al chat de {SALON_CONFIG.duena} por WhatsApp.
        </p>

        {/* Service Selected Card */}
        <div className="bg-gradient-to-r from-[#fdf2f8] to-[#fff1f5] rounded-2xl p-4 border border-[#f5e6ed] mb-4">
          <div className="flex items-center justify-between gap-2">
            <div>
              <span className="text-[10px] uppercase font-bold text-[#b10e6b] block">Servicio</span>
              <span className="font-serif font-bold text-[#0b1c30] text-sm sm:text-base">{servicio.nombre}</span>
            </div>
            <div className="text-right">
              <span className="text-[10px] text-[#8b7079] block">Precio</span>
              <span className="font-serif font-bold text-[#b10e6b] text-lg sm:text-xl">
                {SALON_CONFIG.monedaSimbolo}{Number(servicio.precio_base).toFixed(2)}
              </span>
            </div>
          </div>
        </div>

        {/* Change Service Selector if provided */}
        {serviciosDisponibles && serviciosDisponibles.length > 1 && onSelectServicio && (
          <div className="mb-4">
            <label className="block text-[11px] font-bold text-[#515f74] mb-1">
              Cambiar servicio:
            </label>
            <select
              value={servicio.id}
              onChange={(e) => {
                const s = serviciosDisponibles.find((item) => item.id === e.target.value);
                if (s) onSelectServicio(s);
              }}
              className="w-full px-3 py-2.5 rounded-xl border border-[#f5e6ed] text-xs font-bold text-[#0b1c30] outline-none bg-white cursor-pointer"
            >
              {serviciosDisponibles.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.nombre} – {SALON_CONFIG.monedaSimbolo}{Number(item.precio_base).toFixed(2)}
                </option>
              ))}
            </select>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleWhatsAppSubmit} className="space-y-4">
          {/* Optional Date Picker */}
          <div>
            <label className="flex items-center justify-between text-xs font-bold text-[#0b1c30] mb-1.5">
              <span className="flex items-center gap-1.5">
                <CalendarDays className="w-4 h-4 text-[#b10e6b]" />
                Escoger fecha en el calendario
              </span>
              <span className="text-[10px] font-normal text-[#8b7079] bg-slate-100 px-2 py-0.5 rounded-full">
                Opcional
              </span>
            </label>
            <input
              type="date"
              min={todayStr}
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
              className="w-full px-4 py-3 rounded-2xl border border-[#f5e6ed] focus:border-[#b10e6b] text-sm text-[#0b1c30] outline-none transition-all shadow-xs cursor-pointer bg-[#fefcfd]"
            />
          </div>

          {/* Submit CTA */}
          <button
            type="submit"
            className="w-full py-4 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm shadow-xl shadow-emerald-600/25 transition-all cursor-pointer flex items-center justify-center gap-2 active:scale-[0.98]"
          >
            <MessageCircle className="w-5 h-5" />
            <span>Ir a WhatsApp ({SALON_CONFIG.whatsappNumber})</span>
            <ChevronRight className="w-4 h-4" />
          </button>

          <p className="text-[10px] text-[#8b7079] text-center">
            Se abrirá WhatsApp directamente sin necesidad de llenar más datos. 💬
          </p>
        </form>
      </div>
    </div>
  );
};
