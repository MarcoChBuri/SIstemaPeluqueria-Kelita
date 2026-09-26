import React from 'react';
import {
  TrendingUp,
  CircleDollarSign,
  Calendar,
  Clock,
  Plus,
  ArrowUpRight,
  ArrowDownRight,
  CheckCircle2,
  AlertCircle,
  Scissors,
  Tag,
  DollarSign,
  Phone,
} from 'lucide-react';
import { Cita, ReporteFinanciero } from '../types';

interface DashboardViewProps {
  reporte: ReporteFinanciero | null;
  citas: Cita[];
  onOpenNewAppointment: () => void;
  onNavigateToTab: (tab: any) => void;
  onShowToast: (message: string) => void;
}

export const DashboardView: React.FC<DashboardViewProps> = ({
  reporte,
  citas,
  onOpenNewAppointment,
  onNavigateToTab,
  onShowToast,
}) => {
  const hoy = new Date().toISOString().split('T')[0];
  const citasHoy = citas.filter((c) => c.fecha_cita === hoy);
  const citasConfirmadas = citas.filter((c) => c.estado === 'confirmada' || c.estado === 'completada').length;

  return (
    <div className="flex flex-col w-full gap-8">
      {/* Editorial Header Masthead */}
      <section className="relative overflow-hidden rounded-2xl bg-white p-6 sm:p-8 shadow-[0_4px_20px_-2px_rgba(236,72,153,0.06)] border border-[#eff4ff]">
        <div className="absolute -right-16 -top-16 w-80 h-80 rounded-full bg-gradient-to-br from-[#b10e6b]/10 via-[#ffd8e7]/30 to-transparent blur-3xl pointer-events-none"></div>

        <div className="relative z-10 flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
          <div className="flex flex-col">
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#d5e3fd] text-[#0d1c2f] text-[10px] font-semibold tracking-wide uppercase">
                <span className="w-2 h-2 rounded-full bg-[#b10e6b] animate-pulse"></span>
                Backend Conectado
              </span>
              <span className="text-xs text-[#515f74]">{reporte?.periodo || 'Mes Actual'}</span>
            </div>

            <h1 className="font-serif text-3xl sm:text-4xl text-[#0b1c30] tracking-tight leading-none">
              Peluquería <span className="text-[#b10e6b] italic font-normal">Raquel</span>
            </h1>
            <p className="text-sm text-[#515f74] mt-2">
              {reporte?.mensaje || 'Control financiero, calculadora de precios y agenda de citas en tiempo real.'}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2.5 sm:gap-3">
            <button
              onClick={() => onNavigateToTab('gastos')}
              className="flex items-center gap-2 px-4 py-2.5 rounded-full bg-[#eff4ff] hover:bg-[#d5e3fd] text-[#0b1c30] text-xs sm:text-sm font-semibold transition-all duration-200 active:scale-95 shadow-xs cursor-pointer"
            >
              <DollarSign className="w-4 h-4 text-[#515f74]" />
              <span>Registrar Gasto / Venta</span>
            </button>

            <button
              onClick={onOpenNewAppointment}
              className="flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#b10e6b] hover:bg-[#930b58] text-white text-xs sm:text-sm font-bold shadow-md shadow-[#b10e6b]/20 transition-all duration-200 active:scale-95 cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Nueva Cita</span>
            </button>
          </div>
        </div>
      </section>

      {/* KPI Cards Grid from Backend Reporte */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        {/* Ingresos Servicios */}
        <div className="bg-white p-5 rounded-2xl border border-[#eff4ff] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-[#515f74] uppercase tracking-wider">Ingresos Servicios</span>
            <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Scissors className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-serif font-bold text-[#0b1c30]">
              ${Number(reporte?.ingresos?.servicios || 0).toFixed(2)}
            </div>
            <span className="text-[11px] text-emerald-600 font-semibold flex items-center gap-1 mt-1">
              <ArrowUpRight className="w-3 h-3" /> Citas y Paquetes
            </span>
          </div>
        </div>

        {/* Total Ingresos */}
        <div className="bg-white p-5 rounded-2xl border border-[#eff4ff] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-[#515f74] uppercase tracking-wider">Total Ingresos</span>
            <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-serif font-bold text-[#0b1c30]">
              ${Number(reporte?.total_ingresos || 0).toFixed(2)}
            </div>
            <span className="text-[11px] text-[#515f74] mt-1 block">
              Servicios + Cursos + Productos
            </span>
          </div>
        </div>

        {/* Total Gastos */}
        <div className="bg-white p-5 rounded-2xl border border-[#eff4ff] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-[#515f74] uppercase tracking-wider">Total Gastos</span>
            <div className="w-8 h-8 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
              <ArrowDownRight className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-serif font-bold text-rose-600">
              ${Number(reporte?.total_gastos || 0).toFixed(2)}
            </div>
            <span className="text-[11px] text-rose-500 font-semibold mt-1 block">
              Insumos, arriendo, servicios
            </span>
          </div>
        </div>

        {/* Balance Neto */}
        <div className="bg-white p-5 rounded-2xl border border-[#eff4ff] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-[#515f74] uppercase tracking-wider">Balance Neto</span>
            <div className="w-8 h-8 rounded-xl bg-[#ffd9e4] text-[#b10e6b] flex items-center justify-center">
              <CircleDollarSign className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className={`text-2xl font-serif font-bold ${(reporte?.balance_neto || 0) >= 0 ? 'text-[#b10e6b]' : 'text-rose-600'}`}>
              ${Number(reporte?.balance_neto || 0).toFixed(2)}
            </div>
            <span className="text-[11px] text-[#515f74] mt-1 block">
              Ganancia mensual neta
            </span>
          </div>
        </div>
      </section>

      {/* Main Grid: Citas Recientes / Hoy & Acciones Rápidas */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Citas de la Agenda */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="font-serif text-lg font-bold text-[#0b1c30]">Agenda de Citas</h2>
              <p className="text-xs text-[#515f74]">Listado de citas registradas en la base de datos</p>
            </div>
            <button
              onClick={() => onNavigateToTab('citas')}
              className="text-xs font-semibold text-[#b10e6b] hover:underline cursor-pointer"
            >
              Ver Todas ({citas.length}) →
            </button>
          </div>

          {citas.length === 0 ? (
            <div className="text-center py-12 text-[#515f74] text-xs">
              <Calendar className="w-8 h-8 mx-auto mb-2 text-slate-300" />
              No hay citas registradas en este momento.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#eff4ff] text-[#515f74]">
                    <th className="pb-3 font-semibold">Cliente</th>
                    <th className="pb-3 font-semibold">Servicio</th>
                    <th className="pb-3 font-semibold">Fecha / Hora</th>
                    <th className="pb-3 font-semibold">Total</th>
                    <th className="pb-3 font-semibold">Estado</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#eff4ff]">
                  {citas.slice(0, 5).map((cita) => (
                    <tr key={cita.id} className="hover:bg-[#f8f9ff]">
                      <td className="py-3">
                        <div className="font-bold text-[#0b1c30]">{cita.cliente_nombre}</div>
                        <div className="text-[11px] text-[#515f74] flex items-center gap-1">
                          <Phone className="w-3 h-3" /> {cita.cliente_telefono}
                        </div>
                      </td>
                      <td className="py-3 text-[#515f74]">
                        {cita.servicios?.nombre || 'Servicio General'}
                      </td>
                      <td className="py-3 text-[#515f74]">
                        <span className="font-medium text-[#0b1c30]">{cita.fecha_cita}</span>
                        <div className="text-[10px] text-[#515f74]">{cita.hora_inicio} - {cita.hora_fin}</div>
                      </td>
                      <td className="py-3 font-bold text-[#0b1c30]">
                        ${Number(cita.precio_final).toFixed(2)}
                      </td>
                      <td className="py-3">
                        <span
                          className={`inline-flex px-2.5 py-0.5 rounded-full text-[10px] font-bold capitalize ${
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
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Accesos Rápidos y Modos del Negocio */}
        <div className="flex flex-col gap-4">
          <div className="bg-white rounded-2xl p-6 border border-[#eff4ff] shadow-xs">
            <h3 className="font-serif text-base font-bold text-[#0b1c30] mb-4">Herramientas Rápidas</h3>
            <div className="space-y-3">
              <button
                onClick={() => onNavigateToTab('calculadora')}
                className="w-full flex items-center justify-between p-3.5 rounded-xl bg-[#eff4ff] hover:bg-[#d5e3fd] text-[#0b1c30] text-xs font-semibold transition-all text-left cursor-pointer"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-white flex items-center justify-center text-[#b10e6b] shadow-xs">
                    <Scissors className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="font-bold">Calculadora de Tintes</div>
                    <div className="text-[11px] text-[#515f74]">Cálculo exacto de químicos y margen</div>
                  </div>
                </div>
                <span>→</span>
              </button>

              <button
                onClick={() => onNavigateToTab('promociones')}
                className="w-full flex items-center justify-between p-3.5 rounded-xl bg-[#eff4ff] hover:bg-[#d5e3fd] text-[#0b1c30] text-xs font-semibold transition-all text-left cursor-pointer"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-white flex items-center justify-center text-[#b10e6b] shadow-xs">
                    <Tag className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="font-bold">Promociones del Mes</div>
                    <div className="text-[11px] text-[#515f74]">Descuentos para clientas web</div>
                  </div>
                </div>
                <span>→</span>
              </button>

              <button
                onClick={() => onNavigateToTab('gastos')}
                className="w-full flex items-center justify-between p-3.5 rounded-xl bg-[#eff4ff] hover:bg-[#d5e3fd] text-[#0b1c30] text-xs font-semibold transition-all text-left cursor-pointer"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-white flex items-center justify-center text-[#b10e6b] shadow-xs">
                    <DollarSign className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="font-bold">Gastos & Venta Productos</div>
                    <div className="text-[11px] text-[#515f74]">Control de caja y egresos diarios</div>
                  </div>
                </div>
                <span>→</span>
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};
