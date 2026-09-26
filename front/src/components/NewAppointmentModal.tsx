import React, { useState } from 'react';
import { X, Calendar, Clock, User, Phone, Mail, FileText, CheckCircle2, MessageCircle } from 'lucide-react';
import { Cita, Servicio, Promocion } from '../types';
import { createCita } from '../services/api';

interface NewAppointmentModalProps {
  isOpen: boolean;
  onClose: () => void;
  servicios: Servicio[];
  promociones: Promocion[];
  onAppointmentCreated: (cita: Cita, whatsappUrl?: string) => void;
}

export const NewAppointmentModal: React.FC<NewAppointmentModalProps> = ({
  isOpen,
  onClose,
  servicios,
  promociones,
  onAppointmentCreated,
}) => {
  const hoy = new Date().toISOString().split('T')[0];

  const [clienteNombre, setClienteNombre] = useState<string>('');
  const [clienteTelefono, setClienteTelefono] = useState<string>('');
  const [clienteEmail, setClienteEmail] = useState<string>('');
  const [servicioId, setServicioId] = useState<string>(servicios[0]?.id || '');
  const [promocionId, setPromocionId] = useState<string>('');
  const [fechaCita, setFechaCita] = useState<string>(hoy);
  const [horaInicio, setHoraInicio] = useState<string>('10:00');
  const [notas, setNotas] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [createdCitaInfo, setCreatedCitaInfo] = useState<{ cita: Cita; whatsappUrl: string } | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!clienteNombre.trim() || !clienteTelefono.trim() || !servicioId) {
      setErrorMessage('Por favor completa nombre, teléfono y servicio.');
      return;
    }

    try {
      setIsSubmitting(true);
      setErrorMessage(null);

      const res = await createCita({
        cliente_nombre: clienteNombre.trim(),
        cliente_telefono: clienteTelefono.trim(),
        cliente_email: clienteEmail.trim() || undefined,
        servicio_id: servicioId,
        promocion_id: promocionId || undefined,
        fecha_cita: fechaCita,
        hora_inicio: horaInicio,
        notas: notas.trim() || undefined,
      });

      setCreatedCitaInfo({ cita: res.cita, whatsappUrl: res.whatsapp_url });
      onAppointmentCreated(res.cita, res.whatsapp_url);
    } catch (err: any) {
      setErrorMessage(err.message || 'Error al agendar la cita.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleFinish = () => {
    setCreatedCitaInfo(null);
    setClienteNombre('');
    setClienteTelefono('');
    setClienteEmail('');
    setNotas('');
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="w-full max-w-lg rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-[#eff4ff] relative max-h-[90vh] overflow-y-auto">
        <button
          onClick={onClose}
          className="absolute right-5 top-5 p-2 rounded-full hover:bg-[#eff4ff] text-[#515f74] transition-colors cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        {createdCitaInfo ? (
          <div className="flex flex-col items-center text-center py-6">
            <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mb-4">
              <CheckCircle2 className="w-9 h-9" />
            </div>
            <h3 className="font-serif text-2xl font-bold text-[#0b1c30] mb-2">¡Cita Registrada!</h3>
            <p className="text-sm text-[#515f74] mb-6">
              La cita para <strong className="text-[#0b1c30]">{createdCitaInfo.cita.cliente_nombre}</strong> el día{' '}
              <strong>{createdCitaInfo.cita.fecha_cita}</strong> a las <strong>{createdCitaInfo.cita.hora_inicio}</strong> ha sido guardada en la base de datos.
            </p>

            {createdCitaInfo.whatsappUrl && (
              <a
                href={createdCitaInfo.whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full mb-3 flex items-center justify-center gap-2 py-3 px-6 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm shadow-md transition-all active:scale-95"
              >
                <MessageCircle className="w-5 h-5" />
                <span>Enviar Confirmación por WhatsApp</span>
              </a>
            )}

            <button
              type="button"
              onClick={handleFinish}
              className="w-full py-2.5 px-6 rounded-full bg-[#eff4ff] hover:bg-[#d5e3fd] text-[#0b1c30] font-semibold text-sm transition-all"
            >
              Cerrar y ver en Agenda
            </button>
          </div>
        ) : (
          <>
            <div className="mb-6">
              <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
                Agenda de Peluquería Raquel
              </span>
              <h2 className="font-serif text-2xl font-bold text-[#0b1c30]">Nueva Cita de Cliente</h2>
              <p className="text-xs text-[#515f74] mt-0.5">
                Los datos se guardan directamente en el backend de Raquel.
              </p>
            </div>

            {errorMessage && (
              <div className="mb-4 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-medium">
                {errorMessage}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Nombre de la Clienta *</label>
                  <div className="relative">
                    <User className="w-4 h-4 text-[#515f74] absolute left-3 top-3" />
                    <input
                      type="text"
                      required
                      placeholder="Ej: María Pérez"
                      value={clienteNombre}
                      onChange={(e) => setClienteNombre(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Teléfono / WhatsApp *</label>
                  <div className="relative">
                    <Phone className="w-4 h-4 text-[#515f74] absolute left-3 top-3" />
                    <input
                      type="tel"
                      required
                      placeholder="Ej: 0991234567"
                      value={clienteTelefono}
                      onChange={(e) => setClienteTelefono(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none"
                    />
                  </div>
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Email (Opcional)</label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-[#515f74] absolute left-3 top-3" />
                  <input
                    type="email"
                    placeholder="maria@ejemplo.com"
                    value={clienteEmail}
                    onChange={(e) => setClienteEmail(e.target.value)}
                    className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Servicio *</label>
                  <select
                    value={servicioId}
                    onChange={(e) => setServicioId(e.target.value)}
                    required
                    className="w-full px-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none cursor-pointer"
                  >
                    <option value="">Selecciona un servicio</option>
                    {servicios.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.nombre} (${Number(s.precio_base).toFixed(2)} - {s.duracion_minutos} min)
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Promoción (Opcional)</label>
                  <select
                    value={promocionId}
                    onChange={(e) => setPromocionId(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none cursor-pointer"
                  >
                    <option value="">Ninguna promoción</option>
                    {promociones.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.titulo} ({p.porcentaje_descuento ? `${p.porcentaje_descuento}% OFF` : `$${p.monto_descuento} OFF`})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Fecha de la Cita *</label>
                  <div className="relative">
                    <Calendar className="w-4 h-4 text-[#515f74] absolute left-3 top-3" />
                    <input
                      type="date"
                      required
                      value={fechaCita}
                      onChange={(e) => setFechaCita(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-[#0b1c30] mb-1">Hora de Inicio *</label>
                  <div className="relative">
                    <Clock className="w-4 h-4 text-[#515f74] absolute left-3 top-3" />
                    <input
                      type="time"
                      required
                      value={horaInicio}
                      onChange={(e) => setHoraInicio(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none"
                    />
                  </div>
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#0b1c30] mb-1">Notas o Requerimientos</label>
                <div className="relative">
                  <FileText className="w-4 h-4 text-[#515f74] absolute left-3 top-3" />
                  <textarea
                    rows={2}
                    placeholder="Ej: Cabello previamente tinturado, requiere prueba de mecha..."
                    value={notas}
                    onChange={(e) => setNotas(e.target.value)}
                    className="w-full pl-9 pr-3 py-2.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] focus:bg-white focus:ring-2 focus:ring-[#b10e6b]/20 outline-none resize-none"
                  />
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-5 py-2.5 rounded-full bg-[#eff4ff] hover:bg-[#e5eeff] text-xs font-semibold text-[#515f74] cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-6 py-2.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white text-xs font-bold shadow-sm transition-all active:scale-95 disabled:opacity-50 cursor-pointer"
                >
                  {isSubmitting ? 'Guardando...' : 'Guardar Cita'}
                </button>
              </div>
            </form>
          </>
        )}
      </div>
    </div>
  );
};
