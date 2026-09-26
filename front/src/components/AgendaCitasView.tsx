import React, { useState } from 'react';
import {
  Calendar,
  Clock,
  CheckCircle2,
  XCircle,
  AlertCircle,
  Plus,
  Phone,
  Mail,
  Filter,
  DollarSign,
  MessageCircle,
} from 'lucide-react';
import { Cita, EstadoCita } from '../types';
import { updateCitaEstado } from '../services/api';

interface AgendaCitasViewProps {
  citas: Cita[];
  onOpenNewAppointment: () => void;
  onAppointmentUpdated: (citaActualizada: Cita) => void;
  onShowToast: (message: string) => void;
}

export const AgendaCitasView: React.FC<AgendaCitasViewProps> = ({
  citas,
  onOpenNewAppointment,
  onAppointmentUpdated,
  onShowToast,
}) => {
  const [filterEstado, setFilterEstado] = useState<string>('all');
  const [filterFecha, setFilterFecha] = useState<string>('');
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const filteredCitas = citas.filter((c) => {
    if (filterEstado !== 'all' && c.estado !== filterEstado) return false;
    if (filterFecha && c.fecha_cita !== filterFecha) return false;
    return true;
  });

  const handleUpdateStatus = async (id: string, nuevoEstado: EstadoCita) => {
    try {
      setUpdatingId(id);
      const updated = await updateCitaEstado(id, { estado: nuevoEstado });
      onAppointmentUpdated(updated);
      onShowToast(`Cita marcada como ${nuevoEstado}`);
    } catch (err: any) {
      onShowToast(`Error: ${err.message}`);
    } finally {
      setUpdatingId(null);
    }
  };

  const handleTogglePayment = async (cita: Cita) => {
    const nuevoPago = cita.estado_pago === 'pagado' ? 'pendiente' : 'pagado';
    try {
      setUpdatingId(cita.id);
      const updated = await updateCitaEstado(cita.id, { estado_pago: nuevoPago });
      onAppointmentUpdated(updated);
      onShowToast(`Estado de pago actualizado a "${nuevoPago}"`);
    } catch (err: any) {
      onShowToast(`Error: ${err.message}`);
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-[#eff4ff] shadow-xs">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#b10e6b] font-bold">
            Gestión de Agenda
          </span>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold text-[#0b1c30]">
            Citas de Raquel
          </h1>
          <p className="text-xs text-[#515f74] mt-0.5">
            Control de reservas, horarios y confirmación directa por WhatsApp.
          </p>
        </div>

        <button
          onClick={onOpenNewAppointment}
          className="flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white text-xs sm:text-sm font-bold shadow-md transition-all active:scale-95 cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Nueva Cita</span>
        </button>
      </div>

      {/* Filters Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-4 rounded-xl border border-[#eff4ff] shadow-xs text-xs">
        <div className="flex flex-wrap items-center gap-2">
          <span className="font-semibold text-[#515f74] flex items-center gap-1">
            <Filter className="w-3.5 h-3.5" /> Estado:
          </span>
          {['all', 'pendiente', 'confirmada', 'completada', 'cancelada'].map((st) => (
            <button
              key={st}
              onClick={() => setFilterEstado(st)}
              className={`px-3 py-1.5 rounded-full font-medium transition-all capitalize cursor-pointer ${
                filterEstado === st
                  ? 'bg-[#b10e6b] text-white font-bold'
                  : 'bg-[#eff4ff] text-[#515f74] hover:bg-[#d5e3fd]'
              }`}
            >
              {st === 'all' ? 'Todas' : st}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-2">
          <span className="font-semibold text-[#515f74]">Fecha:</span>
          <input
            type="date"
            value={filterFecha}
            onChange={(e) => setFilterFecha(e.target.value)}
            className="px-3 py-1.5 rounded-xl bg-[#eff4ff] text-xs text-[#0b1c30] outline-none"
          />
          {filterFecha && (
            <button
              onClick={() => setFilterFecha('')}
              className="text-[#b10e6b] font-semibold text-[11px] hover:underline cursor-pointer"
            >
              Limpiar
            </button>
          )}
        </div>
      </div>

      {/* Citas Cards / Table */}
      {filteredCitas.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center text-[#515f74] border border-[#eff4ff]">
          <Calendar className="w-10 h-10 mx-auto mb-3 text-slate-300" />
          <h3 className="font-serif text-lg font-bold text-[#0b1c30] mb-1">No hay citas</h3>
          <p className="text-xs">No se encontraron citas con los filtros seleccionados.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredCitas.map((cita) => {
            const wspMsg = encodeURIComponent(
              `¡Hola ${cita.cliente_nombre}! Te escribo de Peluquería Raquel para confirmar tu cita el ${cita.fecha_cita} a las ${cita.hora_inicio}.`
            );
            const wspUrl = `https://wa.me/${cita.cliente_telefono.replace(/[^0-9]/g, '')}?text=${wspMsg}`;

            return (
              <div
                key={cita.id}
                className="bg-white rounded-2xl p-5 border border-[#eff4ff] shadow-xs flex flex-col justify-between hover:shadow-md transition-shadow"
              >
                <div>
                  <div className="flex items-start justify-between gap-2 mb-3">
                    <div>
                      <span className="text-[10px] uppercase font-bold text-[#b10e6b] tracking-wider block">
                        {cita.servicios?.categoria || 'Servicio'}
                      </span>
                      <h3 className="font-serif text-lg font-bold text-[#0b1c30]">
                        {cita.cliente_nombre}
                      </h3>
                    </div>

                    <span
                      className={`px-2.5 py-1 rounded-full text-[10px] font-bold capitalize ${
                        cita.estado === 'confirmada'
                          ? 'bg-emerald-100 text-emerald-700'
                          : cita.estado === 'completada'
                          ? 'bg-blue-100 text-blue-700'
                          : cita.estado === 'cancelada'
                          ? 'bg-rose-100 text-rose-700'
                          : 'bg-amber-100 text-amber-700'
                      }`}
                    >
                      {cita.estado}
                    </span>
                  </div>

                  <div className="space-y-1.5 text-xs text-[#515f74] mb-4">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-3.5 h-3.5 text-[#b10e6b]" />
                      <span>{cita.fecha_cita} • <strong className="text-[#0b1c30]">{cita.hora_inicio} a {cita.hora_fin}</strong></span>
                    </div>

                    <div className="flex items-center gap-2">
                      <Phone className="w-3.5 h-3.5 text-[#515f74]" />
                      <span>{cita.cliente_telefono}</span>
                    </div>

                    <div className="flex items-center gap-2">
                      <DollarSign className="w-3.5 h-3.5 text-emerald-600" />
                      <span>
                        Total: <strong className="text-[#0b1c30]">${Number(cita.precio_final).toFixed(2)}</strong>{' '}
                        {cita.descuento_aplicado > 0 && (
                          <span className="text-emerald-600 text-[10px]">(Desc. -${Number(cita.descuento_aplicado).toFixed(2)})</span>
                        )}
                      </span>
                    </div>

                    {cita.notas && (
                      <div className="mt-2 p-2 rounded-lg bg-[#f8f9ff] text-[11px] italic text-[#515f74]">
                        "{cita.notas}"
                      </div>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="pt-3 border-t border-[#eff4ff] flex flex-col gap-2">
                  <div className="flex items-center justify-between text-[11px]">
                    <button
                      onClick={() => handleTogglePayment(cita)}
                      className={`px-2.5 py-1 rounded-full font-bold transition-all cursor-pointer ${
                        cita.estado_pago === 'pagado'
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-amber-100 text-amber-700 hover:bg-amber-200'
                      }`}
                    >
                      {cita.estado_pago === 'pagado' ? '✓ Pagado' : '⏳ Pago Pendiente'}
                    </button>

                    <a
                      href={wspUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-1 text-emerald-600 hover:text-emerald-700 font-bold"
                    >
                      <MessageCircle className="w-3.5 h-3.5" /> WhatsApp
                    </a>
                  </div>

                  {/* Status buttons */}
                  <div className="grid grid-cols-3 gap-1 pt-1">
                    <button
                      disabled={updatingId === cita.id || cita.estado === 'confirmada'}
                      onClick={() => handleUpdateStatus(cita.id, 'confirmada')}
                      className="py-1 rounded bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-[10px] font-bold transition-all disabled:opacity-40 cursor-pointer"
                    >
                      Confirmar
                    </button>
                    <button
                      disabled={updatingId === cita.id || cita.estado === 'completada'}
                      onClick={() => handleUpdateStatus(cita.id, 'completada')}
                      className="py-1 rounded bg-blue-50 hover:bg-blue-100 text-blue-700 text-[10px] font-bold transition-all disabled:opacity-40 cursor-pointer"
                    >
                      Completar
                    </button>
                    <button
                      disabled={updatingId === cita.id || cita.estado === 'cancelada'}
                      onClick={() => handleUpdateStatus(cita.id, 'cancelada')}
                      className="py-1 rounded bg-rose-50 hover:bg-rose-100 text-rose-700 text-[10px] font-bold transition-all disabled:opacity-40 cursor-pointer"
                    >
                      Cancelar
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
